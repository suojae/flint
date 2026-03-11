library flint;

import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rules/avoid_empty_catch.dart';
import 'src/rules/avoid_hardcoded_color.dart';
import 'src/rules/avoid_image_opacity.dart';
import 'src/rules/avoid_shrink_wrap_in_list.dart';
import 'src/rules/avoid_single_child_column_or_row.dart';
import 'src/rules/avoid_visibility_widget.dart';

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
      ];
}
