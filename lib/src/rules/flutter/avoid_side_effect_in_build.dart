import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/flint_lint_rule.dart';
import 'package:flint/src/utils/build_scope_helpers.dart';

/// # avoid_side_effect_in_build
///
/// ## 규칙
/// `build()` 또는 `buildXxx()`/`_buildXxx()` 함수 안에서
/// 네비게이션, 다이얼로그/스낵바 표시, Bloc 이벤트 발행 같은
/// side effect를 직접 실행하거나 post-frame callback으로 예약하지 마세요.
///
/// ## 원리
/// Flutter의 `build()`는 여러 번 호출되는 것이 정상입니다.
/// 여기서 `Navigator.push()`, `showDialog()`, `bloc.add()`,
/// `addPostFrameCallback()` 같은 effect를 실행/예약하면
/// rebuild마다 같은 동작이 반복되어:
/// - 같은 화면이 여러 번 push되거나
/// - dialog/snackbar가 중복 표시되거나
/// - Bloc 이벤트가 반복 발행되거나
/// - post-frame callback이 프레임마다 다시 예약되어
///   무한 루프나 중복 요청으로 이어질 수 있습니다.
///
/// 이런 side effect는 `onPressed` 같은 사용자 액션 콜백,
/// `BlocListener`, `initState()`, `ref.listen` 등
/// effect 전용 위치로 옮겨야 합니다.
///
/// ## 감지 대상
/// - `Navigator.push/pop/...`
/// - `showDialog`, `showModalBottomSheet`, `showDatePicker` 등
/// - `ScaffoldMessenger.of(context).showSnackBar(...)`
/// - `bloc.add(...)`, `cubit.emit(...)`, `bloc.close()`
/// - `WidgetsBinding.instance.addPostFrameCallback(...)`
/// - `SchedulerBinding.instance.addPostFrameCallback(...)`
///
/// ## 나쁜 예
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   if (state is LoginSuccess) {
///     Navigator.push(context, HomeRoute());
///   }
///
///   return const LoginView();
/// }
/// ```
///
/// ## 좋은 예
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return BlocListener<LoginBloc, LoginState>(
///     listenWhen: (prev, next) => next is LoginSuccess,
///     listener: (context, state) {
///       Navigator.push(context, HomeRoute());
///     },
///     child: const LoginView(),
///   );
/// }
/// ```
class AvoidSideEffectInBuild extends FlintLintRule {
  AvoidSideEffectInBuild() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_side_effect_in_build',
    problemMessage: 'Avoid triggering side effects inside build(). '
        'Build can run multiple times.',
    correctionMessage:
        'Move navigation, dialogs, snackbars, bloc event dispatch, and '
        'post-frame callback registration to callbacks, listeners, '
        'initState(), or another effect boundary.',
  );

  static const _dialogFunctionNames = {
    'showAdaptiveDialog',
    'showBottomSheet',
    'showCupertinoDialog',
    'showCupertinoModalPopup',
    'showDatePicker',
    'showDialog',
    'showGeneralDialog',
    'showLicensePage',
    'showMenu',
    'showModalBottomSheet',
    'showSearch',
    'showTimePicker',
  };

  static const _navigatorMethodNames = {
    'maybePop',
    'pop',
    'popAndPushNamed',
    'popUntil',
    'push',
    'pushAndRemoveUntil',
    'pushNamed',
    'pushNamedAndRemoveUntil',
    'pushReplacement',
    'pushReplacementNamed',
    'replace',
    'replaceRouteBelow',
    'restorablePopAndPushNamed',
    'restorablePush',
    'restorablePushAndRemoveUntil',
    'restorablePushNamed',
    'restorablePushNamedAndRemoveUntil',
    'restorablePushReplacement',
    'restorablePushReplacementNamed',
  };

  static const _scaffoldMessengerMethodNames = {
    'clearSnackBars',
    'hideCurrentMaterialBanner',
    'hideCurrentSnackBar',
    'removeCurrentMaterialBanner',
    'removeCurrentSnackBar',
    'showMaterialBanner',
    'showSnackBar',
  };

  static const _blocSideEffectMethodNames = {
    'add',
    'addError',
    'close',
    'emit',
  };

  static const _postFrameCallbackMethodName = 'addPostFrameCallback';

  static final _blocPackagePrefixes = [
    'package:bloc/',
    'package:flutter_bloc/'
  ];

  static final _navigatorFrameworkUri = Uri.parse(
    'package:flutter/src/widgets/navigator.dart',
  );

  static final _widgetsBindingFrameworkUri = Uri.parse(
    'package:flutter/src/widgets/binding.dart',
  );

  static final _schedulerBindingFrameworkUri = Uri.parse(
    'package:flutter/src/scheduler/binding.dart',
  );

  static final _scaffoldMessengerFrameworkUri = Uri.parse(
    'package:flutter/src/material/scaffold.dart',
  );

  @override
  void analyze(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!isInsideBuildScope(node)) return;
      if (_isDialogCall(node) ||
          _isNavigatorCall(node) ||
          _isScaffoldMessengerCall(node) ||
          _isBlocSideEffect(node) ||
          _isPostFrameCallbackRegistration(node)) {
        reporter.atNode(node, _code);
      }
    });
  }

  bool _isDialogCall(MethodInvocation node) {
    return node.target == null &&
        _dialogFunctionNames.contains(node.methodName.name);
  }

  bool _isNavigatorCall(MethodInvocation node) {
    if (!_navigatorMethodNames.contains(node.methodName.name)) return false;

    final target = node.target;
    if (target is SimpleIdentifier && target.name == 'Navigator') {
      return true;
    }

    return _isNavigatorStateType(target?.staticType);
  }

  bool _isScaffoldMessengerCall(MethodInvocation node) {
    if (!_scaffoldMessengerMethodNames.contains(node.methodName.name)) {
      return false;
    }

    final target = node.target;
    if (target is MethodInvocation &&
        target.target is SimpleIdentifier &&
        (target.target as SimpleIdentifier).name == 'ScaffoldMessenger' &&
        target.methodName.name == 'of') {
      return true;
    }

    return _isScaffoldMessengerStateType(target?.staticType);
  }

  bool _isBlocSideEffect(MethodInvocation node) {
    if (!_blocSideEffectMethodNames.contains(node.methodName.name)) {
      return false;
    }

    return _isBlocLikeType(node.target?.staticType);
  }

  bool _isPostFrameCallbackRegistration(MethodInvocation node) {
    if (node.methodName.name != _postFrameCallbackMethodName) {
      return false;
    }

    return _isBindingInstanceAccess(node.target) ||
        _isFrameCallbackBindingType(node.target?.staticType);
  }

  bool _isNavigatorStateType(DartType? type) {
    return _hasMatchingSupertype(type, (interfaceType) {
      final element = interfaceType.element;
      return element.name == 'NavigatorState' &&
          element.library.uri == _navigatorFrameworkUri;
    });
  }

  bool _isScaffoldMessengerStateType(DartType? type) {
    return _hasMatchingSupertype(type, (interfaceType) {
      final element = interfaceType.element;
      return element.name == 'ScaffoldMessengerState' &&
          element.library.uri == _scaffoldMessengerFrameworkUri;
    });
  }

  bool _isBlocLikeType(DartType? type) {
    return _hasMatchingSupertype(type, (interfaceType) {
      final element = interfaceType.element;
      final uri = element.library.uri.toString();
      return _blocPackagePrefixes.any(uri.startsWith) &&
          (element.name == 'Bloc' ||
              element.name == 'BlocBase' ||
              element.name == 'Cubit');
    });
  }

  bool _isBindingInstanceAccess(Expression? target) {
    if (target is PrefixedIdentifier) {
      return target.identifier.name == 'instance' &&
          (target.prefix.name == 'WidgetsBinding' ||
              target.prefix.name == 'SchedulerBinding');
    }

    if (target is PropertyAccess) {
      return target.propertyName.name == 'instance' &&
          target.target is SimpleIdentifier &&
          ((target.target as SimpleIdentifier).name == 'WidgetsBinding' ||
              (target.target as SimpleIdentifier).name == 'SchedulerBinding');
    }

    return false;
  }

  bool _isFrameCallbackBindingType(DartType? type) {
    return _hasMatchingSupertype(type, (interfaceType) {
      final element = interfaceType.element;
      return (element.name == 'WidgetsBinding' &&
              element.library.uri == _widgetsBindingFrameworkUri) ||
          (element.name == 'SchedulerBinding' &&
              element.library.uri == _schedulerBindingFrameworkUri);
    });
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
