import 'package:analyzer/dart/ast/ast.dart';

bool isInsideBuildScope(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is MethodDeclaration) {
      return isBuildLikeName(current.name.lexeme);
    }
    if (current is FunctionDeclaration) {
      return isBuildLikeName(current.name.lexeme);
    }
    if (current is FunctionExpression) {
      return false;
    }
    current = current.parent;
  }
  return false;
}

bool isBuildLikeName(String name) {
  return name == 'build' ||
      name.startsWith('build') ||
      name.startsWith('_build');
}
