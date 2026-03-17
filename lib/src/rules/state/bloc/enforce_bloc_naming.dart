import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # enforce_bloc_naming
///
/// ## 규칙
/// `Bloc`을 상속하는 클래스는 이름이 `Bloc`으로 끝나야 하고,
/// `Cubit`을 상속하는 클래스는 이름이 `Cubit`으로 끝나야 합니다.
///
/// ## 원리
/// BLoC 패턴에서는 클래스 이름만 보고도 역할을 알 수 있어야 합니다.
/// `AuthBloc`, `CartCubit`처럼 접미사가 있으면
/// 파일을 열지 않아도 "이건 상태 관리 클래스구나"가 바로 보입니다.
///
/// 팀원이 `AuthManager`, `CartHandler` 같은 이름을 쓰면
/// Bloc인지 일반 클래스인지 구분이 안 됩니다.
/// IDE에서 `Bloc`으로 검색해도 안 잡히고, 코드 리뷰에서도 놓치기 쉽습니다.
///
/// ## 나쁜 예
/// ```dart
/// class Authentication extends Bloc<AuthEvent, AuthState> {}
/// class Counter extends Cubit<int> {}
/// ```
///
/// ## 좋은 예
/// ```dart
/// class AuthBloc extends Bloc<AuthEvent, AuthState> {}
/// class CounterCubit extends Cubit<int> {}
/// ```
class EnforceBlocNaming extends FlintLintRule {
  EnforceBlocNaming() : super(code: _blocCode);

  static const _blocCode = LintCode(
    name: 'enforce_bloc_naming',
    problemMessage:
        'Classes extending Bloc should end with "Bloc". '
        'Classes extending Cubit should end with "Cubit".',
    correctionMessage: 'Rename the class to end with the appropriate suffix.',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final extendsClause = node.extendsClause;
      if (extendsClause == null) return;

      final superclassName = extendsClause.superclass.name.lexeme;
      final className = node.name.lexeme;

      if (superclassName == 'Bloc' && !className.endsWith('Bloc')) {
        reporter.atToken(node.name, _blocCode);
      }

      if (superclassName == 'Cubit' && !className.endsWith('Cubit')) {
        reporter.atToken(node.name, _blocCode);
      }
    });
  }
}
