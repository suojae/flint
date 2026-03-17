import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// # prefer_talker_logger
///
/// ## 규칙
/// `print()` 또는 `debugPrint()`를 사용하지 마세요.
/// 구조화된 로깅을 위해 Talker를 사용하세요.
///
/// ## 원리
/// `print()`와 `debugPrint()`는 로그 레벨 구분이 없고,
/// 프로덕션에서 끄기 어렵습니다. Talker를 사용하면
/// 로그 레벨(info, warning, error)을 구분하고,
/// 옵저버를 통해 로그를 수집·필터링할 수 있습니다.
///
/// ## 나쁜 예
/// ```dart
/// print('user logged in');
/// debugPrint('response: $data');
/// ```
///
/// ## 좋은 예
/// ```dart
/// talker.info('user logged in');
/// talker.debug('response: $data');
/// talker.error('failed to fetch', error, stackTrace);
/// ```
class PreferTalkerLogger extends DartLintRule {
  PreferTalkerLogger() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_talker_logger',
    problemMessage:
        'Avoid using print() or debugPrint(). '
        'Use Talker for structured logging instead.',
    correctionMessage:
        'Replace with Talker instance methods '
        'such as talker.info(), talker.error(), talker.debug(), etc.',
  );

  static const _disallowedFunctions = {'print', 'debugPrint'};

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.target == null &&
          _disallowedFunctions.contains(node.methodName.name)) {
        reporter.atNode(node, _code);
      }
    });
  }
}
