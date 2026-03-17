import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # avoid_mutable_global_state
///
/// ## 규칙
/// 최상위(top-level) 변수를 `var`나 타입만으로 선언하지 마세요.
/// `final` 또는 `const`를 사용하세요.
///
/// ## 원리
/// 변경 가능한 전역 상태는 함수형 프로그래밍의 핵심 원칙인
/// **불변성(immutability)**을 깨뜨립니다.
///
/// 전역 `var`는 어디서든 값을 바꿀 수 있어서,
/// 코드를 읽을 때 "지금 이 변수가 어떤 상태인지"를
/// 프로그램 전체를 추적해야만 알 수 있습니다.
/// 테스트도 어려워지고, 동시성 환경에서는 race condition의 원인이 됩니다.
///
/// `final`이나 `const`로 선언하면 값이 한 번 정해진 뒤 바뀌지 않으므로
/// 코드의 예측 가능성이 높아집니다.
///
/// ## 나쁜 예
/// ```dart
/// var counter = 0;
/// List<String> items = [];
/// String currentUser = 'guest';
/// ```
///
/// ## 좋은 예
/// ```dart
/// final counter = 0;
/// const maxRetries = 3;
/// final List<String> items = List.unmodifiable([]);
/// ```
class AvoidMutableGlobalState extends FlintLintRule {
  AvoidMutableGlobalState() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_mutable_global_state',
    problemMessage:
        'Avoid mutable top-level variables. '
        'Global mutable state makes code unpredictable and hard to test.',
    correctionMessage: 'Use final or const instead of var.',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addTopLevelVariableDeclaration((node) {
      final variables = node.variables;

      // final이나 const면 OK
      if (variables.isFinal || variables.isConst) return;

      // late final도 OK
      if (variables.lateKeyword != null &&
          variables.keyword?.type == Keyword.FINAL) {
        return;
      }

      reporter.atNode(node, _code);
    });
  }
}
