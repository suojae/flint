import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # avoid_as_cast
///
/// ## 규칙
/// `as` 타입 캐스팅을 사용하지 마세요.
/// 런타임에 `TypeError`가 발생할 수 있습니다.
///
/// ## 원리
/// `as`는 "이 값은 반드시 이 타입이다"라고 런타임에 강제합니다.
/// 만약 실제 타입이 다르면 즉시 `TypeError`로 크래시합니다.
///
/// `is` 체크나 패턴 매칭을 사용하면 컴파일러가 자동으로
/// 타입을 좁혀주므로(smart cast) 안전하게 사용할 수 있습니다.
///
/// ## 나쁜 예
/// ```dart
/// final name = (data as Map)['name'];
/// final user = object as User;
/// ```
///
/// ## 좋은 예
/// ```dart
/// if (data case Map data) {
///   final name = data['name'];
/// }
///
/// if (object is User) {
///   print(object.name); // smart cast
/// }
/// ```
class AvoidAsCast extends FlintLintRule {
  AvoidAsCast() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_as_cast',
    problemMessage:
        'Avoid using "as" for type casting. '
        'It can throw TypeError at runtime.',
    correctionMessage:
        'Use "is" type check or pattern matching for safe type narrowing.',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addAsExpression((node) {
      reporter.atNode(node, _code);
    });
  }
}
