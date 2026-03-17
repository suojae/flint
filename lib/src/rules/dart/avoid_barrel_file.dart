import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # avoid_barrel_file
///
/// ## 규칙
/// `index.dart` 배럴 파일을 만들지 마세요.
/// 필요한 파일을 직접 import하세요.
///
/// ## 원리
/// JavaScript/TypeScript에서 넘어온 배럴 패턴(`index.dart`)은
/// Dart에서 **실익 없이 문제만 일으킵니다:**
///
/// - **순환 참조:** 배럴 파일이 서로를 re-export하면
///   `circular dependency` 에러가 발생합니다.
/// - **빌드 성능 저하:** 하나의 export만 필요해도 배럴 파일이
///   모든 파일을 끌어들여 불필요한 재빌드가 발생합니다.
/// - **코드 추적 어려움:** `Go to Definition`이 배럴 파일에서 멈추고,
///   실제 정의로 바로 이동하지 못합니다.
/// - **트리셰이킹 무력화:** 사용하지 않는 코드까지 함께 번들됩니다.
///
/// Dart는 `package:` import로 파일을 직접 참조하는 것이 자연스럽습니다.
///
/// ## 나쁜 예
/// ```dart
/// // lib/src/models/index.dart
/// export 'user.dart';
/// export 'post.dart';
/// export 'comment.dart';
///
/// // 사용처
/// import 'package:app/src/models/index.dart';
/// ```
///
/// ## 좋은 예
/// ```dart
/// // 필요한 파일을 직접 import
/// import 'package:app/src/models/user.dart';
/// import 'package:app/src/models/post.dart';
/// ```
class AvoidBarrelFile extends FlintLintRule {
  AvoidBarrelFile() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_barrel_file',
    problemMessage:
        'Barrel files (index.dart) cause circular dependencies and slow builds. '
        'Import each file directly instead.',
    correctionMessage:
        'Delete this index.dart and replace usages with direct imports.',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (!resolver.path.endsWith('/index.dart')) return;

    context.registry.addCompilationUnit((node) {
      reporter.atNode(node, _code);
    });
  }
}
