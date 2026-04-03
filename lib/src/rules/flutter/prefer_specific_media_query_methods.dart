import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # prefer_specific_media_query_methods
///
/// ## 규칙
/// `MediaQuery.of(context)` 또는 `MediaQuery.maybeOf(context)`로
/// 전체 `MediaQueryData`를 구독하지 말고, 가능하면
/// `MediaQuery.sizeOf(context)`, `MediaQuery.widthOf(context)`,
/// `MediaQuery.paddingOf(context)`, `MediaQuery.devicePixelRatioOf(context)`
/// 같은 전용 접근자를 사용하세요.
///
/// ## 원리
/// `MediaQuery.of(context)`는 `MediaQueryData` 전체에 의존합니다.
/// 그래서 orientation, padding, text scaling 등 어떤 필드가 바뀌어도
/// 이 값을 읽는 위젯이 다시 build 됩니다.
///
/// 반면 Flutter가 제공하는 전용 `...Of`/`maybe...Of` 메서드는
/// 필요한 필드에만 의존하도록 구독 범위를 좁혀서
/// 불필요한 rebuild를 줄일 수 있습니다.
///
/// ## 감지 대상
/// - `MediaQuery.of(context).size`
/// - `MediaQuery.of(context).size.width`
/// - `MediaQuery.of(context).devicePixelRatio`
/// - `MediaQuery.of(context).padding`
/// - `MediaQuery.maybeOf(context)?.viewInsets`
/// - 그 외 Flutter가 전용 accessor를 제공하는 `MediaQueryData` 속성
///
/// ## 나쁜 예
/// ```dart
/// final width = MediaQuery.of(context).size.width;
/// final ratio = MediaQuery.of(context).devicePixelRatio;
/// final insets = MediaQuery.maybeOf(context)?.viewInsets;
/// ```
///
/// ## 좋은 예
/// ```dart
/// final width = MediaQuery.widthOf(context);
/// final ratio = MediaQuery.devicePixelRatioOf(context);
/// final insets = MediaQuery.maybeViewInsetsOf(context);
/// ```
class PreferSpecificMediaQueryMethods extends FlintLintRule {
  PreferSpecificMediaQueryMethods() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_specific_media_query_methods',
    problemMessage:
        'Avoid MediaQuery.of(context) or MediaQuery.maybeOf(context) when '
        'a more specific MediaQuery accessor exists.',
    correctionMessage:
        'Use a dedicated accessor such as MediaQuery.sizeOf(context), '
        'MediaQuery.widthOf(context), MediaQuery.paddingOf(context), '
        'MediaQuery.maybeViewInsetsOf(context), or '
        'MediaQuery.devicePixelRatioOf(context) to reduce unnecessary rebuilds.',
  );

  static const _propertyReplacements = <String, _Replacement>{
    'accessibleNavigation': _Replacement(
      ofMethod: 'accessibleNavigationOf',
      maybeMethod: 'maybeAccessibleNavigationOf',
    ),
    'alwaysUse24HourFormat': _Replacement(
      ofMethod: 'alwaysUse24HourFormatOf',
      maybeMethod: 'maybeAlwaysUse24HourFormatOf',
    ),
    'boldText': _Replacement(
      ofMethod: 'boldTextOf',
      maybeMethod: 'maybeBoldTextOf',
    ),
    'devicePixelRatio': _Replacement(
      ofMethod: 'devicePixelRatioOf',
      maybeMethod: 'maybeDevicePixelRatioOf',
    ),
    'disableAnimations': _Replacement(
      ofMethod: 'disableAnimationsOf',
      maybeMethod: 'maybeDisableAnimationsOf',
    ),
    'displayFeatures': _Replacement(
      ofMethod: 'displayFeaturesOf',
      maybeMethod: 'maybeDisplayFeaturesOf',
    ),
    'gestureSettings': _Replacement(
      ofMethod: 'gestureSettingsOf',
      maybeMethod: 'maybeGestureSettingsOf',
    ),
    'highContrast': _Replacement(
      ofMethod: 'highContrastOf',
      maybeMethod: 'maybeHighContrastOf',
    ),
    'invertColors': _Replacement(
      ofMethod: 'invertColorsOf',
      maybeMethod: 'maybeInvertColorsOf',
    ),
    'navigationMode': _Replacement(
      ofMethod: 'navigationModeOf',
      maybeMethod: 'maybeNavigationModeOf',
    ),
    'onOffSwitchLabels': _Replacement(
      ofMethod: 'onOffSwitchLabelsOf',
      maybeMethod: 'maybeOnOffSwitchLabelsOf',
    ),
    'orientation': _Replacement(
      ofMethod: 'orientationOf',
      maybeMethod: 'maybeOrientationOf',
    ),
    'padding': _Replacement(
      ofMethod: 'paddingOf',
      maybeMethod: 'maybePaddingOf',
    ),
    'platformBrightness': _Replacement(
      ofMethod: 'platformBrightnessOf',
      maybeMethod: 'maybePlatformBrightnessOf',
    ),
    'size': _Replacement(
      ofMethod: 'sizeOf',
      maybeMethod: 'maybeSizeOf',
    ),
    'supportsAnnounce': _Replacement(
      ofMethod: 'supportsAnnounceOf',
      maybeMethod: 'maybeSupportsAnnounceOf',
    ),
    'supportsShowingSystemContextMenu': _Replacement(
      ofMethod: 'supportsShowingSystemContextMenu',
      maybeMethod: 'maybeSupportsShowingSystemContextMenu',
    ),
    'systemGestureInsets': _Replacement(
      ofMethod: 'systemGestureInsetsOf',
      maybeMethod: 'maybeSystemGestureInsetsOf',
    ),
    'textScaler': _Replacement(
      ofMethod: 'textScalerOf',
      maybeMethod: 'maybeTextScalerOf',
    ),
    'viewInsets': _Replacement(
      ofMethod: 'viewInsetsOf',
      maybeMethod: 'maybeViewInsetsOf',
    ),
    'viewPadding': _Replacement(
      ofMethod: 'viewPaddingOf',
      maybeMethod: 'maybeViewPaddingOf',
    ),
  };

  static const _sizeDimensionReplacements = <String, _Replacement>{
    'height': _Replacement(
      ofMethod: 'heightOf',
      maybeMethod: 'maybeHeightOf',
    ),
    'width': _Replacement(
      ofMethod: 'widthOf',
      maybeMethod: 'maybeWidthOf',
    ),
  };

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPropertyAccess((node) {
      if (_isSizeAccessCoveredByDimensionAccess(node)) return;
      if (_matchesSpecificMediaQueryAccess(node) == null) return;

      reporter.atNode(node, _code);
    });
  }

  _Replacement? _matchesSpecificMediaQueryAccess(PropertyAccess node) {
    final sizeDimensionReplacement = _matchSizeDimensionReplacement(node);
    if (sizeDimensionReplacement != null) {
      return sizeDimensionReplacement;
    }

    final mediaQueryLookup = _matchMediaQueryLookup(node.target);
    if (mediaQueryLookup == null) return null;

    return _propertyReplacements[node.propertyName.name];
  }

  _Replacement? _matchSizeDimensionReplacement(PropertyAccess node) {
    final replacement = _sizeDimensionReplacements[node.propertyName.name];
    if (replacement == null) return null;

    final target = _unwrapParentheses(node.target);
    if (target is! PropertyAccess || target.propertyName.name != 'size') {
      return null;
    }

    return _matchMediaQueryLookup(target.target) == null ? null : replacement;
  }

  bool _isSizeAccessCoveredByDimensionAccess(PropertyAccess node) {
    if (node.propertyName.name != 'size') return false;

    final parent = node.parent;
    if (parent is PropertyAccess && identical(parent.target, node)) {
      return _sizeDimensionReplacements.containsKey(parent.propertyName.name);
    }

    if (parent is ParenthesizedExpression) {
      final grandParent = parent.parent;
      if (grandParent is PropertyAccess &&
          identical(grandParent.target, parent)) {
        return _sizeDimensionReplacements
            .containsKey(grandParent.propertyName.name);
      }
    }

    return false;
  }

  _MediaQueryLookup? _matchMediaQueryLookup(Expression? expression) {
    final target = _unwrapParentheses(expression);
    if (target is! MethodInvocation) return null;

    final methodName = target.methodName.name;
    if (methodName != 'of' && methodName != 'maybeOf') return null;
    if (!_isFlutterMediaQueryMethod(target.methodName.element)) return null;

    return _MediaQueryLookup(isMaybe: methodName == 'maybeOf');
  }

  Expression? _unwrapParentheses(Expression? expression) {
    var current = expression;
    while (current is ParenthesizedExpression) {
      current = current.expression;
    }
    return current;
  }

  bool _isFlutterMediaQueryMethod(Element? element) {
    if (element is! ExecutableElement) return false;

    final enclosingElement = element.enclosingElement;
    if (enclosingElement is! InterfaceElement) return false;

    return enclosingElement.name == 'MediaQuery' &&
        element.library.uri.toString().startsWith('package:flutter/');
  }
}

class _MediaQueryLookup {
  const _MediaQueryLookup({required this.isMaybe});

  final bool isMaybe;
}

class _Replacement {
  const _Replacement({
    required this.ofMethod,
    required this.maybeMethod,
  });

  final String ofMethod;
  final String maybeMethod;
}
