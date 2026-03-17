import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # avoid_deep_import
///
/// ## 규칙
/// 현재 파일에서 import 대상까지의 상대 경로를 계산하여
/// `../` 횟수가 2를 초과하면 경고합니다.
///
/// ## 원리
/// 상대 경로상 `../`가 많다는 것은 현재 위치에서 멀리 떨어진
/// 모듈의 내부를 직접 참조한다는 의미입니다.
/// 가까운 파일끼리의 import는 자연스럽지만,
/// 먼 모듈의 깊은 경로를 참조하면 구조 변경에 취약해집니다.
///
/// ## 나쁜 예
/// ```dart
/// // features/auth/data/repo.dart 에서:
/// // ../../../payment/domain/entities/payment.dart (../ 3회)
/// import 'package:app/features/payment/domain/entities/payment.dart';
/// ```
///
/// ## 좋은 예
/// ```dart
/// // features/auth/data/repo.dart 에서:
/// // ../domain/entities/user.dart (../ 1회)
/// import 'package:app/features/auth/domain/entities/user.dart';
/// ```
class AvoidDeepImport extends FlintLintRule {
  AvoidDeepImport() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_deep_import',
    problemMessage:
        'Import is too far from the current file (more than 2 levels up). '
        'This creates tight coupling to a distant module\'s internals.',
    correctionMessage:
        'Import from a shallower public API, or restructure '
        'to keep related files closer.',
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

      // 현재 파일과 import 대상의 디렉토리 세그먼트 추출
      final importedSegments = uri.substring(slashIndex + 1).split('/');
      final importedDir = importedSegments.sublist(
        0,
        importedSegments.length - 1,
      );

      final currentSegments =
          libraryUri.substring(libraryUri.indexOf('/') + 1).split('/');
      final currentDir = currentSegments.sublist(
        0,
        currentSegments.length - 1,
      );

      // 공통 접두사 길이 계산
      int commonPrefix = 0;
      while (commonPrefix < currentDir.length &&
          commonPrefix < importedDir.length &&
          currentDir[commonPrefix] == importedDir[commonPrefix]) {
        commonPrefix++;
      }

      // ../  횟수 = 현재 디렉토리에서 공통 조상까지 올라가는 단계
      final levelsUp = currentDir.length - commonPrefix;

      if (levelsUp > _maxDepth) {
        reporter.atNode(node, _code);
      }
    });
  }
}
