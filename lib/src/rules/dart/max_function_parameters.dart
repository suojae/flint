import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// # max_function_parameters
///
/// ## 규칙
/// 함수나 메서드의 파라미터가 4개를 초과하면 경고합니다.
/// 관련 파라미터를 클래스로 묶어 가독성을 높이세요.
///
/// ## 원리
/// 파라미터가 많은 함수는 호출부에서 읽기 어렵고,
/// 파라미터 순서를 실수하기 쉽습니다.
/// 관련 파라미터를 객체로 그룹화하면 의미가 명확해지고,
/// 변경 시 시그니처를 수정할 필요가 줄어듭니다.
///
/// ## 나쁜 예
/// ```dart
/// void createUser(
///   String name,
///   String email,
///   int age,
///   String address,
///   String phone,
/// ) { ... }
/// ```
///
/// ## 좋은 예
/// ```dart
/// void createUser(CreateUserRequest request) { ... }
///
/// class CreateUserRequest {
///   final String name;
///   final String email;
///   final int age;
///   final String address;
///   final String phone;
/// }
/// ```
class MaxFunctionParameters extends DartLintRule {
  MaxFunctionParameters() : super(code: _code);

  static const _code = LintCode(
    name: 'max_function_parameters',
    problemMessage:
        'Function has more than 4 parameters. '
        'Consider grouping related parameters into a class.',
    correctionMessage:
        'Extract related parameters into a dedicated '
        'parameter object or use a builder pattern.',
  );

  static const _maxParameters = 4;

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionDeclaration((node) {
      final paramCount =
          node.functionExpression.parameters?.parameters.length ?? 0;
      if (paramCount > _maxParameters) {
        reporter.atNode(node, _code);
      }
    });

    context.registry.addMethodDeclaration((node) {
      final paramCount = node.parameters?.parameters.length ?? 0;
      if (paramCount > _maxParameters) {
        reporter.atNode(node, _code);
      }
    });
  }
}
