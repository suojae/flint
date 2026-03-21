import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # avoid_bloc_in_widget
///
/// ## 규칙
/// `widget/` 디렉토리의 파일에서 BLoC/Cubit과 라우팅을 직접 사용하지 마세요.
/// 상태 관리와 네비게이션은 `pages/`에서만 처리하고,
/// widget은 props와 콜백으로 데이터를 받으세요.
///
/// ## 원리
/// widget은 **재사용 가능한 순수 UI 컴포넌트**입니다.
/// BLoC이나 라우팅을 직접 알게 되면:
/// - 특정 상태/라우트에 종속되어 **재사용이 불가능**해집니다.
/// - 테스트 시 BLoC/Navigator를 모킹해야 하므로 **테스트가 복잡**해집니다.
/// - UI와 비즈니스 로직/네비게이션의 **경계가 무너집니다.**
///
/// page가 BLoC에서 상태를 꺼내고, 네비게이션 콜백을 주입하면
/// widget은 어디서든 재사용할 수 있습니다.
///
/// ## 감지 대상
/// - BLoC: `_bloc.dart`, `_cubit.dart`, `_state.dart`, `_event.dart` import
/// - 라우팅: `go_router`, `auto_route`, `routemaster` 등 라우팅 패키지 import
///
/// ## 나쁜 예
/// ```dart
/// // features/auth/presentation/widgets/login_form.dart
/// import 'package:go_router/go_router.dart';
/// import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
///
/// class LoginForm extends StatelessWidget {
///   Widget build(BuildContext context) {
///     return ElevatedButton(
///       onPressed: () => context.go('/home'), // widget이 라우팅을 직접 수행
///     );
///   }
/// }
/// ```
///
/// ## 좋은 예
/// ```dart
/// // features/auth/presentation/widgets/login_form.dart
/// class LoginForm extends StatelessWidget {
///   final VoidCallback onLoginSuccess; // 콜백으로 받음
/// }
///
/// // features/auth/presentation/pages/login_page.dart
/// LoginForm(
///   onLoginSuccess: () => context.go('/home'), // page에서 네비게이션
/// )
/// ```
class AvoidBlocInWidget extends FlintLintRule {
  AvoidBlocInWidget() : super(code: _blocCode);

  static const _blocCode = LintCode(
    name: 'avoid_bloc_in_widget',
    problemMessage:
        'Widgets should not depend on BLoC/Cubit directly. '
        'Receive data via constructor parameters instead.',
    correctionMessage:
        'Move BLoC usage to the page and pass data as props to this widget.',
  );

  static const _routeCode = LintCode(
    name: 'avoid_bloc_in_widget',
    problemMessage:
        'Widgets should not handle routing directly. '
        'Use a VoidCallback or Function prop instead.',
    correctionMessage:
        'Move navigation logic to the page and pass a callback to this widget.',
  );

  static final _blocImportPattern = RegExp(
    r'_(bloc|cubit|state|event)\.dart$',
  );

  static final _routeImportPattern = RegExp(
    r'^package:(go_router|auto_route|routemaster|beamer)/',
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
          reporter.atNode(directive, _blocCode);
        } else if (_routeImportPattern.hasMatch(uri)) {
          reporter.atNode(directive, _routeCode);
        }
      }
    });
  }
}
