library flint;

import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/dart/avoid_barrel_file.dart';
import 'package:flint/src/rules/dart/avoid_as_cast.dart';
import 'package:flint/src/rules/dart/avoid_deep_import.dart';
import 'package:flint/src/rules/dart/limit_cross_feature_dependency.dart';
import 'package:flint/src/rules/dart/avoid_direct_crashlytics.dart';
import 'package:flint/src/rules/dart/avoid_direct_firebase_analytics.dart';
import 'package:flint/src/rules/dart/enforce_layer_dependency_direction.dart';
import 'package:flint/src/rules/dart/enforce_catch_logging.dart';
import 'package:flint/src/rules/dart/enforce_talker_error_stacktrace.dart';
import 'package:flint/src/rules/dart/avoid_empty_catch.dart';
import 'package:flint/src/rules/dart/avoid_force_unwrap.dart';
import 'package:flint/src/rules/dart/avoid_lint_ignore.dart';
import 'package:flint/src/rules/dart/avoid_long_file.dart';
import 'package:flint/src/rules/dart/avoid_nested_conditional.dart';
import 'package:flint/src/rules/dart/avoid_relative_import.dart';
import 'package:flint/src/rules/dart/avoid_untyped_collection.dart';
import 'package:flint/src/rules/dart/max_function_parameters.dart';
import 'package:flint/src/rules/dart/prefer_explicit_return_type.dart';
import 'package:flint/src/rules/dart/prefer_talker_logger.dart';
import 'package:flint/src/rules/functional/avoid_dynamic_type.dart';
import 'package:flint/src/rules/functional/avoid_mutable_global_state.dart';
import 'package:flint/src/rules/functional/avoid_mutating_parameters.dart';
import 'package:flint/src/rules/functional/prefer_pattern_matching.dart';
import 'package:flint/src/rules/state/bloc/avoid_bloc_in_widget.dart';
import 'package:flint/src/rules/state/bloc/enforce_bloc_naming.dart';
import 'package:flint/src/rules/test/enforce_test_framework.dart';
import 'package:flint/src/rules/flutter/avoid_hardcoded_asset_path.dart';
import 'package:flint/src/rules/flutter/avoid_hardcoded_color.dart';
import 'package:flint/src/rules/flutter/avoid_controller_in_build.dart';
import 'package:flint/src/rules/flutter/avoid_image_opacity.dart';
import 'package:flint/src/rules/flutter/avoid_nested_padding.dart';
import 'package:flint/src/rules/flutter/avoid_raw_go_router_navigation.dart';
import 'package:flint/src/rules/flutter/avoid_side_effect_in_build.dart';
import 'package:flint/src/rules/flutter/avoid_shrink_wrap_in_list.dart';
import 'package:flint/src/rules/flutter/avoid_single_child_column_or_row.dart';
import 'package:flint/src/rules/flutter/avoid_visibility_widget.dart';
import 'package:flint/src/rules/flutter/avoid_widget_helper_method.dart';
import 'package:flint/src/rules/flutter/enforce_dispose_owned_fields.dart';
import 'package:flint/src/rules/flutter/enforce_widget_suffix.dart';
import 'package:flint/src/rules/flutter/prefer_specific_media_query_methods.dart';
import 'package:flint/src/rules/flutter/prefer_widget_composition.dart';

PluginBase createPlugin() => _FlintPlugin();

class _FlintPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        AvoidImageOpacity(),
        AvoidHardcodedAssetPath(),
        AvoidHardcodedColor(),
        AvoidControllerInBuild(),
        AvoidRawGoRouterNavigation(),
        AvoidSideEffectInBuild(),
        AvoidVisibilityWidget(),
        AvoidShrinkWrapInList(),
        AvoidSingleChildColumnOrRow(),
        AvoidWidgetHelperMethod(),
        PreferSpecificMediaQueryMethods(),
        EnforceDisposeOwnedFields(),
        AvoidBarrelFile(),
        AvoidAsCast(),
        AvoidDeepImport(),
        EnforceLayerDependencyDirection(),
        LimitCrossFeatureDependency(),
        AvoidEmptyCatch(),
        AvoidForceUnwrap(),
        AvoidLintIgnore(),
        AvoidLongFile(),
        AvoidNestedConditional(),
        AvoidRelativeImport(),
        AvoidUntypedCollection(),
        MaxFunctionParameters(),
        PreferExplicitReturnType(),
        PreferTalkerLogger(),
        AvoidNestedPadding(),
        AvoidMutableGlobalState(),
        AvoidMutatingParameters(),
        AvoidDynamicType(),
        PreferPatternMatching(),
        AvoidBlocInWidget(),
        EnforceBlocNaming(),
        EnforceWidgetSuffix(),
        EnforceTestFramework(),
        PreferWidgetComposition(),
        EnforceCatchLogging(),
        AvoidDirectCrashlytics(),
        AvoidDirectFirebaseAnalytics(),
        EnforceTalkerErrorStacktrace(),
      ];
}
