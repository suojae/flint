import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # enforce_talker_error_stacktrace
///
/// ## 규칙
/// `talker.error()` 호출 시 error와 stackTrace 인자를 모두 전달하세요.
///
/// ## 원리
/// `talker.error('message')`처럼 메시지만 전달하면:
/// - Crashlytics에 스택 트레이스가 기록되지 않아 디버깅이 불가능합니다.
/// - 에러 객체가 없으면 Crashlytics에서 에러 그룹핑이 제대로 되지 않습니다.
///
/// catch 블록에서는 항상 잡은 error와 stackTrace를 함께 전달해야
/// 프로덕션에서 문제 원인을 추적할 수 있습니다.
///
/// ## 나쁜 예
/// ```dart
/// try {
///   await fetchData();
/// } catch (e, st) {
///   talker.error('fetch failed');        // error, stackTrace 누락
///   talker.error('fetch failed', e);     // stackTrace 누락
/// }
/// ```
///
/// ## 좋은 예
/// ```dart
/// try {
///   await fetchData();
/// } catch (e, st) {
///   talker.error('fetch failed', e, st); // 모두 전달
/// }
///
/// // handle()도 OK
/// try {
///   await fetchData();
/// } catch (e, st) {
///   talker.handle(e, st, 'fetch failed');
/// }
/// ```
class EnforceTalkerErrorStacktrace extends FlintLintRule {
  EnforceTalkerErrorStacktrace() : super(code: _code);

  static const _code = LintCode(
    name: 'enforce_talker_error_stacktrace',
    problemMessage:
        'talker.error() must include both error and stackTrace arguments. '
        'Without them, Crashlytics cannot trace the error origin.',
    correctionMessage:
        'Pass all three arguments: talker.error(message, error, stackTrace). '
        'Or use talker.handle(error, stackTrace, message).',
  );

  static final _talkerPattern = RegExp(r'[Tt]alker');

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      // talker.error() 호출만 대상
      if (node.methodName.name != 'error') return;

      final target = node.target;
      if (target == null) return;

      // receiver가 talker 패턴인지 확인
      final String targetName;
      if (target is SimpleIdentifier) {
        targetName = target.name;
      } else if (target is PrefixedIdentifier) {
        targetName = target.identifier.name;
      } else {
        return;
      }

      if (!_talkerPattern.hasMatch(targetName)) return;

      // talker.error()는 positional args: (message, [error, stackTrace])
      // 3개 미만이면 경고
      final args = node.argumentList.arguments;
      final positionalCount =
          args.where((a) => a is! NamedExpression).length;

      if (positionalCount < 3) {
        reporter.atNode(node, _code);
      }
    });
  }
}
