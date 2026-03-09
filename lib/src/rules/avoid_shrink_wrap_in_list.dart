import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../utils/widget_helpers.dart';

/// # avoid_shrink_wrap_in_list
///
/// ## 규칙
/// ListView, GridView, PageView에서 `shrinkWrap: true`를 사용하지 마세요.
/// 대신 `CustomScrollView` + `SliverList`를 사용하세요.
///
/// ## 원리
/// Flutter의 리스트 위젯은 기본적으로 **lazy rendering**을 합니다.
/// 화면에 보이는 아이템만 build하고, 스크롤하면 새 아이템을 그리고
/// 벗어난 아이템은 폐기합니다. 1000개 아이템이 있어도 화면에 보이는
/// 10개만 메모리에 올립니다.
///
/// `shrinkWrap: true`를 켜면 이 최적화가 **완전히 무효화**됩니다.
/// 리스트의 전체 높이를 알아야 하기 때문에 **1000개 아이템을 전부
/// 한꺼번에 build**합니다. 결과적으로:
///
/// - 초기 렌더링이 느려짐 (아이템 수에 비례)
/// - 메모리 사용량 급증
/// - 스크롤 시 프레임 드랍(jank) 발생
///
/// ## 나쁜 예
/// ```dart
/// ListView.builder(
///   shrinkWrap: true,
///   itemCount: items.length,
///   itemBuilder: (_, i) => ItemWidget(items[i]),
/// )
/// ```
///
/// ## 좋은 예
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverList.builder(
///       delegate: SliverChildBuilderDelegate(
///         (_, i) => ItemWidget(items[i]),
///         childCount: items.length,
///       ),
///     ),
///   ],
/// )
/// ```
class AvoidShrinkWrapInList extends DartLintRule {
  AvoidShrinkWrapInList() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_shrink_wrap_in_list',
    problemMessage:
        'Avoid shrinkWrap: true in scrollable lists. '
        'It forces all children to be laid out at once, killing performance.',
    correctionMessage:
        'Use CustomScrollView with SliverList, or set a fixed height with '
        'SizedBox.',
  );

  static const _scrollableWidgets = {
    'ListView',
    'GridView',
    'PageView',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final widgetName = getWidgetName(node);
      if (widgetName == null || !_scrollableWidgets.contains(widgetName)) {
        return;
      }

      final shrinkWrapArg = getNamedArgument(node, 'shrinkWrap');
      if (shrinkWrapArg == null) return;

      if (_isTrueLiteral(shrinkWrapArg.expression)) {
        reporter.reportErrorForNode(_code, node);
      }
    });
  }

  bool _isTrueLiteral(Expression expression) {
    return expression is BooleanLiteral && expression.value;
  }
}
