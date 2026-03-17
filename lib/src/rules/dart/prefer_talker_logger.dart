import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # prefer_talker_logger
///
/// ## 규칙
/// `print()`, `debugPrint()`, `log()`, `Logger` 등을 사용하지 마세요.
/// 모든 로깅은 Talker로 통일하세요.
///
/// ## 원리
/// 로깅 라이브러리가 섞이면:
/// - 로그 포맷이 **제각각**이라 파싱이 어렵습니다.
/// - 프로덕션에서 **일괄 제어**(끄기, 필터링, 수집)가 불가능합니다.
/// - `print()`는 릴리즈 빌드에서도 콘솔에 출력되어 **보안 위험**이 있습니다.
///
/// Talker를 사용하면 로그 레벨 구분, 옵저버 패턴, 일괄 제어가 가능합니다.
///
/// ## 나쁜 예
/// ```dart
/// print('user logged in');
/// debugPrint('response: $data');
/// log('request sent', name: 'API');
/// Logger().d('debug message');
/// ```
///
/// ## 좋은 예
/// ```dart
/// talker.info('user logged in');
/// talker.debug('response: $data');
/// talker.error('failed to fetch', error, stackTrace);
/// ```
class PreferTalkerLogger extends FlintLintRule {
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

  static const _disallowedFunctions = {'print', 'debugPrint', 'log'};

  /// dart:developer, package:logger 등 비-Talker 로깅 패키지
  static final _disallowedImportPattern = RegExp(
    r"^(dart:developer|package:logger/|package:logging/)",
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    // print(), debugPrint(), log() 함수 호출 감지
    context.registry.addMethodInvocation((node) {
      if (node.target == null &&
          _disallowedFunctions.contains(node.methodName.name)) {
        reporter.atNode(node, _code);
      }
    });

    // 다른 로깅 패키지 import 감지
    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null) return;
      if (_disallowedImportPattern.hasMatch(uri)) {
        reporter.atNode(node, _code);
      }
    });
  }
}
