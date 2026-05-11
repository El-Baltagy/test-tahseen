import 'dart:isolate';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:linters/linters.dart';

void main(List<String> args, SendPort sendPort) {
  startPlugin(sendPort, TahseenLints());
}

class TahseenLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        ArchitectureRegistrationRule(),
      ];
}
