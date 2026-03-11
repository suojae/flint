import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// # avoid_lint_ignore
///
/// ## 규칙
/// `// ignore:` 또는 `// ignore_for_file:` 주석을 사용하지 마세요.
/// 린트 경고를 무시하는 대신 근본 원인을 해결하세요.
///
/// ## 원리
/// ignore 주석은 린트 규칙을 **우회**합니다.
/// 코드 리뷰에서 놓치기 쉽고, 시간이 지나면 왜 무시했는지
/// 맥락이 사라집니다. 처음엔 "급해서 일단 무시"로 시작하지만
/// ignore가 쌓이면 린트 도구 자체가 무의미해집니다.
///
/// 정말 무시해야 하는 경우라면 코드를 수정하거나,
/// `analysis_options.yaml`에서 프로젝트 전체 설정으로 관리하세요.
///
/// ## 나쁜 예
/// ```dart
/// // ignore: avoid_print
/// print('debug');
///
/// // ignore_for_file: prefer_const_constructors
/// ```
///
/// ## 좋은 예
/// ```dart
/// // analysis_options.yaml에서 프로젝트 단위로 비활성화
/// // analyzer:
/// //   errors:
/// //     avoid_print: ignore
///
/// // 또는 코드를 수정하여 린트 경고 자체를 해결
/// debugPrint('debug');
/// ```
class AvoidLintIgnore extends DartLintRule {
  AvoidLintIgnore() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_lint_ignore',
    problemMessage:
        'Avoid using // ignore: to suppress lint warnings. '
        'Fix the underlying issue instead.',
    correctionMessage:
        'Remove the ignore comment and fix the code, or configure '
        'the rule in analysis_options.yaml.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      var token = node.beginToken;

      while (!token.isEof) {
        Token? comment = token.precedingComments;
        while (comment != null) {
          final text = comment.lexeme.trim();
          if (text.startsWith('// ignore:') ||
              text.startsWith('// ignore_for_file:') ||
              text.startsWith('//ignore:') ||
              text.startsWith('//ignore_for_file:')) {
            reporter.atOffset(
              offset: comment.offset,
              length: comment.length,
              diagnosticCode: _code,
            );
          }
          comment = comment.next;
        }
        token = token.next!;
      }
    });
  }
}
