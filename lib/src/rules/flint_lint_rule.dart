import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// 모든 Flint 린트 규칙의 베이스 클래스.
///
/// 자동 생성 파일(`.g.dart`, `.freezed.dart`, `.gr.dart`, `.gen.dart`,
/// `.mocks.dart`)을 자동으로 제외합니다.
///
/// 새 규칙을 만들 때 `DartLintRule` 대신 이 클래스를 상속하고,
/// `run` 대신 [analyze]를 구현하세요.
abstract class FlintLintRule extends DartLintRule {
  FlintLintRule({required super.code});

  static final _generatedPattern =
      RegExp(r'\.(g|freezed|gr|gen|mocks)\.dart$');

  /// 린트 분석 로직을 구현합니다.
  /// 자동 생성 파일은 이미 필터링된 상태로 호출됩니다.
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (_generatedPattern.hasMatch(resolver.path)) return;
    analyze(resolver, reporter, context);
  }
}
