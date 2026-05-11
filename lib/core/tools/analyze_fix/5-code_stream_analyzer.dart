// tools/5-code_stream_analyzer.dart
import 'dart:io';


Future<String> runCodeStreamAnalyzer({required bool autoFix, bool printOutput = true}) async {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    return 'no lib';
  }

  int violations = 0;
  final reports = <String>[];
  final methodsFound = <String>[];

  final structuralRules = {
    'cubit': 'BaseCubit',
    'repo': 'BaseRepo',
    'repository': 'BaseRepo',
  };

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path;
    final lowName = path.split(Platform.pathSeparator).last.toLowerCase();
    String content = entity.readAsStringSync();

    // Structural rules
    for (final entry in structuralRules.entries) {
      if (lowName.contains(entry.key)) {
        final match = RegExp(r'class\s+(\w+)\s+extends\s+(\w+)').firstMatch(content);
        if (match == null || match.group(2) != entry.value) {
          violations++;
          final msg = '🚫 $path → should extend ${entry.value}';
          reports.add(msg);
          // if (printOutput) print(msg);
          if (autoFix && entry.key == 'cubit') {
            final fixed = content.replaceFirstMapped(RegExp(r'extends\s+Cubit\s*<'), (m) => 'extends BaseCubit<');
            if (fixed != content) {
              entity.writeAsStringSync(fixed);
              reports.add('🔧 Auto-fixed extends in $path (verify)');
            }
          }
        }
      }
    }

    // ScrollController -> require mixin
    if (content.contains('ScrollController')) {
      final hasMixin = RegExp(r'with\s+AutoScrollControllerMixin').hasMatch(content) ||
          RegExp(r'implements\s+AutoScrollControllerMixin').hasMatch(content);
      if (!hasMixin) {
        violations++;
        final msg = '🚫 $path → uses ScrollController but missing AutoScrollControllerMixin';
        reports.add(msg);
        // if (printOutput) print(msg);
        if (autoFix) {
          final stateMatch = RegExp(r'class\s+(\w+)\s+extends\s+State<[^>]+>').firstMatch(content);
          if (stateMatch != null) {
            final stateClass = stateMatch.group(1)!;
            final pattern = RegExp(r'class\s+' + RegExp.escape(stateClass) + r'\s+extends\s+State<[^>]+>');
            final replacement = 'class $stateClass extends State with AutoScrollControllerMixin';
            final newContent = content.replaceFirst(pattern, replacement);
            if (newContent != content) {
              entity.writeAsStringSync(newContent);
              reports.add('🔧 Attempted to add AutoScrollControllerMixin to $path (review)');
            }
          }
        }
      }
    }

    // Method & function extraction with line numbers
    final lines = content.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final methodMatch = RegExp(r'^\s*(?:Future<.*?>|Stream<.*?>|void|int|double|String|bool|dynamic|\w+)\s+(\w+)\s*\([^)]*\)\s*(?:\{|;)\s*$').firstMatch(line);
      if (methodMatch != null) {
        String className = 'top-level';
        for (int j = i - 1; j >= 0; j--) {
          final cls = RegExp(r'^\s*class\s+(\w+)').firstMatch(lines[j]);
          if (cls != null) {
            className = cls.group(1)!;
            break;
          }
        }
        methodsFound.add('$path → $className → ${methodMatch.group(1)}() [line ${i + 1}]');
      }
    }
  }


  if (printOutput) {
    print('\n===== CODE STREAM ANALYZER REPORT =====');
    if (reports.isEmpty) {
      print('No structural issues found ✅');
    } else {
      for (final r in reports) {
        print(r);
      }
    }
    // print('\n----- Methods Found (path → class → method [line]) -----');
    // for (final m in methodsFound) print(m);
    print('\nTotal violations: $violations');
    print('=======================================');
  }

  return 'violations:$violations';
}

