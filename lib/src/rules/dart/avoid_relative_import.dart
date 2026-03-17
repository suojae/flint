import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # avoid_relative_import
///
/// ## 규칙
/// `lib/` 내부에서 상대 경로 import를 사용하지 마세요.
/// 대신 `package:` 절대 경로를 사용하세요.
///
/// ## 원리
/// 상대 경로 import(`../`, `./`)는 파일이 이동하면 깨집니다.
/// 폴더 구조가 깊어질수록 `../../..` 체인이 길어져서
/// 어디를 가리키는지 파악하기 어렵습니다.
///
/// 절대 경로(`package:my_app/...`)는 파일 위치와 무관하게
/// 항상 같은 경로로 참조하므로 리팩토링에 강하고 가독성이 좋습니다.
///
/// ## 나쁜 예
/// ```dart
/// import '../utils/helpers.dart';
/// import '../../models/user.dart';
/// ```
///
/// ## 좋은 예
/// ```dart
/// import 'package:my_app/utils/helpers.dart';
/// import 'package:my_app/models/user.dart';
/// ```
class AvoidRelativeImport extends FlintLintRule {
  AvoidRelativeImport() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_relative_import',
    problemMessage:
        'Avoid relative imports. '
        'They break when files are moved and are harder to read.',
    correctionMessage: 'Use a package: import instead.',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null) return;

      if (uri.startsWith('../') || uri.startsWith('./')) {
        reporter.atNode(node, _code);
      }
    });
  }
}
