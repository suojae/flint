import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';

/// # avoid_raw_go_router_navigation
///
/// ## 규칙
/// `BuildContext`나 `GoRouter`에서 문자열 기반 `go_router` 네비게이션 API를
/// 직접 호출하지 마세요. 생성된 typed route API를 사용하세요.
///
/// ## 원리
/// `context.go('/home')`, `router.pushNamed('login')` 같은 호출은
/// 경로 문자열과 파라미터 키를 런타임 문자열에 의존하게 만듭니다.
/// 이 방식은:
/// - 경로 오타를 컴파일 타임에 잡지 못하고
/// - 리팩터링 시 rename safety가 없고
/// - path/query 파라미터 누락을 쉽게 만들며
/// - 라우트 정의와 사용처가 문자열로 흩어져 추적이 어려워집니다.
///
/// `typed_go_router`를 사용하면 route 클래스가 타입 안전한 네비게이션 API를
/// 제공하므로, 경로 문자열 대신 `HomeRoute().go(context)` 같은 호출로
/// 일관되게 이동할 수 있습니다.
///
/// ## 감지 대상
/// - `context.go(...)`, `context.push(...)`, `context.goNamed(...)`
/// - `router.go(...)`, `router.pushNamed(...)`
/// - `GoRouter.of(context).go(...)`
///
/// ## 허용 예
/// - `const HomeRoute().go(context)`
/// - `UserDetailRoute(id: id).push(context)`
///
/// ## 나쁜 예
/// ```dart
/// context.go('/home');
/// context.pushNamed('user', pathParameters: {'id': id});
/// GoRouter.of(context).replace('/settings');
/// ```
///
/// ## 좋은 예
/// ```dart
/// const HomeRoute().go(context);
/// UserRoute(id: id).push(context);
/// const SettingsRoute().replace(context);
/// ```
class AvoidRawGoRouterNavigation extends FlintLintRule {
  AvoidRawGoRouterNavigation() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_raw_go_router_navigation',
    problemMessage:
        'Avoid raw go_router navigation APIs on BuildContext/GoRouter. '
        'Use typed route data APIs instead.',
    correctionMessage:
        'Replace string-based navigation with generated typed routes, '
        'for example HomeRoute().go(context).',
  );

  static const _rawNavigationMethodNames = {
    'go',
    'goNamed',
    'push',
    'pushNamed',
    'pushReplacement',
    'pushReplacementNamed',
    'replace',
    'replaceNamed',
  };

  static final _buildContextFrameworkUri = Uri.parse(
    'package:flutter/src/widgets/framework.dart',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!_isRawGoRouterNavigation(node)) return;
      reporter.atNode(node, _code);
    });
  }

  bool _isRawGoRouterNavigation(MethodInvocation node) {
    if (!_rawNavigationMethodNames.contains(node.methodName.name)) {
      return false;
    }

    final target = node.realTarget;
    if (target == null) return false;

    final targetType = target.staticType;

    if (_isBuildContextType(targetType)) {
      return _isGoRouterBuildContextExtension(node.methodName.element);
    }

    return _isGoRouterType(targetType);
  }

  bool _isBuildContextType(DartType? type) {
    return _hasMatchingSupertype(type, (interfaceType) {
      final element = interfaceType.element;
      return element.name == 'BuildContext' &&
          element.library.uri == _buildContextFrameworkUri;
    });
  }

  bool _isGoRouterType(DartType? type) {
    return _hasMatchingSupertype(type, (interfaceType) {
      final element = interfaceType.element;
      return element.name == 'GoRouter' &&
          _isGoRouterLibraryUri(element.library.uri.toString());
    });
  }

  bool _isGoRouterBuildContextExtension(Element? element) {
    if (element is! ExecutableElement) return false;
    return _isGoRouterLibraryUri(element.library.uri.toString());
  }

  bool _isGoRouterLibraryUri(String uri) {
    return uri.startsWith('package:go_router/');
  }

  bool _hasMatchingSupertype(
    DartType? type,
    bool Function(InterfaceType interfaceType) predicate,
  ) {
    if (type is! InterfaceType) return false;
    if (predicate(type)) return true;
    return type.element.allSupertypes.any(predicate);
  }
}
