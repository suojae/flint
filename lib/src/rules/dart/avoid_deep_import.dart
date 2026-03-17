import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # avoid_deep_import
///
/// ## 규칙
/// `package:` import 경로의 디렉토리 깊이가 2를 초과하고,
/// 현재 파일과 다른 모듈에 속하면 경고합니다.
///
/// 같은 모듈(2뎁스까지 경로가 동일) 내부의 파일끼리는
/// 깊은 import가 허용됩니다.
///
/// ## 원리
/// 다른 모듈의 깊은 경로를 직접 import하면 해당 모듈의 내부 구현에
/// 직접 의존하게 됩니다. 내부 구조가 변경되면 import한 모든 곳이
/// 깨집니다.
///
/// 같은 모듈 내부에서는 구현 파일끼리 자유롭게 참조해야 하므로
/// 깊은 import가 자연스럽습니다.
///
/// ## 나쁜 예
/// ```dart
/// // features/auth/data/repo.dart 에서:
/// import 'package:app/features/payment/domain/entities/payment.dart';
/// ```
///
/// ## 좋은 예
/// ```dart
/// // features/auth/data/repo.dart 에서:
/// import 'package:app/features/auth/domain/entities/user.dart'; // 같은 모듈
///
/// // 또는 2뎁스 이내의 외부 모듈
/// import 'package:app/core/network/dio_client.dart';
/// ```
class AvoidDeepImport extends FlintLintRule {
  AvoidDeepImport() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_deep_import',
    problemMessage:
        'Deep import into another module\'s internals. '
        'This creates tight coupling to internal module structure.',
    correctionMessage:
        'Import from a shallower public API, or move this code '
        'into the same module.',
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

      final importedPath = uri.substring(slashIndex + 1);
      final importedSegments = importedPath.split('/');

      // 디렉토리 깊이 = 세그먼트 수 - 1 (파일명 제외)
      final dirDepth = importedSegments.length - 1;
      if (dirDepth <= _maxDepth) return;

      // 현재 파일의 경로와 비교하여 같은 모듈인지 확인
      final currentPath =
          libraryUri.substring(libraryUri.indexOf('/') + 1);
      final currentSegments = currentPath.split('/');

      // _maxDepth 레벨까지 경로가 동일하면 같은 모듈로 판단
      bool sameModule = true;
      for (int i = 0; i < _maxDepth; i++) {
        if (i >= currentSegments.length ||
            i >= importedSegments.length ||
            currentSegments[i] != importedSegments[i]) {
          sameModule = false;
          break;
        }
      }

      if (!sameModule) {
        reporter.atNode(node, _code);
      }
    });
  }
}
