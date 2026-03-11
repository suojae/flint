import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// # avoid_dynamic_type
///
/// ## 규칙
/// `dynamic` 타입을 명시적으로 사용하지 마세요.
/// 구체적인 타입, 제네릭, 또는 `Object?`를 사용하세요.
///
/// ## 원리
/// `dynamic`은 타입 시스템을 완전히 우회합니다.
/// 컴파일 타임에 어떤 타입 검사도 하지 않으므로
/// 런타임에서야 `NoSuchMethodError`가 터집니다.
///
/// 함수형 프로그래밍에서 타입은 "이 값으로 뭘 할 수 있는지"를
/// 문서화하는 역할입니다. `dynamic`은 그 문서를 찢어버리는 거와 같습니다.
///
/// `Object?`는 모든 타입을 받으면서도 타입 검사를 유지합니다.
/// "아무 타입이나 받겠다"는 의도라면 `Object?`가 더 안전합니다.
///
/// ## 나쁜 예
/// ```dart
/// dynamic value = getData();
/// void process(dynamic input) {}
/// List<dynamic> items = [];
/// ```
///
/// ## 좋은 예
/// ```dart
/// Object? value = getData();
/// void process(Object? input) {}
/// List<Item> items = [];
///
/// // 제네릭으로 타입을 유연하게
/// T parse<T>(String raw) => ...;
/// ```
class AvoidDynamicType extends DartLintRule {
  AvoidDynamicType() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_dynamic_type',
    problemMessage:
        'Avoid using "dynamic". '
        'It bypasses the type system entirely.',
    correctionMessage:
        'Use a specific type, a generic, or Object? instead.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addNamedType((node) {
      if (node.name.lexeme == 'dynamic') {
        reporter.atNode(node, _code);
      }
    });
  }
}
