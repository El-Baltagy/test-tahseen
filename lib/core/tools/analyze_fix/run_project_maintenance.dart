// tools/run_project_maintenance.dart
import 'package:${PathConstants().projectName}/core/tools/utils_spinner.dart';

import '1-pubspec_patcher.dart' as patcher;
import '2-smart_const_fixer.dart' as constfixer;
import '3-organize_reformat_Code.dart' as formatter;
import '4-find_to_do_commits.dart' as getToDo;
import '5-code_stream_analyzer.dart' as analyzer;
Future<void> main(List<String> args) async {
  final withFixes = args.contains('--fix');
  final spinner = Spinner('🧰 Running Project Maintenance...');
  spinner.start();

/// ToDo
  await patcher.runPubspecPatcher();
  await constfixer.runSmartConstFixer();
  await formatter.reformatCode();
  await getToDo.getToDoCommits();
  await analyzer.runCodeStreamAnalyzer(autoFix: withFixes);


  spinner.stop('✅ Maintenance completed successfully!');
}
