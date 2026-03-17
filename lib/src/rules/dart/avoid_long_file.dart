import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// # avoid_long_file
///
/// ## 규칙
/// 하나의 파일은 500줄을 초과하지 마세요.
/// 파일이 너무 길면 여러 파일로 분리하세요.
///
/// ## 원리
/// 긴 파일은 읽기 어렵고, 여러 책임이 섞이기 쉽습니다.
/// 파일이 500줄을 넘으면 대부분 단일 책임 원칙(SRP)을 위반하고 있습니다.
/// 클래스·함수·상수 등을 관련 단위로 묶어 별도 파일로 분리하면
/// 코드 탐색과 유지보수가 훨씬 수월해집니다.
///
/// ## 나쁜 예
/// ```dart
/// // 500줄이 넘는 거대한 단일 파일
/// class UserRepository { ... }
/// class UserService { ... }
/// class UserController { ... }
/// // ... 수백 줄의 코드
/// ```
///
/// ## 좋은 예
/// ```dart
/// // user_repository.dart
/// class UserRepository { ... }
///
/// // user_service.dart
/// class UserService { ... }
///
/// // user_controller.dart
/// class UserController { ... }
/// ```
class AvoidLongFile extends DartLintRule {
  AvoidLongFile() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_long_file',
    problemMessage:
        'This file exceeds 500 lines. '
        'Consider splitting it into smaller, focused files.',
    correctionMessage:
        'Extract related classes, functions, or constants '
        'into separate files to follow the Single Responsibility Principle.',
  );

  static const _maxLines = 500;

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      final lineCount = node.lineInfo.getLocation(node.end).lineNumber;
      if (lineCount > _maxLines) {
        reporter.atNode(node, _code);
      }
    });
  }
}
