// ─────────────────────────────────────────────────────────────────────────────
// detect_unused_keys.dart
// Scans Dart source files and finds ARB keys that are never referenced in code.
//
// Usage:
//   dart run lib/core/tools/localization/detect_unused_keys.dart [l10n_dir] [--ref=en] [--delete]
//
// Options:
//   --ref=<locale>   Which ARB file to use as the source of truth (default: en)
//   --delete         Remove unused keys from ALL .arb files after confirmation
//   --yes            Skip confirmation prompt (use with --delete in CI)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  // ── Args ─────────────────────────────────────────────────────────────────────
  final positional = args.where((a) => !a.startsWith('--')).toList();
  final l10nDir   = positional.isNotEmpty ? positional.first : 'lib/l10n';
  final refLocale = _flag(args, 'ref') ?? 'en';
  final doDelete  = args.contains('--delete');
  final autoYes   = args.contains('--yes');

  final root = Directory.current.path;
  if (!File('$root/pubspec.yaml').existsSync()) {
    print('❌ Run this script from the project root (where pubspec.yaml is).');
    exit(1);
  }

  // ── Load reference ARB ───────────────────────────────────────────────────────
  final l10nDirectory = Directory('$root/$l10nDir');
  if (!l10nDirectory.existsSync()) {
    print('❌ l10n directory not found: $l10nDir');
    exit(1);
  }

  final arbFiles = l10nDirectory
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .toList();

  if (arbFiles.isEmpty) {
    print('❌ No .arb files found in $l10nDir');
    exit(1);
  }

  final refFile = arbFiles.firstWhere(
    (f) => f.path.contains('app_$refLocale.arb'),
    orElse: () {
      print('❌ Reference file app_$refLocale.arb not found.');
      exit(1);
    },
  );

  final refJson     = jsonDecode(refFile.readAsStringSync()) as Map<String, dynamic>;
  final allArbKeys  = refJson.keys.where((k) => !k.startsWith('@')).toSet();

  print('\n🔑 Loaded ${allArbKeys.length} keys from app_$refLocale.arb');
  print('─' * 60);

  // ── Collect all Dart source ──────────────────────────────────────────────────
  print('🔍 Scanning lib/ for key usages...');
  final dartFiles = Directory('$root/lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      // Skip the localization tool files themselves
      .where((f) => !f.path.contains('core/tools/localization'))
      .toList();

  final fullSource = dartFiles.map((f) => f.readAsStringSync()).join('\n');

  // ── Detect unused keys ───────────────────────────────────────────────────────
  // A key is "used" if its name appears anywhere in the Dart source.
  // Common patterns:  S.of(ctx).login_title  |  l10n.loginTitle  | 'login_title'
  // We match the snake_case key AND its lowerCamelCase variant.
  final unusedKeys = <String>[];
  final usedKeys   = <String>[];

  for (final key in allArbKeys) {
    final camel = _toCamelCase(key);
    if (fullSource.contains(key) || fullSource.contains(camel)) {
      usedKeys.add(key);
    } else {
      unusedKeys.add(key);
    }
  }

  unusedKeys.sort();
  usedKeys.sort();

  // ── Print report ─────────────────────────────────────────────────────────────
  print('\n✅ Used keys   : ${usedKeys.length}');
  print('🗑  Unused keys : ${unusedKeys.length}');

  if (unusedKeys.isEmpty) {
    print('\n🎉 No unused keys found. All clean!');
    return;
  }

  print('\n🗑  Unused keys:');
  for (final k in unusedKeys) {
    print('   - $k');
  }

  // ── Save report ──────────────────────────────────────────────────────────────
  final reportFile = File('$root/unused_arb_keys_report.txt');
  final buffer = StringBuffer('# Unused ARB Keys Report\n');
  buffer.writeln('Reference locale : $refLocale');
  buffer.writeln('Scanned Dart files: ${dartFiles.length}');
  buffer.writeln('Unused keys (${unusedKeys.length}):');
  for (final k in unusedKeys) buffer.writeln('  - $k');
  reportFile.writeAsStringSync(buffer.toString());
  print('\n📄 Report saved → unused_arb_keys_report.txt');

  // ── Optional delete ───────────────────────────────────────────────────────────
  if (!doDelete) {
    print('\n💡 Run with --delete to remove unused keys from all .arb files.');
    return;
  }

  // Confirm
  if (!autoYes) {
    stdout.write('\n⚠️  Delete ${unusedKeys.length} keys from all .arb files? [y/N]: ');
    final input = stdin.readLineSync(encoding: utf8)?.trim().toLowerCase() ?? '';
    if (input != 'y') {
      print('🚫 Aborted. No files modified.');
      return;
    }
  }

  // Remove from every ARB file
  for (final file in arbFiles) {
    final json   = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    int removed  = 0;
    for (final key in unusedKeys) {
      if (json.remove(key) != null) removed++;
      json.remove('@$key'); // also remove any associated @metadata
    }
    _writeArb(file, json);
    print('🗑  Removed $removed keys from ${file.path.split(Platform.pathSeparator).last}');
  }

  reportFile.deleteSync();
  print('\n✨ Cleanup complete. Unused keys removed from all .arb files.');
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// login_screen_title → loginScreenTitle
String _toCamelCase(String snake) {
  final parts = snake.split('_');
  return parts.first +
      parts.skip(1).map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}').join();
}

String? _flag(List<String> args, String name) {
  final match = args.firstWhere(
    (a) => a.startsWith('--$name='),
    orElse: () => '',
  );
  if (match.isEmpty) return null;
  return match.split('=').skip(1).join('=');
}

void _writeArb(File file, Map<String, dynamic> json) {
  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(json));
}
