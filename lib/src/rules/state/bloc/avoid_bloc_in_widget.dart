import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # avoid_bloc_in_widget
///
/// ## 규칙
/// `widget/` 디렉토리의 파일에서 BLoC/Cubit을 직접 import하지 마세요.
/// 상태 관리는 `pages/`에서만 주입하고, widget은 props로 데이터를 받으세요.
///
/// ## 원리
/// widget은 **재사용 가능한 순수 UI 컴포넌트**입니다.
/// BLoC을 직접 알게 되면:
/// - 특정 상태에 종속되어 **재사용이 불가능**해집니다.
/// - 테스트 시 BLoC을 모킹해야 하므로 **테스트가 복잡**해집니다.
/// - UI와 비즈니스 로직의 **경계가 무너집니다.**
///
/// page가 BLoC에서 상태를 꺼내 widget에 props로 전달하면
/// widget은 어디서든 재사용할 수 있습니다.
///
/// ## 감지 대상
/// `_bloc.dart`, `_cubit.dart`, `_state.dart`, `_event.dart` import
///
/// ## 나쁜 예
/// ```dart
/// // features/auth/presentation/widgets/login_form.dart
/// import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
///
/// class LoginForm extends StatelessWidget {
///   Widget build(BuildContext context) {
///     return BlocBuilder<AuthBloc, AuthState>(...); // widget이 BLoC을 직접 사용
///   }
/// }
/// ```
///
/// ## 좋은 예
/// ```dart
/// // features/auth/presentation/widgets/login_form.dart
/// class LoginForm extends StatelessWidget {
///   final String email;
///   final bool isLoading;
///   final VoidCallback onSubmit;
///   // ... props로 데이터를 받음
/// }
///
/// // features/auth/presentation/pages/login_page.dart
/// BlocBuilder<AuthBloc, AuthState>(
///   builder: (context, state) => LoginForm(
///     email: state.email,
///     isLoading: state.isLoading,
///     onSubmit: () => context.read<AuthBloc>().add(LoginSubmitted()),
///   ),
/// )
/// ```
class AvoidBlocInWidget extends FlintLintRule {
  AvoidBlocInWidget() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_bloc_in_widget',
    problemMessage:
        'Widgets should not depend on BLoC/Cubit directly. '
        'Receive data via constructor parameters instead.',
    correctionMessage:
        'Move BLoC usage to the page and pass data as props to this widget.',
  );

  static final _blocImportPattern = RegExp(
    r'_(bloc|cubit|state|event)\.dart$',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((unit) {
      final libraryUri =
          unit.declaredFragment?.source.uri.toString();
      if (libraryUri == null || !libraryUri.startsWith('package:')) return;

      final path = libraryUri.substring(libraryUri.indexOf('/') + 1);

      // widget/ 또는 widgets/ 디렉토리 내부인지 확인
      if (!path.contains('/widget/') && !path.contains('/widgets/')) return;

      for (final directive in unit.directives) {
        if (directive is! ImportDirective) continue;
        final uri = directive.uri.stringValue;
        if (uri == null) continue;

        if (_blocImportPattern.hasMatch(uri)) {
          reporter.atNode(directive, _code);
        }
      }
    });
  }
}
