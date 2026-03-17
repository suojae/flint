import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

import 'package:flint/src/utils/widget_helpers.dart';

/// # avoid_nested_padding
///
/// ## 규칙
/// Padding 위젯 안에 또 Padding 위젯을 넣지 마세요.
/// 하나의 Padding으로 합치세요.
///
/// ## 원리
/// 중첩된 Padding은 각각 별도의 RenderObject를 생성합니다.
/// 레이아웃 단계에서 불필요한 계산이 두 번 일어나고,
/// 렌더 트리의 깊이가 깊어집니다.
///
/// 더 중요한 건 **가독성**입니다. 중첩 Padding이 있으면 실제로
/// 적용되는 여백이 몇인지 두 위젯의 값을 더해서 계산해야 합니다.
/// 하나로 합치면 의도가 명확해집니다.
///
/// ## 나쁜 예
/// ```dart
/// Padding(
///   padding: EdgeInsets.symmetric(horizontal: 16),
///   child: Padding(
///     padding: EdgeInsets.only(top: 8),
///     child: Text('hello'),
///   ),
/// )
/// ```
///
/// ## 좋은 예
/// ```dart
/// Padding(
///   padding: EdgeInsets.only(left: 16, right: 16, top: 8),
///   child: Text('hello'),
/// )
/// ```
class AvoidNestedPadding extends FlintLintRule {
  AvoidNestedPadding() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_nested_padding',
    problemMessage:
        'Avoid nesting Padding widgets. '
        'Each Padding creates a separate RenderObject.',
    correctionMessage: 'Merge into a single Padding with combined EdgeInsets.',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final widgetName = getWidgetName(node);
      if (widgetName != 'Padding') return;

      final childArg = getNamedArgument(node, 'child');
      if (childArg == null) return;

      if (isWidgetOfType(childArg.expression, const {'Padding'})) {
        reporter.atNode(node, _code);
      }
    });
  }
}
