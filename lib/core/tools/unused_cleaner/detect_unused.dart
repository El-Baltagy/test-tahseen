import 'dart:io';

/// [ignoring loop detection]
void main() {
  final root = Directory.current.path;
  if (!File('$root/pubspec.yaml').existsSync()) {
    print('❌ Error: Run this from the project root.');
    exit(1);
  }

  print('🔍 Scanning for unused files...');
  
  final exclusions = _loadExclusions(root);
  final packageName = _getPackageName(root);
  final declaredFonts = _getDeclaredFonts(root);

  // 1. Find all Dart files in lib/
  final libFiles = Directory('$root/lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  // 2. Map imports
  final importedFiles = <String>{};
  for (final file in libFiles) {
    final content = file.readAsStringSync();
    final matches = RegExp(r"(import|export)\s+'([^']+)'").allMatches(content);
    for (final m in matches) {
      final uri = m.group(2)!;
      if (uri.startsWith('package:$packageName/')) {
        importedFiles.add('lib/${uri.substring(packageName.length + 9)}');
      } else if (!uri.startsWith('package:') && !uri.startsWith('dart:')) {
        final relPath = _resolveRelative(file.path, uri, root);
        if (relPath != null) importedFiles.add(relPath);
      }
    }
  }

  // 3. Detect Unused Dart
  final unusedDart = libFiles
      .map((f) => f.path.replaceFirst('$root/', '').replaceAll('\\', '/'))
      .where((path) {
        if (path == 'lib/main.dart' || importedFiles.contains(path)) return false;
        if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) return false;
        return !_isExcluded(path, exclusions);
      }).toList();

  // 4. Detect Unused Assets
  final assets = Directory('$root/assets').existsSync() 
      ? Directory('$root/assets').listSync(recursive: true).whereType<File>().toList()
      : [];
  
  final fullCode = libFiles.map((f) => f.readAsStringSync()).join('\n');
  final unusedAssets = assets
      .map((f) => f.path.replaceFirst('$root/', '').replaceAll('\\', '/'))
      .where((path) {
        if (declaredFonts.contains(path)) return false;
        final name = path.split('/').last;
        return !fullCode.contains(path) && !fullCode.contains(name) && !_isExcluded(path, exclusions);
      }).toList();

  _saveReport(root, unusedDart, unusedAssets);
}

String? _resolveRelative(String from, String uri, String root) {
  final parts = from.replaceFirst('$root/', '').split('/')..removeLast();
  for (final segment in uri.split('/')) {
    if (segment == '..') { if (parts.isNotEmpty) parts.removeLast(); }
    else if (segment != '.') parts.add(segment);
  }
  return parts.join('/');
}

List<String> _loadExclusions(String root) {
  final f = File('$root/unused_cleaner_config.yaml');
  if (!f.existsSync()) return [];
  return f.readAsLinesSync().where((l) => l.startsWith('-')).map((l) => l.replaceFirst('-', '').trim()).toList();
}

bool _isExcluded(String path, List<String> exclusions) {
  return exclusions.any((e) => path.startsWith(e));
}

String _getPackageName(String root) {
  return File('$root/pubspec.yaml').readAsLinesSync().firstWhere((l) => l.startsWith('name:')).split(':').last.trim();
}

Set<String> _getDeclaredFonts(String root) {
  final content = File('$root/pubspec.yaml').readAsStringSync();
  return RegExp(r'asset:\s+([^\s]+)').allMatches(content).map((m) => m.group(1)!).toSet();
}

void _saveReport(String root, List<String> dart, List<String> assets) {
  final out = File('$root/unused_files_report.txt');
  final buffer = StringBuffer('# Unused Files Report\n');
  buffer.writeln('\n# Dart Files (${dart.length})');
  dart.forEach(buffer.writeln);
  buffer.writeln('\n# Assets (${assets.length})');
  assets.forEach(buffer.writeln);
  out.writeAsStringSync(buffer.toString());
  print('✅ Found ${dart.length} unused Dart files and ${assets.length} assets.');
  print('📄 Report saved to: unused_files_report.txt');
}
