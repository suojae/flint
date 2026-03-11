import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// # avoid_hardcoded_color
///
/// ## 규칙
/// build 메서드 안에서 `Color(0xFF...)`, `Color.fromRGBO(...)` 등
/// 색상을 직접 하드코딩하지 마세요.
/// 대신 `Theme.of(context).colorScheme` 또는 디자인 토큰을 사용하세요.
///
/// ## 원리
/// 하드코딩된 색상은 **다크모드에서 깨집니다.**
/// 앱이 라이트→다크 테마로 전환되어도 하드코딩된 색은 그대로이기 때문에,
/// 검은 배경 위에 검은 글씨가 되어 텍스트가 안 보이는 사고가 발생합니다.
///
/// colorScheme을 사용하면 테마 전환 시 Flutter가 자동으로
/// 적절한 색상으로 교체해줍니다.
///
/// ## 검사 범위
/// - `build()` 메서드 내부
/// - `buildXxx()`, `_buildXxx()` 패턴의 위젯 빌더 함수 내부
/// - 상수 정의, 테스트 파일 등은 검사하지 않음 (false positive 방지)
///
/// ## 나쁜 예
/// ```dart
/// Container(color: Color(0xFF000000))
/// Text('hello', style: TextStyle(color: Color(0xFFFFFFFF)))
/// ```
///
/// ## 좋은 예
/// ```dart
/// Container(color: Theme.of(context).colorScheme.surface)
/// Text('hello', style: TextStyle(color: context.colorScheme.onSurface))
/// ```
class AvoidHardcodedColor extends DartLintRule {
  AvoidHardcodedColor() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_hardcoded_color',
    problemMessage:
        'Avoid hardcoded Color values. '
        'Use Theme.of(context).colorScheme or design tokens instead.',
    correctionMessage:
        'Replace with a color from Theme.of(context).colorScheme.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final name = node.constructorName.type.name.lexeme;
      if (name != 'Color') return;

      // Only flag if inside a build method or widget tree
      if (!_isInsideBuildMethod(node)) return;

      reporter.atNode(node, _code);
    });

    // Also catch Color.fromRGBO, Color.fromARGB
    context.registry.addMethodInvocation((node) {
      final target = node.target;
      if (target is SimpleIdentifier && target.name == 'Color') {
        final methodName = node.methodName.name;
        if (methodName == 'fromRGBO' || methodName == 'fromARGB') {
          if (_isInsideBuildMethod(node)) {
            reporter.atNode(node, _code);
          }
        }
      }
    });
  }

  /// Checks if the node is inside a `build` method.
  /// This avoids false positives in test files, constants, etc.
  bool _isInsideBuildMethod(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is MethodDeclaration && current.name.lexeme == 'build') {
        return true;
      }
      // Also catch functions commonly used to build widgets
      if (current is FunctionDeclaration) {
        final name = current.name.lexeme;
        if (name.startsWith('build') || name.startsWith('_build')) {
          return true;
        }
      }
      current = current.parent;
    }
    return false;
  }
}
