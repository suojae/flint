import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # avoid_hardcoded_asset_path
///
/// ## 규칙
/// 에셋 경로 문자열(`'assets/...'`)을 위젯이나 함수 호출에 직접 넣지 마세요.
/// 대신 별도 상수 클래스에서 관리하세요.
///
/// ## 원리
/// 에셋 경로를 하드코딩하면:
/// - **경로 변경 시** 사용처를 모두 찾아 수정해야 합니다 (Human error 발생).
/// - **오타를 런타임에서야** 발견합니다 (컴파일 타임 보장 없음).
/// - **자동완성이 안 되어** 어떤 에셋이 있는지 파악이 어렵습니다.
///
/// 상수 클래스를 사용하면 IDE 자동완성, 컴파일 타임 검증,
/// 일괄 변경이 가능합니다.
///
/// ## 검사 범위
/// - `'assets/'`로 시작하는 문자열 리터럴
/// - `const` 또는 `static const` 필드 선언은 제외 (상수 클래스 정의 허용)
/// - 자동 생성 파일은 FlintLintRule에 의해 자동 제외
///
/// ## 나쁜 예
/// ```dart
/// Image.asset('assets/images/logo.png')
/// SvgPicture.asset('assets/icons/arrow.svg')
/// Lottie.asset('assets/animations/loading.json')
/// ```
///
/// ## 좋은 예
/// ```dart
/// // assets.dart
/// abstract class Assets {
///   static const logo = 'assets/images/logo.png';
///   static const arrowIcon = 'assets/icons/arrow.svg';
/// }
///
/// // usage
/// Image.asset(Assets.logo)
/// SvgPicture.asset(Assets.arrowIcon)
/// ```
class AvoidHardcodedAssetPath extends FlintLintRule {
  AvoidHardcodedAssetPath() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_hardcoded_asset_path',
    problemMessage:
        'Avoid hardcoded asset paths. '
        'Use a constants class (e.g., Assets.logo) instead.',
    correctionMessage:
        'Define asset paths in a dedicated constants class and reference them.',
  );

  static final _assetPathPattern = RegExp(r'^assets/');

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addSimpleStringLiteral((node) {
      if (!_assetPathPattern.hasMatch(node.value)) return;

      // Allow asset paths in const/static const field declarations
      if (_isInConstFieldDeclaration(node)) return;

      // Allow asset paths in top-level const variable declarations
      if (_isInTopLevelConstDeclaration(node)) return;

      reporter.atNode(node, _code);
    });
  }

  /// `static const` 또는 `const` 필드 선언 안에 있는지 확인합니다.
  /// 에셋 상수 클래스 정의를 허용하기 위함입니다.
  bool _isInConstFieldDeclaration(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is VariableDeclaration) {
        final declarationList = current.parent;
        if (declarationList is VariableDeclarationList) {
          if (declarationList.isConst) return true;

          // static const field in a class
          final fieldDeclaration = declarationList.parent;
          if (fieldDeclaration is FieldDeclaration) {
            if (fieldDeclaration.isStatic && declarationList.isConst) {
              return true;
            }
          }
        }
      }
      current = current.parent;
    }
    return false;
  }

  /// 최상위 const 변수 선언에 있는지 확인합니다.
  bool _isInTopLevelConstDeclaration(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is TopLevelVariableDeclaration) {
        return current.variables.isConst;
      }
      current = current.parent;
    }
    return false;
  }
}
