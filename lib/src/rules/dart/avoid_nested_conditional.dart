import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// # avoid_nested_conditional
///
/// ## 규칙
/// 삼항 연산자(`? :`)를 중첩하지 마세요.
/// 중첩된 삼항 연산자는 읽기 매우 어렵습니다.
///
/// ## 원리
/// 삼항 연산자 하나는 간결하지만, 중첩되면 어떤 조건이
/// 어떤 값에 대응하는지 파악하기 힘들어집니다.
/// if-else 문이나 switch 표현식으로 대체하면
/// 각 분기의 의도가 명확해집니다.
///
/// ## 나쁜 예
/// ```dart
/// final label = isAdmin
///     ? 'Admin'
///     : isMember
///         ? 'Member'
///         : 'Guest';
/// ```
///
/// ## 좋은 예
/// ```dart
/// final label = switch (role) {
///   Role.admin => 'Admin',
///   Role.member => 'Member',
///   _ => 'Guest',
/// };
/// ```
class AvoidNestedConditional extends DartLintRule {
  AvoidNestedConditional() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_nested_conditional',
    problemMessage:
        'Avoid nesting ternary (conditional) expressions. '
        'They are difficult to read.',
    correctionMessage:
        'Use if-else statements, switch expressions, '
        'or extract the logic into a separate function.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addConditionalExpression((node) {
      if (node.condition is ConditionalExpression ||
          node.thenExpression is ConditionalExpression ||
          node.elseExpression is ConditionalExpression) {
        reporter.atNode(node, _code);
      }
    });
  }
}
