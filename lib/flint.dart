library flint;

import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:flint/src/rules/dart/avoid_empty_catch.dart';
import 'package:flint/src/rules/dart/avoid_lint_ignore.dart';
import 'package:flint/src/rules/dart/avoid_long_file.dart';
import 'package:flint/src/rules/dart/avoid_relative_import.dart';
import 'package:flint/src/rules/functional/avoid_dynamic_type.dart';
import 'package:flint/src/rules/functional/avoid_mutable_global_state.dart';
import 'package:flint/src/rules/functional/avoid_mutating_parameters.dart';
import 'package:flint/src/rules/functional/prefer_pattern_matching.dart';
import 'package:flint/src/rules/state/bloc/enforce_bloc_naming.dart';
import 'package:flint/src/rules/flutter/avoid_hardcoded_color.dart';
import 'package:flint/src/rules/flutter/avoid_image_opacity.dart';
import 'package:flint/src/rules/flutter/avoid_nested_padding.dart';
import 'package:flint/src/rules/flutter/avoid_shrink_wrap_in_list.dart';
import 'package:flint/src/rules/flutter/avoid_single_child_column_or_row.dart';
import 'package:flint/src/rules/flutter/avoid_visibility_widget.dart';

PluginBase createPlugin() => _FlintPlugin();

class _FlintPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        AvoidImageOpacity(),
        AvoidHardcodedColor(),
        AvoidVisibilityWidget(),
        AvoidShrinkWrapInList(),
        AvoidSingleChildColumnOrRow(),
        AvoidEmptyCatch(),
        AvoidLintIgnore(),
        AvoidLongFile(),
        AvoidRelativeImport(),
        AvoidNestedPadding(),
        AvoidMutableGlobalState(),
        AvoidMutatingParameters(),
        AvoidDynamicType(),
        PreferPatternMatching(),
        EnforceBlocNaming(),
      ];
}
