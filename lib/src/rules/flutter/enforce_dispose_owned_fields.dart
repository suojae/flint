import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';
import 'package:flint/src/utils/disposable_helpers.dart';

/// # enforce_dispose_owned_fields
///
/// ## 규칙
/// `State`가 직접 생성한 controller/node 필드는 반드시 `dispose()`에서
/// 정리하세요.
///
/// ## 원리
/// `TextEditingController`, `ScrollController`, `AnimationController`,
/// `FocusNode` 같은 객체는 단순 데이터가 아니라 listener, ticker,
/// 내부 상태를 함께 들고 있습니다.
///
/// 이 객체들을 `State` 내부에서 직접 만들었다면, 화면이 사라질 때
/// `dispose()`에서 함께 정리해야 합니다. 누락되면 listener가 남거나,
/// ticker 관련 에러가 생기거나, 화면 생명주기와 맞지 않는 동작이
/// 뒤늦게 실행될 수 있습니다.
///
/// ## 감지 대상
/// - `State`, `ConsumerState`, `HookConsumerState` 클래스
/// - 클래스 내부에서 직접 생성한 인스턴스 필드
///   - `final c = TextEditingController();`
///   - `controller = ScrollController();` in `initState()`
/// - `dispose()` 안에 `field.dispose()` 또는 `field?.dispose()` 호출이 없는 경우
///
/// ## 나쁜 예
/// ```dart
/// class _LoginPageState extends State<LoginPage> {
///   final controller = TextEditingController();
///
///   @override
///   Widget build(BuildContext context) {
///     return TextField(controller: controller);
///   }
/// }
/// ```
///
/// ## 좋은 예
/// ```dart
/// class _LoginPageState extends State<LoginPage> {
///   final controller = TextEditingController();
///
///   @override
///   void dispose() {
///     controller.dispose();
///     super.dispose();
///   }
/// }
/// ```
class EnforceDisposeOwnedFields extends FlintLintRule {
  EnforceDisposeOwnedFields() : super(code: _code);

  static const _code = LintCode(
    name: 'enforce_dispose_owned_fields',
    problemMessage:
        'Dispose controller/node fields owned by this State in dispose().',
    correctionMessage: 'Call field.dispose() inside dispose(), '
        'or move ownership outside this State.',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      if (!_isStateClass(node)) return;

      final ownedFields = _collectOwnedFields(node);
      if (ownedFields.isEmpty) return;

      final disposedFields = _collectDisposedFields(node);

      for (final entry in ownedFields.entries) {
        if (!disposedFields.contains(entry.key)) {
          reporter.atToken(entry.value.name, _code);
        }
      }
    });
  }

  bool _isStateClass(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause == null) return false;

    final superclassName = extendsClause.superclass.name.lexeme;
    return _stateBaseClassNames.contains(superclassName);
  }

  Map<String, VariableDeclaration> _collectOwnedFields(ClassDeclaration node) {
    final ownedFields = <String, VariableDeclaration>{};
    final initStateCandidates = <String, VariableDeclaration>{};

    for (final member in node.members) {
      if (member is! FieldDeclaration || member.isStatic) continue;

      final declaredTypeName = extractNamedTypeName(member.fields.type);

      for (final variable in member.fields.variables) {
        final variableName = variable.name.lexeme;
        final ownedTypeName =
            extractOwnedDisposableTypeName(variable.initializer);

        if (ownedTypeName != null) {
          ownedFields[variableName] = variable;
          continue;
        }

        if (variable.initializer == null &&
            declaredTypeName != null &&
            ownedDisposableTypeNames.contains(declaredTypeName)) {
          initStateCandidates[variableName] = variable;
        }
      }
    }

    if (initStateCandidates.isEmpty) return ownedFields;

    final initStateMethod = _findMethod(node, 'initState');
    final initStateBody = initStateMethod?.body;
    if (initStateBody is! BlockFunctionBody) return ownedFields;

    final finder =
        _OwnedFieldAssignmentFinder(initStateCandidates.keys.toSet());
    initStateBody.block.accept(finder);

    for (final fieldName in finder.assignedOwnedFields) {
      final field = initStateCandidates[fieldName];
      if (field != null) {
        ownedFields[fieldName] = field;
      }
    }

    return ownedFields;
  }

  Set<String> _collectDisposedFields(ClassDeclaration node) {
    final disposeMethod = _findMethod(node, 'dispose');
    final disposeBody = disposeMethod?.body;
    if (disposeBody is! BlockFunctionBody) return {};

    final finder = _DisposeCallFinder();
    disposeBody.block.accept(finder);
    return finder.disposedFieldNames;
  }

  MethodDeclaration? _findMethod(ClassDeclaration node, String methodName) {
    for (final member in node.members) {
      if (member is MethodDeclaration && member.name.lexeme == methodName) {
        return member;
      }
    }
    return null;
  }
}

class _OwnedFieldAssignmentFinder extends RecursiveAstVisitor<void> {
  _OwnedFieldAssignmentFinder(this.candidateFieldNames);

  final Set<String> candidateFieldNames;
  final Set<String> assignedOwnedFields = {};

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.type != TokenType.EQ) {
      super.visitAssignmentExpression(node);
      return;
    }

    final fieldName = _extractFieldName(node.leftHandSide);
    if (fieldName == null || !candidateFieldNames.contains(fieldName)) {
      super.visitAssignmentExpression(node);
      return;
    }

    if (extractOwnedDisposableTypeName(node.rightHandSide) != null) {
      assignedOwnedFields.add(fieldName);
    }

    super.visitAssignmentExpression(node);
  }
}

class _DisposeCallFinder extends RecursiveAstVisitor<void> {
  final Set<String> disposedFieldNames = {};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'dispose') {
      final fieldName = _extractFieldName(node.target);
      if (fieldName != null) {
        disposedFieldNames.add(fieldName);
      }
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    final fieldName = _extractFieldName(node.target);
    if (fieldName != null) {
      for (final section in node.cascadeSections) {
        if (section is MethodInvocation &&
            section.methodName.name == 'dispose') {
          disposedFieldNames.add(fieldName);
        }
      }
    }

    super.visitCascadeExpression(node);
  }
}

const _stateBaseClassNames = {
  'State',
  'ConsumerState',
  'HookConsumerState',
};

String? _extractFieldName(Expression? expression) {
  if (expression == null) return null;

  if (expression is ParenthesizedExpression) {
    return _extractFieldName(expression.expression);
  }

  if (expression is SimpleIdentifier) {
    return expression.name;
  }

  if (expression is PropertyAccess && expression.target is ThisExpression) {
    return expression.propertyName.name;
  }

  return null;
}
