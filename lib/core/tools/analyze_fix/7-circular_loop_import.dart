// tool/circular_import_detector.dart
//
// Usage: dart run tool/circular_import_detector.dart lib

import 'dart:io';


void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run tool/circular_import_detector.dart <scanDir>');
    exit(1);
  }

  final scanDir = Directory(args[0]);
  final dartFiles = scanDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  final Map<String, List<String>> graph = {};

  for (final file in dartFiles) {
    final content = file.readAsStringSync();
    final imports = RegExp(r"import\s+'([^']+)';")
        .allMatches(content)
        .map((m) => m.group(1)!)
        .where((p) => p.endsWith('.dart'))
        .toList();

    graph[file.path] = imports;
  }

  // DFS to detect cycles
  final visited = <String>{};
  final stack = <String>{};

  void dfs(String node) {
    if (stack.contains(node)) {
      print('⚠️ Circular import detected: $node');
      return;
    }
    if (visited.contains(node)) return;

    visited.add(node);
    stack.add(node);

    for (final dep in graph[node] ?? []) {
      final depPath = dartFiles
          .map((f) => f.path)
          .firstWhere((p) => p.endsWith(dep), orElse: () => '');
      if (depPath.isNotEmpty) dfs(depPath);
    }

    stack.remove(node);
  }

  for (final file in dartFiles) {
    dfs(file.path);
  }
}
