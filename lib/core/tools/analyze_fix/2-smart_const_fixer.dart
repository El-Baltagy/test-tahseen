// tools/2-smart_const_fixer.dart
import 'dart:io';

// import 'utils_spinner.dart';

Future<void> runSmartConstFixer() async {
  // final spinner = Spinner('⚡ Applying smart const fixes...');
  // spinner.start();

  final result = await Process.run(
    'dart',
    ['fix', '--apply'],
    runInShell: true,
  );

  stdout.write(result.stdout);
  stderr.write(result.stderr);

  if (result.exitCode == 0) {
    print('✅ Const fixes applied successfully');
  } else {
    print('❌ Fix failed');
    exit(result.exitCode);
  }
  // spinner.stop('✅ Smart const fixes applied.');
}



