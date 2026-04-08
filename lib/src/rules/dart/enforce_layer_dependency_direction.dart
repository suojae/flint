import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # enforce_layer_dependency_direction
///
/// ## 규칙
/// `features/<feature>/<layer>` 구조에서 레이어 의존 방향을 강제합니다.
///
/// - `domain/` 은 `domain/` 에만 의존할 수 있습니다.
/// - `data/` 는 `domain/`, `data/` 에만 의존할 수 있습니다.
/// - `presentation/` 은 `domain/`, `presentation/` 에만 의존할 수 있습니다.
///
/// feature 밖 공통 모듈(`core/`, `shared/` 등)은 이 규칙의 검사 대상이
/// 아닙니다. 이 규칙은 feature 내부 레이어 간 방향성만 다룹니다.
///
/// ## 원리
/// Clean Architecture에서 안쪽 레이어는 바깥 레이어를 몰라야 합니다.
///
/// - `domain -> data/presentation` 이 되면 비즈니스 규칙이 구현/UI에 묶이고
/// - `data -> presentation` 이 되면 데이터 구현이 화면 로직을 알게 되며
/// - `presentation -> data` 가 되면 UI가 구체 구현에 직접 결합됩니다.
///
/// 레이어 방향을 고정하면 파일 경로만 봐도 역할과 허용 의존성을 추론할 수
/// 있어서, 사람과 AI 모두 코드베이스를 훨씬 안정적으로 읽을 수 있습니다.
///
/// ## 나쁜 예
/// ```dart
/// // features/auth/domain/usecases/login.dart
/// import 'package:app/features/auth/data/repositories/auth_repository_impl.dart';
///
/// // features/auth/data/repositories/auth_repository_impl.dart
/// import 'package:app/features/auth/presentation/pages/login_page.dart';
///
/// // features/auth/presentation/pages/login_page.dart
/// import 'package:app/features/auth/data/datasources/auth_remote_data_source.dart';
/// ```
///
/// ## 좋은 예
/// ```dart
/// // features/auth/data/repositories/auth_repository_impl.dart
/// import 'package:app/features/auth/domain/repositories/auth_repository.dart';
///
/// // features/auth/presentation/pages/login_page.dart
/// import 'package:app/features/auth/domain/usecases/login.dart';
/// ```
class EnforceLayerDependencyDirection extends FlintLintRule {
  EnforceLayerDependencyDirection() : super(code: _domainCode);

  static const _domainCode = LintCode(
    name: 'enforce_layer_dependency_direction',
    problemMessage:
        'Domain layer must not depend on data or presentation layers. '
        'Keep domain isolated from implementation and UI.',
    correctionMessage:
        'Depend only on domain abstractions, or move shared code to a common '
        'module outside the feature layers.',
  );

  static const _dataCode = LintCode(
    name: 'enforce_layer_dependency_direction',
    problemMessage: 'Data layer must not depend on presentation layer. '
        'Data should serve the UI, not know about it.',
    correctionMessage:
        'Move UI-specific logic to presentation, or depend on domain '
        'abstractions instead.',
  );

  static const _presentationCode = LintCode(
    name: 'enforce_layer_dependency_direction',
    problemMessage:
        'Presentation layer must not depend on data layer directly. '
        'Depend on domain contracts instead.',
    correctionMessage:
        'Import a domain use case, entity, or repository interface instead of '
        'a data implementation.',
  );

  static const _allowedLayersByCurrentLayer = <String, Set<String>>{
    'domain': {'domain'},
    'data': {'domain', 'data'},
    'presentation': {'domain', 'presentation'},
  };

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((unit) {
      final libraryUri = unit.declaredFragment?.source.uri.toString();
      if (libraryUri == null || !libraryUri.startsWith('package:')) return;

      final currentLocation =
          _parseFeatureLayer(_extractPackagePath(libraryUri));
      if (currentLocation == null) return;

      final allowedLayers = _allowedLayersByCurrentLayer[currentLocation.layer];
      if (allowedLayers == null) return;

      final currentPackage = _extractPackageName(libraryUri);

      for (final directive in unit.directives) {
        if (directive is! UriBasedDirective) continue;

        final uri = directive.uri.stringValue;
        if (uri == null || !uri.startsWith('package:')) continue;
        if (_extractPackageName(uri) != currentPackage) continue;

        final importedLocation = _parseFeatureLayer(_extractPackagePath(uri));
        if (importedLocation == null) continue;
        if (allowedLayers.contains(importedLocation.layer)) continue;

        reporter.atNode(directive, _codeForLayer(currentLocation.layer));
      }
    });
  }

  LintCode _codeForLayer(String layer) {
    switch (layer) {
      case 'domain':
        return _domainCode;
      case 'data':
        return _dataCode;
      case 'presentation':
        return _presentationCode;
      default:
        return _domainCode;
    }
  }

  String _extractPackageName(String packageUri) {
    final slashIndex = packageUri.indexOf('/');
    return packageUri.substring('package:'.length, slashIndex);
  }

  String _extractPackagePath(String packageUri) {
    return packageUri.substring(packageUri.indexOf('/') + 1);
  }

  _FeatureLayerLocation? _parseFeatureLayer(String path) {
    final segments = path.split('/');
    final featuresIndex = segments.indexOf('features');
    if (featuresIndex == -1 || featuresIndex + 2 >= segments.length) {
      return null;
    }

    final layer = segments[featuresIndex + 2];
    if (!_allowedLayersByCurrentLayer.containsKey(layer)) {
      return null;
    }

    return _FeatureLayerLocation(layer: layer);
  }
}

class _FeatureLayerLocation {
  const _FeatureLayerLocation({
    required this.layer,
  });

  final String layer;
}
