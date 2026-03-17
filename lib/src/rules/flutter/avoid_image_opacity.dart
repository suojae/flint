import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

import 'package:flint/src/utils/widget_helpers.dart';

/// # avoid_image_opacity
///
/// ## 규칙
/// Image 위젯을 Opacity로 감싸지 마세요.
/// 대신 Image의 `color` + `colorBlendMode` 속성을 사용하세요.
///
/// ## 원리
/// Opacity 위젯은 자식을 **별도의 오프스크린 버퍼(중간 캔버스)**에 먼저 그린 뒤,
/// 그 버퍼 전체에 투명도를 적용하고, 다시 화면에 합성합니다. (3단계)
///
/// 반면 Image의 color + colorBlendMode를 쓰면 이미지를 그리는 **그 순간에**
/// 각 픽셀의 투명도를 바로 조절합니다. 중간 버퍼가 필요 없습니다. (1단계)
///
/// 비유하면:
/// - Opacity = 사진을 인화한 뒤, 반투명 유리 뒤에 놓기 (비효율)
/// - color + colorBlendMode = 처음부터 연하게 인화하기 (효율)
///
/// 리스트에서 이미지 여러 개에 Opacity를 쓰면 스크롤 시 프레임 드랍이 발생합니다.
///
/// ## 나쁜 예
/// ```dart
/// Opacity(
///   opacity: 0.5,
///   child: Image.asset('photo.png'),
/// )
/// ```
///
/// ## 좋은 예
/// ```dart
/// Image.asset(
///   'photo.png',
///   color: Color.fromRGBO(255, 255, 255, 0.5),
///   colorBlendMode: BlendMode.modulate,
/// )
/// ```
class AvoidImageOpacity extends FlintLintRule {
  AvoidImageOpacity() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_image_opacity',
    problemMessage:
        'Avoid wrapping Image with Opacity. '
        'Use Image\'s color + colorBlendMode instead for better performance.',
    correctionMessage:
        'Remove Opacity and use Image(color: Color.fromRGBO(255, 255, 255, '
        'opacity), colorBlendMode: BlendMode.modulate).',
  );

  static const _imageTypes = {'Image', 'FadeInImage', 'CachedNetworkImage'};

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final widgetName = getWidgetName(node);
      if (widgetName != 'Opacity' && widgetName != 'AnimatedOpacity') return;

      final childArg = getNamedArgument(node, 'child');
      if (childArg == null) return;

      if (isWidgetOfType(childArg.expression, _imageTypes)) {
        reporter.atNode(node, _code);
      }
    });
  }
}
