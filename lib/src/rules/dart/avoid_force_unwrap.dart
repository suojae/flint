import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # avoid_force_unwrap
///
/// ## 규칙
/// null 단언 연산자(`!`)를 사용하지 마세요.
/// 런타임에 null이면 즉시 크래시가 발생합니다.
///
/// ## 원리
/// `!` 연산자는 "이 값은 절대 null이 아니다"라고 컴파일러에게
/// 약속하는 것입니다. 하지만 이 약속이 깨지면 `Null check operator
/// used on a null value` 예외가 발생합니다.
///
/// null-aware 연산자(`?.`, `??`)나 패턴 매칭, 명시적 null 체크로
/// 안전하게 처리하세요.
///
/// ## 나쁜 예
/// ```dart
/// final name = user.name!;
/// final value = map['key']!;
/// widget.callback!();
/// ```
///
/// ## 좋은 예
/// ```dart
/// final name = user.name ?? 'Unknown';
///
/// if (user.name case final name?) {
///   print(name);
/// }
///
/// final value = map['key'];
/// if (value != null) {
///   use(value);
/// }
/// ```
class AvoidForceUnwrap extends FlintLintRule {
  AvoidForceUnwrap() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_force_unwrap',
    problemMessage:
        'Avoid using the null assertion operator (!). '
        'It can cause runtime exceptions.',
    correctionMessage:
        'Use null-aware operators (?., ??), '
        'pattern matching, or explicit null checks instead.',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPostfixExpression((node) {
      if (node.operator.type == TokenType.BANG) {
        reporter.atNode(node, _code);
      }
    });
  }
}
