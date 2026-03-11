import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// # avoid_empty_catch
///
/// ## 규칙
/// 빈 catch 블록을 사용하지 마세요.
/// 최소한 에러를 로깅하거나 명시적으로 무시하는 주석을 남기세요.
///
/// ## 원리
/// 빈 catch 블록은 에러를 **조용히 삼켜버립니다.**
/// 네트워크 요청이 실패해도, 파일 저장이 안 돼도, 파싱이 깨져도
/// 아무 일도 안 일어난 것처럼 넘어갑니다.
///
/// 디버깅할 때 가장 힘든 게 "에러가 발생했는데 어디서 발생했는지
/// 흔적이 없는" 상황입니다. 빈 catch가 그 원인인 경우가 많습니다.
///
/// ## 나쁜 예
/// ```dart
/// try {
///   await saveData();
/// } catch (e) {
///   // 아무것도 안 함 — 저장 실패를 완전히 무시
/// }
/// ```
///
/// ## 좋은 예
/// ```dart
/// try {
///   await saveData();
/// } catch (e) {
///   debugPrint('Failed to save: $e');
/// }
///
/// // 의도적으로 무시하는 경우, 예외 변수를 _로 표기
/// try {
///   await cache.clear();
/// } catch (_) {
///   // 캐시 클리어 실패는 무시해도 안전함
/// }
/// ```
class AvoidEmptyCatch extends DartLintRule {
  AvoidEmptyCatch() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_empty_catch',
    problemMessage:
        'Avoid empty catch blocks. '
        'Silently swallowing errors makes debugging nearly impossible.',
    correctionMessage:
        'Log the error, rethrow it, or use catch (_) with a comment '
        'explaining why it is safe to ignore.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCatchClause((node) {
      if (node.body.statements.isEmpty) {
        reporter.reportErrorForNode(_code, node);
      }
    });
  }
}
