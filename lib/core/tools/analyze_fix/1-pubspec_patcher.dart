// tools/1-pubspec_patcher.dart
import 'dart:io';


final Map<String, String> requiredDependencies = {
  'rxdart': '^0.27.0',
  'flutter_bloc': '^8.2.0',
  'dio': '^6.1.0',
  'stack_trace': '^1.11.0',
  'dartz': '^0.10.1'
};

final Map<String, String> requiredDevDependencies = {
  'build_runner': '^2.4.6',
  'json_serializable': '^6.7.0'
};

Future<String> runPubspecPatcher({bool printOutput = true}) async {
  // final spinner = Spinner('🧩 Patching pubspec.yaml...');
  // spinner.start();

  final file = File('pubspec.yaml');
  if (!file.existsSync()) {
    // spinner.stop('⚠️ pubspec.yaml not found.');
    return 'pubspec.yaml not found';
  }

  final lines = file.readAsLinesSync();

  // find or create 'dependencies:' and 'dev_dependencies:' sections
  var depsIndex = lines.indexWhere((l) => l.trim() == 'dependencies:');
  if (depsIndex == -1) {
    // try to insert before environment or at end
    var insertAt = lines.indexWhere((l) => l.trim().startsWith('environment:'));
    if (insertAt == -1) insertAt = lines.length;
    lines.insert(insertAt, 'dependencies:');
    depsIndex = lines.indexWhere((l) => l.trim() == 'dependencies:');
  }

  var devDepsIndex = lines.indexWhere((l) => l.trim() == 'dev_dependencies:');

  Map<String, String> currentDeps = {};
  Map<String, String> currentDevDeps = {};

  for (int i = depsIndex + 1; i < (devDepsIndex != -1 ? devDepsIndex : lines.length); i++) {
    final line = lines[i].trim();
    if (line.contains(':')) {
      final parts = line.split(':');
      currentDeps[parts[0].trim()] = parts.sublist(1).join(':').trim();
    }
  }

  if (devDepsIndex != -1) {
    for (int i = devDepsIndex + 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.contains(':')) {
        final parts = line.split(':');
        currentDevDeps[parts[0].trim()] = parts.sublist(1).join(':').trim();
      }
    }
  }

  bool updated = false;
  requiredDependencies.forEach((k, v) {
    if (!currentDeps.containsKey(k)) {
      lines.insert(depsIndex + 1, '  $k: $v');
      updated = true;
      if (printOutput) print('✅ Added dependency: $k: $v');
    }
  });

  if (devDepsIndex == -1) {
    lines.add('\ndev_dependencies:');
    devDepsIndex = lines.indexWhere((l) => l.trim() == 'dev_dependencies:');
  }

  requiredDevDependencies.forEach((k, v) {
    if (!currentDevDeps.containsKey(k)) {
      lines.add('  $k: $v');
      updated = true;
      if (printOutput) print('✅ Added dev dependency: $k: $v');
    }
  });

  if (updated) {
    file.writeAsStringSync(lines.join('\n'));
    if (printOutput) print('📦 Running flutter pub get...');
    final result = await Process.run('flutter', ['pub', 'get']);
    if (printOutput) {
      stdout.write(result.stdout);
      stderr.write(result.stderr);
    }
  } else {
    if (printOutput) print('🎉 All required dependencies already exist.');
  }

  // spinner.stop('✅ Pubspec patching completed.');
  return updated ? 'updated' : 'nothing';
}

Future<void> main(List<String> args) async {
  await runPubspecPatcher();
}
