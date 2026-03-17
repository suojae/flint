import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # avoid_untyped_collection
///
/// ## 규칙
/// `List`, `Map`, `Set`을 선언할 때 타입 파라미터를 명시하세요.
/// 타입 파라미터가 없으면 `dynamic`으로 추론되어 타입 안전성을 잃습니다.
///
/// ## 원리
/// `List items = []`는 실제로 `List<dynamic>`입니다.
/// 어떤 타입이든 넣을 수 있고, 꺼낼 때 타입 검사가 없어서
/// 런타임에야 `TypeError`를 발견합니다.
///
/// 타입 파라미터를 명시하면 컴파일 타임에 잘못된 타입 삽입을
/// 잡아낼 수 있고, IDE 자동완성도 정확하게 동작합니다.
///
/// ## 나쁜 예
/// ```dart
/// List items = [];
/// Map config = {};
/// Set visited = {};
/// ```
///
/// ## 좋은 예
/// ```dart
/// List<String> items = [];
/// Map<String, dynamic> config = {};
/// Set<int> visited = {};
/// ```
class AvoidUntypedCollection extends FlintLintRule {
  AvoidUntypedCollection() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_untyped_collection',
    problemMessage:
        'Collection declared without type parameters defaults to dynamic. '
        'Specify explicit type parameters.',
    correctionMessage:
        'Add type parameters, e.g., List<String>, Map<String, int>, Set<int>.',
  );

  static const _collectionTypes = {'List', 'Map', 'Set', 'Iterable'};

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addVariableDeclaration((node) {
      final parent = node.parent;
      if (parent is! VariableDeclarationList) return;

      final type = parent.type;
      if (type is! NamedType) return;

      if (_collectionTypes.contains(type.name.lexeme) &&
          type.typeArguments == null) {
        reporter.atNode(type, _code);
      }
    });
  }
}
