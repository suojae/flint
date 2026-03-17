import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # enforce_test_framework
///
/// ## 규칙
/// 테스트 유형에 맞는 프레임워크를 사용하세요.
///
/// ## 원리
/// 팀 전체가 일관된 테스트 프레임워크를 사용하면
/// 코드 리뷰가 쉬워지고, 테스트 인프라 유지보수 비용이 줄어듭니다.
///
/// | 테스트 유형     | 프레임워크                          |
/// |----------------|-------------------------------------|
/// | 단위 테스트     | `flutter_test` + `mocktail`         |
/// | 위젯 테스트     | `flutter_test` (`WidgetTester`)     |
/// | 상태관리 테스트  | `bloc_test` 또는 `ProviderContainer` |
/// | E2E 테스트      | `patrol`                            |
///
/// ## 나쁜 예
/// ```dart
/// // 단위 테스트에서 mockito 사용
/// import 'package:mockito/mockito.dart';
///
/// // E2E 테스트에서 patrol 미사용
/// // integration_test/app_test.dart
/// import 'package:flutter_test/flutter_test.dart';
///
/// // Bloc 테스트에서 bloc_test 미사용
/// import 'package:flutter_bloc/flutter_bloc.dart';
/// test('bloc test', () { ... });
/// ```
///
/// ## 좋은 예
/// ```dart
/// // 단위 테스트
/// import 'package:flutter_test/flutter_test.dart';
/// import 'package:mocktail/mocktail.dart';
///
/// // E2E 테스트
/// import 'package:patrol/patrol.dart';
///
/// // Bloc 테스트
/// import 'package:bloc_test/bloc_test.dart';
/// ```
class EnforceTestFramework extends FlintLintRule {
  EnforceTestFramework() : super(code: _mockitoCode);

  // ── Lint codes ──────────────────────────────────────────────

  static const _mockitoCode = LintCode(
    name: 'enforce_test_framework',
    problemMessage:
        'mockito 대신 mocktail을 사용하세요. '
        'mocktail은 코드 생성 없이 mock을 만들 수 있습니다.',
    correctionMessage:
        "import 'package:mocktail/mocktail.dart'로 변경하세요.",
  );

  static const _rawTestCode = LintCode(
    name: 'enforce_test_framework',
    problemMessage:
        'package:test 대신 package:flutter_test를 사용하세요. '
        'flutter_test는 test를 포함하며 위젯 테스트도 지원합니다.',
    correctionMessage:
        "import 'package:flutter_test/flutter_test.dart'로 변경하세요.",
  );

  static const _patrolCode = LintCode(
    name: 'enforce_test_framework',
    problemMessage:
        'E2E 테스트에서는 patrol을 사용하세요. '
        'patrol은 네이티브 인터랙션과 딥 링크 테스트를 지원합니다.',
    correctionMessage:
        "import 'package:patrol/patrol.dart'를 추가하세요.",
  );

  static const _blocTestCode = LintCode(
    name: 'enforce_test_framework',
    problemMessage:
        'Bloc/Cubit 테스트에서는 bloc_test를 사용하세요. '
        'blocTest()는 상태 전이를 선언적으로 검증합니다.',
    correctionMessage:
        "import 'package:bloc_test/bloc_test.dart'를 추가하세요.",
  );

  // ── 상태관리 관련 패키지 패턴 ───────────────────────────────

  static const _blocPackages = [
    'package:bloc/',
    'package:flutter_bloc/',
  ];

  static const _riverpodPackages = [
    'package:riverpod/',
    'package:flutter_riverpod/',
    'package:hooks_riverpod/',
  ];

  // ── 분석 로직 ──────────────────────────────────────────────

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    // 테스트 파일에만 적용
    if (!resolver.path.endsWith('_test.dart')) return;

    final isIntegrationTest = resolver.path.contains('/integration_test/');

    // import 단위 검사: mockito, package:test
    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null) return;

      // mockito → mocktail
      if (uri.startsWith('package:mockito')) {
        reporter.atNode(node, _mockitoCode);
      }

      // package:test → flutter_test
      if (uri == 'package:test/test.dart') {
        reporter.atNode(node, _rawTestCode);
      }
    });

    // 파일 전체 단위 검사: E2E / 상태관리
    context.registry.addCompilationUnit((node) {
      final imports = node.directives
          .whereType<ImportDirective>()
          .map((d) => d.uri.stringValue ?? '')
          .toList();

      // E2E 테스트 → patrol 필수
      if (isIntegrationTest) {
        final hasPatrol =
            imports.any((uri) => uri.startsWith('package:patrol'));
        if (!hasPatrol) {
          // 첫 번째 import에 경고 표시 (파일 위치 표시용)
          final firstImport = node.directives
              .whereType<ImportDirective>()
              .firstOrNull;
          if (firstImport != null) {
            reporter.atNode(firstImport, _patrolCode);
          }
        }
      }

      // Bloc/Cubit 테스트 → bloc_test 필수
      if (!isIntegrationTest) {
        _checkBlocTestRequired(node, imports, reporter);
      }
    });
  }

  void _checkBlocTestRequired(
    CompilationUnit node,
    List<String> imports,
    DiagnosticReporter reporter,
  ) {
    final importsBlocPackage = imports.any(
      (uri) => _blocPackages.any((pkg) => uri.startsWith(pkg)),
    );
    if (!importsBlocPackage) return;

    final hasBlocTest =
        imports.any((uri) => uri.startsWith('package:bloc_test'));

    // Riverpod의 ProviderContainer도 상태관리 테스트 도구로 허용
    final hasRiverpodTest =
        imports.any((uri) => _riverpodPackages.any((pkg) => uri.startsWith(pkg)));

    if (!hasBlocTest && !hasRiverpodTest) {
      // bloc 관련 import 노드에 경고 표시
      final blocImport = node.directives
          .whereType<ImportDirective>()
          .where((d) {
            final uri = d.uri.stringValue ?? '';
            return _blocPackages.any((pkg) => uri.startsWith(pkg));
          })
          .firstOrNull;
      if (blocImport != null) {
        reporter.atNode(blocImport, _blocTestCode);
      }
    }
  }
}
