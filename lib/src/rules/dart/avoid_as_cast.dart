import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # avoid_as_cast
///
/// ## 규칙
/// `as` 타입 캐스팅을 사용하지 마세요.
/// 런타임에 `TypeError`가 발생할 수 있습니다.
///
/// ## 원리
/// `as`는 "이 값은 반드시 이 타입이다"라고 런타임에 강제합니다.
/// 만약 실제 타입이 다르면 즉시 `TypeError`로 크래시합니다.
///
/// `is` 체크나 패턴 매칭을 사용하면 컴파일러가 자동으로
/// 타입을 좁혀주므로(smart cast) 안전하게 사용할 수 있습니다.
///
/// ## 예외
/// JSON/API 파싱에서 불가피한 캐스팅은 허용합니다:
/// - 프리미티브 타입: `as String`, `as int`, `as double`, `as bool`, `as num`
///   (nullable 포함)
/// - JSON 컬렉션: `as Map<String, dynamic>`, `as List<dynamic>`
///
/// ## 나쁜 예
/// ```dart
/// final user = object as User;
/// final widget = element as StatefulWidget;
/// ```
///
/// ## 좋은 예
/// ```dart
/// // is 체크 또는 패턴 매칭
/// if (object is User) {
///   print(object.name); // smart cast
/// }
///
/// // JSON 파싱은 OK
/// final data = response.data as Map<String, dynamic>;
/// final name = json['name'] as String?;
/// ```
class AvoidAsCast extends FlintLintRule {
  AvoidAsCast() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_as_cast',
    problemMessage:
        'Avoid using "as" for type casting. '
        'It can throw TypeError at runtime.',
    correctionMessage:
        'Use "is" type check or pattern matching for safe type narrowing.',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addAsExpression((node) {
      if (_isJsonSafeCast(node.type)) return;

      reporter.atNode(node, _code);
    });
  }

  static const _primitiveTypes = {
    'String',
    'int',
    'double',
    'bool',
    'num',
  };

  /// JSON 파싱에서 불가피한 캐스팅인지 확인합니다.
  bool _isJsonSafeCast(TypeAnnotation type) {
    if (type is! NamedType) return false;

    final name = type.name.lexeme;

    // String, int, double, bool, num (nullable 포함)
    if (_primitiveTypes.contains(name)) return true;

    // Map<String, dynamic>
    if (name == 'Map') {
      final args = type.typeArguments?.arguments;
      if (args != null &&
          args.length == 2 &&
          args[0] is NamedType &&
          (args[0] as NamedType).name.lexeme == 'String' &&
          args[1] is NamedType &&
          (args[1] as NamedType).name.lexeme == 'dynamic') {
        return true;
      }
    }

    // List<dynamic>, List<Map<String, dynamic>>
    if (name == 'List') {
      final args = type.typeArguments?.arguments;
      if (args != null && args.length == 1) {
        final arg = args[0];
        if (arg is NamedType) {
          if (arg.name.lexeme == 'dynamic') return true;
          if (arg.name.lexeme == 'Map') return _isJsonSafeCast(arg);
        }
      }
    }

    return false;
  }
}
