import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';
import 'package:flint/src/utils/build_scope_helpers.dart';
import 'package:flint/src/utils/disposable_helpers.dart';

/// # avoid_controller_in_build
///
/// ## 규칙
/// `build()` 또는 `buildXxx()`/`_buildXxx()` 함수 안에서
/// controller/node 객체를 생성하지 마세요.
///
/// ## 원리
/// Flutter의 `build()`는 여러 번 호출되는 것이 정상입니다.
/// 여기서 `TextEditingController`, `ScrollController`, `FocusNode` 같은
/// 상태 보유 객체를 만들면 rebuild 때마다 새 인스턴스가 생겨:
/// - 텍스트 입력 상태와 selection이 초기화되고
/// - 스크롤 위치가 리셋되거나
/// - listener/ticker 생명주기가 꼬이거나
/// - dispose 누락으로 이어질 수 있습니다.
///
/// 이런 객체는 `State` 필드로 소유하고 `initState()`에서 생성한 뒤
/// `dispose()`에서 정리해야 합니다.
///
/// ## 감지 대상
/// - `build()` 메서드
/// - `buildXxx()`, `_buildXxx()` 패턴의 함수/메서드
/// - `TextEditingController`, `ScrollController`, `PageController`,
///   `AnimationController`, `FocusNode`, `TabController`
///
/// ## 나쁜 예
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   final controller = TextEditingController();
///   return TextField(controller: controller);
/// }
/// ```
///
/// ## 좋은 예
/// ```dart
/// class _LoginPageState extends State<LoginPage> {
///   late final TextEditingController controller;
///
///   @override
///   void initState() {
///     super.initState();
///     controller = TextEditingController();
///   }
///
///   @override
///   void dispose() {
///     controller.dispose();
///     super.dispose();
///   }
/// }
/// ```
class AvoidControllerInBuild extends FlintLintRule {
  AvoidControllerInBuild() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_controller_in_build',
    problemMessage: 'Avoid creating controller/node objects inside build(). '
        'Build can run multiple times.',
    correctionMessage:
        'Move creation out of build(): use a State field, initState(), '
        'or inject the object from outside.',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (extractOwnedDisposableTypeName(node) == null) return;
      if (!isInsideBuildScope(node)) return;

      reporter.atNode(node.constructorName, _code);
    });
  }
}
