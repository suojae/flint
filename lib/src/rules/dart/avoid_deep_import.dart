import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # avoid_deep_import
///
/// ## 규칙
/// `package:` import 경로의 디렉토리 깊이가 2를 초과하면 경고합니다.
/// 깊은 import는 모듈 내부 구현에 대한 의존을 의미합니다.
///
/// ## 원리
/// 깊은 경로의 파일을 직접 import하면 해당 모듈의 내부 구현에
/// 직접 의존하게 됩니다. 내부 구조가 변경되면 import한 모든 곳이
/// 깨집니다.
///
/// 배럴 파일(barrel file)이나 공개 API를 통해 import하면
/// 내부 리팩토링이 외부에 영향을 주지 않습니다.
///
/// ## 나쁜 예
/// ```dart
/// import 'package:app/features/auth/data/sources/auth_api.dart';
/// import 'package:app/features/payment/domain/entities/payment.dart';
/// ```
///
/// ## 좋은 예
/// ```dart
/// import 'package:app/features/auth/auth.dart';
/// import 'package:app/features/payment/payment.dart';
///
/// // 또는 2뎁스 이내
/// import 'package:app/core/network/dio_client.dart';
/// ```
class AvoidDeepImport extends FlintLintRule {
  AvoidDeepImport() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_deep_import',
    problemMessage:
        'Import path is too deep (more than 2 directory levels). '
        'This creates tight coupling to internal module structure.',
    correctionMessage:
        'Import from a barrel file or a shallower public API instead.',
  );

  static const _maxDepth = 2;

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null || !uri.startsWith('package:')) return;

      // package:name/ 이후의 경로 추출
      final slashIndex = uri.indexOf('/');
      if (slashIndex == -1) return;

      // 외부 패키지는 검사하지 않음 (자기 프로젝트만 검사)
      final importedPackage =
          uri.substring('package:'.length, slashIndex);
      final compilationUnit = node.parent;
      if (compilationUnit is! CompilationUnit) return;
      final libraryUri =
          compilationUnit.declaredFragment?.source.uri.toString();
      if (libraryUri == null || !libraryUri.startsWith('package:')) return;
      final currentPackage =
          libraryUri.substring('package:'.length, libraryUri.indexOf('/'));
      if (importedPackage != currentPackage) return;

      final packagePath = uri.substring(slashIndex + 1);
      final segments = packagePath.split('/');

      // 디렉토리 깊이 = 세그먼트 수 - 1 (파일명 제외)
      final dirDepth = segments.length - 1;

      if (dirDepth > _maxDepth) {
        reporter.atNode(node, _code);
      }
    });
  }
}
