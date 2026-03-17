import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # avoid_direct_crashlytics
///
/// ## 규칙
/// `FirebaseCrashlytics.instance`를 직접 사용하지 마세요.
/// 모든 에러 보고는 Talker를 경유해야 합니다.
///
/// ## 원리
/// Crashlytics를 직접 호출하면 Talker 로깅 파이프라인을 우회하여:
/// - 콘솔 로그가 남지 않아 개발 중 디버깅이 어렵습니다.
/// - CrashlyticsTalkerObserver의 필터링/포맷팅이 적용되지 않습니다.
/// - 로깅 경로가 이원화되어 추적이 힘들어집니다.
///
/// Crashlytics 직접 접근은 `CrashlyticsService`에서만 허용됩니다.
/// (fatal 에러 전송, 사용자 식별 등 초기화 전용)
///
/// ## 예외
/// - `crashlytics_service.dart` 파일은 검사에서 제외됩니다.
/// - `crashlytics_talker_observer.dart` 파일은 검사에서 제외됩니다.
///
/// ## 나쁜 예
/// ```dart
/// // some_repository.dart
/// try {
///   await api.fetch();
/// } catch (e, st) {
///   FirebaseCrashlytics.instance.recordError(e, st);
/// }
/// ```
///
/// ## 좋은 예
/// ```dart
/// // some_repository.dart
/// try {
///   await api.fetch();
/// } catch (e, st) {
///   talker.error('API fetch failed', e, st);
/// }
/// ```
class AvoidDirectCrashlytics extends FlintLintRule {
  AvoidDirectCrashlytics() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_direct_crashlytics',
    problemMessage:
        'Do not use FirebaseCrashlytics directly. '
        'All error reporting must go through Talker.',
    correctionMessage:
        'Use talker.error() or talker.handle() instead. '
        'Crashlytics receives errors via CrashlyticsTalkerObserver.',
  );

  /// Crashlytics를 직접 다루는 것이 허용되는 파일들
  static final _allowedFilePattern = RegExp(
    r'(crashlytics_service|crashlytics_talker_observer)\.dart$',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    // 허용된 서비스 파일에서는 검사하지 않음
    if (_allowedFilePattern.hasMatch(resolver.path)) return;

    // FirebaseCrashlytics.instance 프로퍼티 접근 감지
    context.registry.addPropertyAccess((node) {
      final target = node.target;
      if (target is SimpleIdentifier &&
          target.name == 'FirebaseCrashlytics' &&
          node.propertyName.name == 'instance') {
        reporter.atNode(node, _code);
      }
    });

    // FirebaseCrashlytics.instance.xxx() 메서드 호출 감지
    // (PropertyAccess가 target인 MethodInvocation)
    context.registry.addMethodInvocation((node) {
      final target = node.target;
      if (target is PrefixedIdentifier &&
          target.prefix.name == 'FirebaseCrashlytics' &&
          target.identifier.name == 'instance') {
        reporter.atNode(node, _code);
      }
    });

    // firebase_crashlytics import 감지 (허용 파일 제외는 위에서 처리됨)
    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null) return;
      if (uri == 'package:firebase_crashlytics/firebase_crashlytics.dart') {
        reporter.atNode(node, _code);
      }
    });
  }
}
