import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # prefer_explicit_return_type
///
/// ## 규칙
/// 함수와 메서드에 반환 타입을 명시하세요.
/// 반환 타입을 생략하면 암묵적으로 `dynamic`이 됩니다.
///
/// ## 원리
/// 반환 타입이 없으면 호출부에서 반환값의 타입을 알 수 없고,
/// 컴파일러도 타입 검사를 하지 않습니다.
/// 반환값에 대한 자동완성도 동작하지 않습니다.
///
/// 명시적 반환 타입은 함수의 계약(contract)을 명확히 하고,
/// 실수로 다른 타입을 반환하는 것을 컴파일 타임에 잡아줍니다.
///
/// ## 나쁜 예
/// ```dart
/// fetchUser(int id) async {
///   return await api.getUser(id);
/// }
///
/// calculate(int a, int b) {
///   return a + b;
/// }
/// ```
///
/// ## 좋은 예
/// ```dart
/// Future<User> fetchUser(int id) async {
///   return await api.getUser(id);
/// }
///
/// int calculate(int a, int b) {
///   return a + b;
/// }
/// ```
class PreferExplicitReturnType extends FlintLintRule {
  PreferExplicitReturnType() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_explicit_return_type',
    problemMessage:
        'Function is missing an explicit return type. '
        'Without it, the return type is implicitly "dynamic".',
    correctionMessage:
        'Add an explicit return type such as void, int, Future<T>, etc.',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionDeclaration((node) {
      if (node.returnType == null) {
        reporter.atToken(node.name, _code);
      }
    });

    context.registry.addMethodDeclaration((node) {
      // setter는 반환 타입이 없는 게 정상
      if (node.isSetter) return;

      if (node.returnType == null) {
        reporter.atToken(node.name, _code);
      }
    });
  }
}
