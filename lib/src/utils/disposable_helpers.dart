import 'package:analyzer/dart/ast/ast.dart';

/// Types that are typically owned by a widget/State and must be disposed.
const ownedDisposableTypeNames = {
  'AnimationController',
  'FocusNode',
  'PageController',
  'ScrollController',
  'TabController',
  'TextEditingController',
};

String? extractNamedTypeName(TypeAnnotation? type) {
  if (type is NamedType) return type.name.lexeme;
  return null;
}

String? extractOwnedDisposableTypeName(Expression? expression) {
  if (expression == null) return null;

  if (expression is ParenthesizedExpression) {
    return extractOwnedDisposableTypeName(expression.expression);
  }

  if (expression is CascadeExpression) {
    return extractOwnedDisposableTypeName(expression.target);
  }

  if (expression is InstanceCreationExpression) {
    final typeName = expression.constructorName.type.name.lexeme;
    if (ownedDisposableTypeNames.contains(typeName)) {
      return typeName;
    }
  }

  return null;
}
