import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../utils/widget_helpers.dart';

/// # avoid_visibility_widget
///
/// ## 규칙
/// 위젯을 숨길 때 `Visibility`나 `Offstage`를 사용하지 마세요.
/// 대신 `if (condition) Widget()` 패턴으로 위젯 트리에서 완전히 제거하세요.
///
/// ## 원리
/// Visibility(visible: false)로 숨긴 위젯은 **화면에 안 보일 뿐,
/// 위젯 트리에는 여전히 존재합니다.** 이로 인해 두 가지 문제가 생깁니다:
///
/// 1. **고스트 터치 버그**: 보이지 않는 위젯이 아래에 있는 버튼의
///    터치 이벤트를 가로챕니다. 사용자가 버튼을 눌렀는데 반응이 없는
///    원인 불명의 버그가 됩니다.
///
/// 2. **불필요한 리소스 소비**: 숨겨진 위젯도 build, layout, paint
///    파이프라인을 통과하며, State도 유지됩니다.
///
/// `if (condition)` 패턴을 쓰면 위젯이 트리에서 완전히 사라지므로
/// 두 문제 모두 원천적으로 방지됩니다.
///
/// ## 나쁜 예
/// ```dart
/// Visibility(
///   visible: isShown,
///   child: MyWidget(),
/// )
/// ```
///
/// ## 좋은 예
/// ```dart
/// if (isShown) MyWidget()
/// ```
class AvoidVisibilityWidget extends DartLintRule {
  AvoidVisibilityWidget() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_visibility_widget',
    problemMessage:
        'Avoid Visibility/Offstage to hide widgets. '
        'Hidden widgets still consume resources and can intercept touches.',
    correctionMessage:
        'Use conditional rendering: if (condition) Widget() instead.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final widgetName = getWidgetName(node);

      if (widgetName == 'Visibility') {
        final visibleArg = getNamedArgument(node, 'visible');
        if (visibleArg != null && _isFalseLiteral(visibleArg.expression)) {
          reporter.reportErrorForNode(_code, node);
          return;
        }
        // Even when using a variable, warn about Visibility usage
        if (visibleArg != null) {
          reporter.reportErrorForNode(_code, node);
        }
      }

      if (widgetName == 'Offstage') {
        reporter.reportErrorForNode(_code, node);
      }
    });
  }

  bool _isFalseLiteral(Expression expression) {
    return expression is BooleanLiteral && !expression.value;
  }
}
