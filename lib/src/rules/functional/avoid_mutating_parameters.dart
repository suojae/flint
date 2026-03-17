import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # avoid_mutating_parameters
///
/// ## 규칙
/// 함수나 메서드의 파라미터에 새 값을 할당하지 마세요.
/// 파라미터는 불변으로 취급하세요.
///
/// ## 원리
/// 파라미터를 재할당하면 원래 넘어온 값이 사라집니다.
/// 함수 중간에 `count = count + 1`이 있으면
/// 그 아래 코드에서 `count`가 원래 값인지 바뀐 값인지
/// 위로 올라가서 확인해야 합니다.
///
/// 새 변수에 담으면 원래 값과 변환된 값이 둘 다 살아있어서
/// 코드의 흐름이 명확해집니다.
///
/// ## 나쁜 예
/// ```dart
/// int calculate(int count) {
///   count = count + 1;  // 파라미터 재할당
///   return count * 2;
/// }
/// ```
///
/// ## 좋은 예
/// ```dart
/// int calculate(int count) {
///   final adjusted = count + 1;
///   return adjusted * 2;
/// }
/// ```
class AvoidMutatingParameters extends FlintLintRule {
  AvoidMutatingParameters() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_mutating_parameters',
    problemMessage:
        'Avoid reassigning function parameters. '
        'Treat them as immutable values.',
    correctionMessage:
        'Create a new local variable instead of reassigning the parameter.',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addAssignmentExpression((node) {
      final leftSide = node.leftHandSide;
      if (leftSide is! SimpleIdentifier) return;

      final paramNames = _getEnclosingParameterNames(node);
      if (paramNames.contains(leftSide.name)) {
        reporter.atNode(node, _code);
      }
    });
  }

  Set<String> _getEnclosingParameterNames(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      FormalParameterList? params;

      if (current is FunctionDeclaration) {
        params = current.functionExpression.parameters;
      } else if (current is MethodDeclaration) {
        params = current.parameters;
      } else if (current is FunctionExpression) {
        // 클로저 내부는 검사하지 않음 — 상위 함수 파라미터와 혼동 방지
        if (current.parent is! FunctionDeclaration) return {};
        params = current.parameters;
      }

      if (params != null) {
        return params.parameters
            .map((p) => p.name?.lexeme)
            .whereType<String>()
            .toSet();
      }
      current = current.parent;
    }
    return {};
  }
}
