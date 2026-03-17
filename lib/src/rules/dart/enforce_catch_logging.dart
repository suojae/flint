import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # enforce_catch_logging
///
/// ## 규칙
/// catch 블록에서 반드시 Talker를 사용하여 에러를 로깅하세요.
///
/// ## 원리
/// catch 블록에서 에러를 잡아놓고 로깅하지 않으면
/// 프로덕션에서 문제의 원인을 추적할 수 없습니다.
/// Talker로 통일된 로깅을 하면 에러 추적, 필터링, 수집이 가능합니다.
///
/// ## 예외
/// - `catch (_)` — 의도적으로 무시하는 경우 (변수명이 `_`)
/// - `rethrow` 또는 `throw` — 에러를 상위로 전파하는 경우
///
/// ## 나쁜 예
/// ```dart
/// try {
///   await fetchData();
/// } catch (e) {
///   print(e);            // print 대신 talker 사용
/// }
///
/// try {
///   await fetchData();
/// } catch (e, st) {
///   setState(() {});      // 로깅 없이 상태만 변경
/// }
/// ```
///
/// ## 좋은 예
/// ```dart
/// try {
///   await fetchData();
/// } catch (e, st) {
///   talker.error('Failed to fetch data', e, st);
/// }
///
/// try {
///   await fetchData();
/// } catch (e, st) {
///   talker.handle(e, st, 'fetch failed');
///   setState(() {});
/// }
///
/// // 의도적으로 무시
/// try {
///   await cache.clear();
/// } catch (_) {
///   // 캐시 클리어 실패는 무시해도 안전함
/// }
///
/// // 상위로 전파
/// try {
///   await saveData();
/// } catch (e, st) {
///   talker.error('save failed', e, st);
///   rethrow;
/// }
/// ```
class EnforceCatchLogging extends FlintLintRule {
  EnforceCatchLogging() : super(code: _code);

  static const _code = LintCode(
    name: 'enforce_catch_logging',
    problemMessage:
        'Catch block must log the error using Talker. '
        'Unlogged errors are invisible in production.',
    correctionMessage:
        'Add talker.error(), talker.handle(), or another '
        'Talker logging call. Use catch (_) to intentionally ignore.',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCatchClause((node) {
      // catch (_) — 의도적으로 무시하는 패턴은 허용
      final exceptionParam = node.exceptionParameter;
      if (exceptionParam == null || exceptionParam.name.lexeme == '_') return;

      final finder = _CatchBodyAnalyzer();
      node.body.accept(finder);

      // rethrow / throw 가 있으면 에러를 전파하는 것이므로 허용
      if (finder.hasRethrowOrThrow) return;

      // Talker 로깅 호출이 없으면 경고
      if (!finder.hasTalkerCall) {
        reporter.atNode(node, _code);
      }
    });
  }
}

class _CatchBodyAnalyzer extends RecursiveAstVisitor<void> {
  bool hasTalkerCall = false;
  bool hasRethrowOrThrow = false;

  static final _talkerPattern = RegExp(r'[Tt]alker');

  @override
  void visitRethrowExpression(RethrowExpression node) {
    hasRethrowOrThrow = true;
    super.visitRethrowExpression(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    hasRethrowOrThrow = true;
    super.visitThrowExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    if (target is SimpleIdentifier && _talkerPattern.hasMatch(target.name)) {
      hasTalkerCall = true;
    }
    if (target is PrefixedIdentifier &&
        _talkerPattern.hasMatch(target.identifier.name)) {
      hasTalkerCall = true;
    }
    super.visitMethodInvocation(node);
  }
}
