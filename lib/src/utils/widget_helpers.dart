import 'package:analyzer/dart/ast/ast.dart';

/// Extracts the widget type name from an [InstanceCreationExpression].
///
/// Returns the class name (e.g., "Opacity", "Image", "ListView").
String? getWidgetName(InstanceCreationExpression node) {
  return node.constructorName.type.name2.lexeme;
}

/// Extracts a named argument from an [InstanceCreationExpression].
///
/// Returns the [NamedExpression] for the given [name], or null if not found.
NamedExpression? getNamedArgument(
  InstanceCreationExpression node,
  String name,
) {
  for (final arg in node.argumentList.arguments) {
    if (arg is NamedExpression && arg.name.label.name == name) {
      return arg;
    }
  }
  return null;
}

/// Checks if an expression is an [InstanceCreationExpression] with
/// one of the given [widgetNames].
bool isWidgetOfType(Expression? expression, Set<String> widgetNames) {
  if (expression is InstanceCreationExpression) {
    final name = getWidgetName(expression);
    return name != null && widgetNames.contains(name);
  }
  return false;
}
