import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// # prefer_pattern_matching
///
/// ## 규칙
/// 같은 변수에 대해 3개 이상의 if-else 체인으로 타입 검사(`is`)나
/// 값 비교(`==`)를 하고 있다면 switch 패턴 매칭을 사용하세요.
///
/// ## 원리
/// Dart 3의 switch 표현식은 패턴 매칭을 지원합니다.
/// if-else 체인은 분기가 늘어날수록 읽기 어렵고,
/// 새 케이스를 추가할 때 빠뜨리기 쉽습니다.
///
/// switch는 모든 케이스를 한눈에 볼 수 있고,
/// sealed class와 함께 쓰면 컴파일러가 빠진 케이스를 잡아줍니다.
///
/// ## 나쁜 예
/// ```dart
/// if (state is Loading) {
///   return spinner();
/// } else if (state is Success) {
///   return content(state.data);
/// } else if (state is Error) {
///   return errorView(state.message);
/// }
///
/// if (status == 'active') {
///   activate();
/// } else if (status == 'inactive') {
///   deactivate();
/// } else if (status == 'pending') {
///   wait();
/// }
/// ```
///
/// ## 좋은 예
/// ```dart
/// return switch (state) {
///   Loading()          => spinner(),
///   Success(:final data) => content(data),
///   Error(:final message) => errorView(message),
/// };
///
/// switch (status) {
///   case 'active':   activate();
///   case 'inactive': deactivate();
///   case 'pending':  wait();
/// }
/// ```
class PreferPatternMatching extends DartLintRule {
  PreferPatternMatching() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_pattern_matching',
    problemMessage:
        'Use switch pattern matching instead of if-else chains '
        'on the same variable.',
    correctionMessage:
        'Replace the if-else chain with a switch expression or statement.',
  );

  static const _minBranches = 3;

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addIfStatement((node) {
      // 중첩된 else-if의 일부면 스킵 (최상위 if만 검사)
      if (node.parent is IfStatement) return;

      final branches = _collectIfElseChain(node);
      if (branches.length < _minBranches) return;

      final targetName = _extractTargetName(branches.first);
      if (targetName == null) return;

      // 모든 분기가 같은 변수를 검사하는지 확인
      final allSameTarget = branches.every((condition) {
        return _extractTargetName(condition) == targetName;
      });

      if (allSameTarget) {
        reporter.atNode(node, _code);
      }
    });
  }

  /// if-else 체인의 모든 조건을 수집한다.
  List<Expression> _collectIfElseChain(IfStatement node) {
    final conditions = <Expression>[];
    IfStatement? current = node;

    while (current != null) {
      conditions.add(current.expression);
      final elseStmt = current.elseStatement;
      current = elseStmt is IfStatement ? elseStmt : null;
    }

    return conditions;
  }

  /// 조건에서 검사 대상 변수명을 추출한다.
  /// `x is Foo` → 'x', `x == 'bar'` → 'x'
  String? _extractTargetName(Expression condition) {
    if (condition is IsExpression) {
      final expr = condition.expression;
      if (expr is SimpleIdentifier) return expr.name;
    }
    if (condition is BinaryExpression && condition.operator.lexeme == '==') {
      final left = condition.leftOperand;
      if (left is SimpleIdentifier) return left.name;
    }
    return null;
  }
}
