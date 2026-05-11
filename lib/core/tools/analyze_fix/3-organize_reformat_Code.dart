import 'dart:io';


Future<void> reformatCode() async {
  // print('⚡ Reformatting all Dart files in lib/...');

  // 1️⃣ Format all Dart files in lib/
  final formatResult = await Process.run(
    'dart',
    ['format', 'lib'],
    runInShell: true,
  );

  stdout.write(formatResult.stdout);
  stderr.write(formatResult.stderr);

  if (formatResult.exitCode != 0) {
    print('❌ dart format failed');
    exit(formatResult.exitCode);
  }

  print('✅ Formatting complete');

  // 2️⃣ Apply Dart analyzer fixes (const, imports, etc.)
  print('⚡ Applying Dart fixes (const, imports)...');

  final fixResult = await Process.run(
    'dart',
    ['fix', '--apply', 'lib'],
    runInShell: true,
  );

  stdout.write(fixResult.stdout);
  stderr.write(fixResult.stderr);

  if (fixResult.exitCode != 0) {
    print('❌ dart fix failed');
    exit(fixResult.exitCode);
  }

  // print('🎉 All files in lib/ reformatted & fixed successfully');
}
