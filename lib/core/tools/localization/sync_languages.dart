// ─────────────────────────────────────────────────────────────────────────────
// sync_languages.dart
// Compares all .arb files in lib/l10n and reports missing / extra keys
// relative to the reference locale (default: en).
//
// Usage:
//   dart run lib/core/tools/localization/sync_languages.dart [l10n_dir] [--ref=en] [--fix]
//
// Options:
//   --ref=<locale>   Reference locale (default: en)
//   --fix            Auto-add missing keys as empty strings in target files
//   --sort           Sort all ARB files alphabetically while at it
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  // ── Args ─────────────────────────────────────────────────────────────────────
  final positional = args.where((a) => !a.startsWith('--')).toList();
  final l10nDir = positional.isNotEmpty ? positional.first : 'lib/l10n';
  final refLocale = _flag(args, 'ref') ?? 'en';
  final fix = args.contains('--fix');
  final sort = args.contains('--sort');

  final root = Directory.current.path;
  final dir = Directory('$root/$l10nDir');

  if (!dir.existsSync()) {
    print('❌ l10n directory not found: $l10nDir');
    print('   Run csv_to_arb.dart first, or set the correct path.');
    exit(1);
  }

  // ── Load ARB files ───────────────────────────────────────────────────────────
  final arbFiles = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.arb')).toList();

  if (arbFiles.isEmpty) {
    print('❌ No .arb files found in $l10nDir');
    exit(1);
  }

  // Map<locale, Map<key, value>>
  final Map<String, Map<String, String>> locales = {};

  for (final file in arbFiles) {
    final locale = _localeFromPath(file.path);
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    locales[locale] = {
      for (final e in json.entries)
        if (!e.key.startsWith('@')) e.key: e.value.toString(),
    };
  }

  if (!locales.containsKey(refLocale)) {
    print('❌ Reference locale "$refLocale" not found.');
    print('   Available: ${locales.keys.join(', ')}');
    exit(1);
  }

  final refKeys = locales[refLocale]!.keys.toSet();
  print('\n🔍 Reference locale: $refLocale  (${refKeys.length} keys)');
  print('─' * 60);

  bool allGood = true;

  for (final locale in locales.keys.where((l) => l != refLocale)) {
    final targetKeys = locales[locale]!.keys.toSet();

    final missing = refKeys.difference(targetKeys);
    final extra = targetKeys.difference(refKeys);

    print('\n📦 Locale: $locale');

    if (missing.isEmpty && extra.isEmpty) {
      print('  ✅ Perfect sync — no issues found.');
      continue;
    }

    allGood = false;

    if (missing.isNotEmpty) {
      print('  ❌ Missing in $locale (${missing.length}):');
      for (final k in missing.toList()..sort()) {
        print('       - $k');
      }
    }

    if (extra.isNotEmpty) {
      print('  ⚠️  Extra in $locale (${extra.length}):');
      for (final k in extra.toList()..sort()) {
        print('       + $k');
      }
    }

    // ── --fix: add missing keys with empty string ───────────────────────────
    if (fix && missing.isNotEmpty) {
      final targetFile = arbFiles.firstWhere(
        (f) => _localeFromPath(f.path) == locale,
      );
      final json = jsonDecode(targetFile.readAsStringSync()) as Map<String, dynamic>;

      for (final key in missing) {
        json[key] = ''; // empty — translator fills in
      }

      _writeArb(targetFile, locale, json, sort: sort || true);
      print('  🔧 Added ${missing.length} missing key(s) to app_$locale.arb');
    }
  }

  // ── --sort: sort reference file too ─────────────────────────────────────────
  if (sort) {
    final refFile = arbFiles.firstWhere(
      (f) => _localeFromPath(f.path) == refLocale,
    );
    final json = jsonDecode(refFile.readAsStringSync()) as Map<String, dynamic>;
    _writeArb(refFile, refLocale, json, sort: true);
    print('\n🗂  All ARB files sorted alphabetically.');
  }

  print('\n' + '─' * 60);
  if (allGood) {
    print('🎉 All locales are in sync!');
  } else if (fix) {
    print('🔧 Missing keys added. Fill in translations and re-run without --fix.');
  } else {
    print('💡 Tip: Run with --fix to automatically add missing keys.');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _localeFromPath(String path) {
  // app_en.arb → en  |  app_ar.arb → ar
  final name = path.split(Platform.pathSeparator).last;
  return name.replaceFirst('app_', '').replaceFirst('.arb', '');
}

String? _flag(List<String> args, String name) {
  final match = args.firstWhere(
    (a) => a.startsWith('--$name='),
    orElse: () => '',
  );
  if (match.isEmpty) return null;
  return match.split('=').skip(1).join('=');
}

void _writeArb(File file, String locale, Map<String, dynamic> json, {bool sort = false}) {
  // Keep @@ entries first, then sort the rest
  final metaEntries = json.entries.where((e) => e.key.startsWith('@')).toList();
  final dataEntries = json.entries.where((e) => !e.key.startsWith('@')).toList();

  if (sort) dataEntries.sort((a, b) => a.key.compareTo(b.key));

  final ordered = <String, dynamic>{
    '@@locale': locale,
    for (final e in metaEntries) e.key: e.value,
    for (final e in dataEntries) e.key: e.value,
  };

  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(ordered));
}
