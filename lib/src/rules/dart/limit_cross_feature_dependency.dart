import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # limit_cross_feature_dependency
///
/// ## 규칙
/// Clean Architecture 레이어별로 다른 feature 의존을 제한합니다.
///
/// - `domain/` : 다른 feature import 완전 금지 (0개)
/// - `data/`   : 다른 feature import 완전 금지 (0개)
/// - `presentation/` : 다른 feature import 최대 3개까지 허용
/// - DI/라우터/main 파일 : 검사 제외
///
/// ## 원리
/// domain과 data 레이어는 자기 feature의 비즈니스 로직과
/// 데이터 구현만 담당해야 합니다.
/// presentation은 여러 feature를 조합해 화면을 구성할 수 있지만,
/// 과도한 의존(4개 이상)은 책임 과잉을 의미합니다.
///
/// ## 나쁜 예
/// ```dart
/// // features/auth/domain/usecases/login.dart 에서:
/// import 'package:app/features/payment/domain/entities/payment.dart';
/// ```
///
/// ## 좋은 예
/// ```dart
/// // features/auth/presentation/pages/login_page.dart 에서:
/// import 'package:app/features/user/domain/entities/user.dart';
/// import 'package:app/features/notification/domain/entities/alert.dart';
/// ```
class LimitCrossFeatureDependency extends FlintLintRule {
  LimitCrossFeatureDependency() : super(code: _domainDataCode);

  static const _domainDataCode = LintCode(
    name: 'limit_cross_feature_dependency',
    problemMessage:
        'domain/data layer must not depend on other features. '
        'Keep this layer isolated to its own feature.',
    correctionMessage:
        'Move shared logic to a common module, or access '
        'other features through the presentation layer.',
  );

  static const _presentationCode = LintCode(
    name: 'limit_cross_feature_dependency',
    problemMessage:
        'Presentation layer depends on too many features (max 3). '
        'Consider using a mediator pattern or splitting this file.',
    correctionMessage:
        'Reduce cross-feature dependencies to 3 or fewer.',
  );

  static const _maxPresentationFeatures = 3;

  static const _excludedFiles = [
    'injection.dart',
    'service_locator.dart',
    'injector.dart',
    'di.dart',
    'router.dart',
    'app_router.dart',
    'routes.dart',
    'main.dart',
    'app.dart',
  ];

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

      final packagePath =
          libraryUri.substring(libraryUri.indexOf('/') + 1);

      // DI/라우터/main 파일은 검사 제외
      final fileName = packagePath.split('/').last;
      if (_excludedFiles.contains(fileName)) return;

      // features/ 디렉토리 내부인지 확인
      final segments = packagePath.split('/');
      final featuresIndex = segments.indexOf('features');
      if (featuresIndex == -1) return;
      if (featuresIndex + 1 >= segments.length) return;

      final currentFeature = segments[featuresIndex + 1];

      // 현재 파일의 레이어 판별
      final layerIndex = featuresIndex + 2;
      if (layerIndex >= segments.length) return;
      final layer = segments[layerIndex];

      // 현재 패키지명 추출
      final currentPackage =
          libraryUri.substring('package:'.length, libraryUri.indexOf('/'));

      // 모든 import를 순회하며 다른 feature 의존 수집
      final crossFeatureImports = <String, List<ImportDirective>>{};

      for (final directive in unit.directives) {
        if (directive is! ImportDirective) continue;
        final uri = directive.uri.stringValue;
        if (uri == null || !uri.startsWith('package:')) continue;

        // 외부 패키지는 무시
        final importedPackage =
            uri.substring('package:'.length, uri.indexOf('/'));
        if (importedPackage != currentPackage) continue;

        final importedPath = uri.substring(uri.indexOf('/') + 1);
        final importedSegments = importedPath.split('/');
        final importedFeaturesIndex =
            importedSegments.indexOf('features');
        if (importedFeaturesIndex == -1) continue;
        if (importedFeaturesIndex + 1 >= importedSegments.length) continue;

        final importedFeature =
            importedSegments[importedFeaturesIndex + 1];
        if (importedFeature == currentFeature) continue;

        crossFeatureImports
            .putIfAbsent(importedFeature, () => [])
            .add(directive);
      }

      if (crossFeatureImports.isEmpty) return;

      if (layer == 'domain' || layer == 'data') {
        // domain/data: 다른 feature 의존 완전 금지
        for (final imports in crossFeatureImports.values) {
          for (final node in imports) {
            reporter.atNode(node, _domainDataCode);
          }
        }
      } else if (layer == 'presentation') {
        // presentation: 의존 feature 수 제한
        if (crossFeatureImports.length > _maxPresentationFeatures) {
          for (final imports in crossFeatureImports.values) {
            for (final node in imports) {
              reporter.atNode(node, _presentationCode);
            }
          }
        }
      }
    });
  }
}
