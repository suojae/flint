import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../utils/widget_helpers.dart';

/// # avoid_single_child_column_or_row
///
/// ## 규칙
/// Column이나 Row에 자식이 하나만 있으면 사용하지 마세요.
/// 대신 `Align`, `Padding`, 또는 자식 위젯을 직접 사용하세요.
///
/// ## 원리
/// Column과 Row는 **Flex 레이아웃** 위젯입니다.
/// 내부적으로 자식들의 크기를 측정하고, mainAxis/crossAxis 정렬을 계산하고,
/// 남은 공간을 분배합니다. 자식이 하나뿐이면 이 모든 계산이 낭비입니다.
///
/// 또한 코드를 읽는 사람 입장에서 Column/Row는 "여러 위젯을 배치하겠다"는
/// 의도를 전달합니다. 자식이 하나면 의도가 불분명해집니다.
///
/// ## 나쁜 예
/// ```dart
/// Column(
///   children: [
///     Text('hello'),
///   ],
/// )
/// ```
///
/// ## 좋은 예
/// ```dart
/// // 정렬이 필요하면 Align
/// Align(
///   alignment: Alignment.centerLeft,
///   child: Text('hello'),
/// )
///
/// // 패딩이 필요하면 Padding
/// Padding(
///   padding: EdgeInsets.all(16),
///   child: Text('hello'),
/// )
///
/// // 아무것도 필요 없으면 그냥 직접 사용
/// Text('hello')
/// ```
class AvoidSingleChildColumnOrRow extends DartLintRule {
  AvoidSingleChildColumnOrRow() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_single_child_column_or_row',
    problemMessage:
        'Avoid using Column or Row with a single child. '
        'It adds unnecessary layout overhead.',
    correctionMessage:
        'Use Align, Padding, or the child widget directly instead.',
  );

  static const _flexWidgets = {'Column', 'Row'};

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final widgetName = getWidgetName(node);
      if (widgetName == null || !_flexWidgets.contains(widgetName)) return;

      final childrenArg = getNamedArgument(node, 'children');
      if (childrenArg == null) return;

      final expression = childrenArg.expression;
      if (expression is ListLiteral && expression.elements.length == 1) {
        reporter.reportErrorForNode(_code, node);
      }
    });
  }
}
