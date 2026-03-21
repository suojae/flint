import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # avoid_widget_helper_method
///
/// ## 규칙
/// `_buildXxx()` 형태의 private widget helper 메서드를 만들지 마세요.
/// 별도 위젯 클래스로 추출해서 컴포지션하세요.
///
/// ## 원리
/// private helper 메서드는 처음엔 편해 보여도
/// - 해당 위젯 클래스에 구현이 계속 몰리게 되고
/// - 재사용 단위가 메서드에 묶여 테스트와 탐색이 어려워지며
/// - props 중심의 명확한 UI 경계를 흐리게 만듭니다.
///
/// 반면 별도 위젯 클래스로 추출하면 이름 있는 UI 조각이 생기고,
/// 생성자 파라미터를 통해 의존성이 드러나며, 재사용성과 가독성이 좋아집니다.
///
/// ## 검사 범위
/// - 이름이 `_buildXxx()` 패턴인 private 클래스 메서드
/// - 같은 클래스에 `build()` 메서드가 있는 경우만 검사
/// - 반환 타입이 `Widget` 또는 `Widget`의 하위 타입인 경우만 검사
///
/// ## 나쁜 예
/// ```dart
/// class ProfilePage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         _buildHeader(),
///       ],
///     );
///   }
///
///   Widget _buildHeader() {
///     return const Text('Profile');
///   }
/// }
/// ```
///
/// ## 좋은 예
/// ```dart
/// class ProfilePage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return const Column(
///       children: [
///         _ProfileHeader(),
///       ],
///     );
///   }
/// }
///
/// class _ProfileHeader extends StatelessWidget {
///   const _ProfileHeader();
///
///   @override
///   Widget build(BuildContext context) {
///     return const Text('Profile');
///   }
/// }
/// ```
class AvoidWidgetHelperMethod extends FlintLintRule {
  AvoidWidgetHelperMethod() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_widget_helper_method',
    problemMessage: 'Avoid private widget helper methods like _buildXxx(). '
        'Extract a dedicated widget class instead.',
    correctionMessage:
        'Replace this helper method with a StatelessWidget/StatefulWidget '
        'and compose it from build().',
  );

  static final _helperMethodPattern = RegExp(r'^_build[A-Z]');
  static final _widgetFrameworkUri = Uri.parse(
    'package:flutter/src/widgets/framework.dart',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      if (node.isGetter || node.isSetter) return;
      if (node.body is EmptyFunctionBody) return;
      if (!_helperMethodPattern.hasMatch(node.name.lexeme)) return;
      if (!_isInsideWidgetClass(node)) return;
      if (!_returnsWidget(node)) return;

      reporter.atToken(node.name, _code);
    });
  }

  bool _isInsideWidgetClass(MethodDeclaration node) {
    final parent = node.parent;
    if (parent is! ClassDeclaration) return false;

    for (final member in parent.members) {
      if (member is MethodDeclaration && member.name.lexeme == 'build') {
        return true;
      }
    }

    return false;
  }

  bool _returnsWidget(MethodDeclaration node) {
    return _isWidgetType(node.returnType?.type);
  }

  bool _isWidgetType(DartType? type) {
    if (type is! InterfaceType) return false;

    if (_isFlutterWidget(type)) return true;

    return type.element.allSupertypes.any(_isFlutterWidget);
  }

  bool _isFlutterWidget(InterfaceType type) {
    final element = type.element;
    return element.name == 'Widget' &&
        element.library.uri == _widgetFrameworkUri;
  }
}
