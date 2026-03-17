import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # avoid_direct_firebase_analytics
///
/// ## 규칙
/// `FirebaseAnalytics`를 직접 사용하지 마세요.
/// 모든 analytics 호출은 `AnalyticsService` 래퍼를 통해야 합니다.
///
/// ## 원리
/// FirebaseAnalytics를 직접 호출하면:
/// - 환경별(dev/prod) 수집 ON/OFF 일괄 제어가 불가능합니다.
/// - 이벤트 네이밍 규칙이 파편화됩니다.
/// - 향후 analytics 제공자 교체(Firebase → Amplitude 등) 시
///   모든 호출부를 수정해야 합니다.
///
/// `AnalyticsService`를 통해 호출하면 한 곳에서 일괄 관리할 수 있습니다.
///
/// ## 예외
/// - `analytics_service.dart` 파일은 검사에서 제외됩니다.
/// - `analytics_bloc_observer.dart` 파일은 검사에서 제외됩니다.
/// - `analytics_route_observer.dart` 파일은 검사에서 제외됩니다.
///
/// ## 나쁜 예
/// ```dart
/// // some_widget.dart
/// FirebaseAnalytics.instance.logEvent(name: 'button_click');
/// ```
///
/// ## 좋은 예
/// ```dart
/// // some_widget.dart
/// analyticsService.track('button_click');
/// ```
class AvoidDirectFirebaseAnalytics extends FlintLintRule {
  AvoidDirectFirebaseAnalytics() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_direct_firebase_analytics',
    problemMessage:
        'Do not use FirebaseAnalytics directly. '
        'All analytics calls must go through AnalyticsService.',
    correctionMessage:
        'Use AnalyticsService methods instead. '
        'This ensures consistent event naming and environment control.',
  );

  /// Analytics를 직접 다루는 것이 허용되는 파일들
  static final _allowedFilePattern = RegExp(
    r'(analytics_service|analytics_bloc_observer|analytics_route_observer)\.dart$',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    // 허용된 서비스 파일에서는 검사하지 않음
    if (_allowedFilePattern.hasMatch(resolver.path)) return;

    // FirebaseAnalytics.instance 프로퍼티 접근 감지
    context.registry.addPropertyAccess((node) {
      final target = node.target;
      if (target is SimpleIdentifier &&
          target.name == 'FirebaseAnalytics' &&
          node.propertyName.name == 'instance') {
        reporter.atNode(node, _code);
      }
    });

    // FirebaseAnalytics.instance.xxx() 메서드 호출 감지
    context.registry.addMethodInvocation((node) {
      final target = node.target;
      if (target is PrefixedIdentifier &&
          target.prefix.name == 'FirebaseAnalytics' &&
          target.identifier.name == 'instance') {
        reporter.atNode(node, _code);
      }
    });

    // firebase_analytics import 감지
    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null) return;
      if (uri == 'package:firebase_analytics/firebase_analytics.dart') {
        reporter.atNode(node, _code);
      }
    });
  }
}
