import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';
import 'package:flint/src/utils/widget_helpers.dart';

/// # prefer_widget_composition
///
/// ## 규칙
/// `build()` 또는 `_buildXxx()` 메서드 내에서 위젯 생성자 중첩이
/// 4단계를 초과하면 경고합니다.
///
/// ## 원리
/// 깊게 중첩된 위젯 트리는 들여쓰기가 과도해지고 가독성이 떨어집니다.
/// 별도의 StatelessWidget 클래스로 추출(컴포지션)하면
/// 코드가 읽기 쉽고 재사용하기 좋아집니다.
///
/// ## 나쁜 예
/// ```dart
/// Widget build(BuildContext context) {
///   return Scaffold(           // depth 1
///     body: Column(            // depth 2
///       children: [
///         Container(           // depth 3
///           child: Padding(    // depth 4
///             child: Text(''), // depth 5 ← 위반
///           ),
///         ),
///       ],
///     ),
///   );
/// }
/// ```
///
/// ## 좋은 예
/// ```dart
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: Column(
///       children: [
///         _ContentSection(),
///       ],
///     ),
///   );
/// }
/// ```
class PreferWidgetComposition extends FlintLintRule {
  PreferWidgetComposition() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_widget_composition',
    problemMessage:
        'Widget nesting exceeds $_maxDepth levels in this build method. '
        'Extract deeper widgets into separate widget classes.',
    correctionMessage:
        'Create a new StatelessWidget or StatefulWidget class '
        'for the deeply nested portion.',
  );

  static const _maxDepth = 4;

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (getWidgetName(node) == null) return;

      final method = _enclosingBuildMethod(node);
      if (method == null) return;

      final depth = _widgetDepth(node, method);
      if (depth > _maxDepth) {
        reporter.atNode(node.constructorName, _code);
      }
    });
  }

  /// Returns the enclosing `build()` or `_buildXxx()` method, or null.
  static MethodDeclaration? _enclosingBuildMethod(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is MethodDeclaration) {
        final name = current.name.lexeme;
        if (name == 'build' || _buildMethodPattern.hasMatch(name)) {
          return current;
        }
        return null;
      }
      current = current.parent;
    }
    return null;
  }

  static final _buildMethodPattern = RegExp(r'^_build[A-Z]');

  /// Counts InstanceCreationExpression ancestors within the same build method.
  static int _widgetDepth(InstanceCreationExpression node, MethodDeclaration method) {
    var depth = 1;
    AstNode? current = node.parent;
    while (current != null && current != method) {
      if (current is InstanceCreationExpression && getWidgetName(current) != null) {
        depth++;
      }
      current = current.parent;
    }
    return depth;
  }
}
