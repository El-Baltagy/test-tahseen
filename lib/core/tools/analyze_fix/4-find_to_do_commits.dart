import 'dart:io';


Future<void> getToDoCommits() async {
  final libDir = Directory('lib');

  if (!libDir.existsSync()) {
    print('❌ lib/ directory not found');
    exit(1);
  }

  final todoRegex = RegExp(r'///\s*ToDo[\s\S]*');

  print('🔍 Searching for /// ToDo (regex) in lib/...');

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    final lines = entity.readAsLinesSync();

    for (int i = 0; i < lines.length; i++) {
      if (todoRegex.hasMatch(lines[i])) {
        final lineNumber = i + 1;
        print('${entity.path}:$lineNumber → ${lines[i].trim()}');
      }
    }
  }

  print('✅ Search complete');
}
