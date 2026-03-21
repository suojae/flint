import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # enforce_widget_suffix
///
/// ## 규칙
/// `widgets/` 디렉토리 안의 위젯 클래스는 반드시 `Widget` 접미사를 붙이세요.
///
/// ## 원리
/// `widgets/` 폴더는 재사용 가능한 UI 컴포넌트를 모아두는 곳입니다.
/// `Widget` 접미사를 강제하면:
/// - **역할이 명확해집니다** — 클래스 이름만으로 위젯임을 알 수 있습니다.
/// - **검색이 쉬워집니다** — `Widget`으로 필터링하면 모든 컴포넌트를 찾을 수 있습니다.
/// - **pages와 구분됩니다** — Page/Screen은 페이지, Widget은 컴포넌트라는 컨벤션이 생깁니다.
///
/// ## 나쁜 예
/// ```dart
/// // widgets/login_form.dart
/// class LoginForm extends StatelessWidget { ... }
/// class ProfileCard extends StatefulWidget { ... }
/// ```
///
/// ## 좋은 예
/// ```dart
/// // widgets/login_form_widget.dart
/// class LoginFormWidget extends StatelessWidget { ... }
/// class ProfileCardWidget extends StatefulWidget { ... }
/// ```
class EnforceWidgetSuffix extends FlintLintRule {
  EnforceWidgetSuffix() : super(code: _code);

  static const _code = LintCode(
    name: 'enforce_widget_suffix',
    problemMessage:
        'Widget classes in widgets/ directory must end with "Widget".',
    correctionMessage:
        'Rename this class to end with "Widget" (e.g., LoginFormWidget).',
  );

  static const _widgetBaseClasses = {
    'StatelessWidget',
    'StatefulWidget',
    'HookWidget',
    'HookConsumerWidget',
    'ConsumerWidget',
  };

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
      if (!path.contains('/widget/') && !path.contains('/widgets/')) return;

      for (final declaration in unit.declarations) {
        if (declaration is! ClassDeclaration) continue;

        final superclass = declaration.extendsClause?.superclass.name.lexeme;
        if (superclass == null || !_widgetBaseClasses.contains(superclass)) {
          continue;
        }

        final className = declaration.name.lexeme;
        if (!className.endsWith('Widget')) {
          reporter.atToken(declaration.name, _code);
        }
      }
    });
  }
}
