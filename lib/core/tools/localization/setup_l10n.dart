// ─────────────────────────────────────────────────────────────────────────────
// setup_l10n.dart
// One-shot script that fully wires flutter gen-l10n into your project:
//
//  ✅  Adds flutter_localizations + intl to pubspec.yaml
//  ✅  Adds `generate: true` under the flutter: section
//  ✅  Creates l10n.yaml in the project root
//  ✅  Creates lib/l10n/ with starter ARB files (if none exist)
//  ✅  Runs `flutter pub get`
//  ✅  Runs `flutter gen-l10n`
//  ✅  Prints how to use AppLocalizations in your app
//
// Usage:
//   dart run lib/core/tools/localization/setup_l10n.dart [options]
//
// Options:
//   --arb-dir=<path>       Where .arb files live  (default: lib/l10n)
//   --template=<file>      Template ARB filename   (default: app_en.arb)
//   --output=<file>        Output Dart filename    (default: app_localizations.dart)
//   --locales=en,ar,fr     Locales to scaffold ARB stubs for (default: en,ar)
//   --dry-run              Print what would happen but don't change anything
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';

// ─── ANSI colours ────────────────────────────────────────────────────────────
const _g = '\x1B[32m'; // green
const _y = '\x1B[33m'; // yellow
const _r = '\x1B[31m'; // red
const _c = '\x1B[36m'; // cyan
const _b = '\x1B[1m';  // bold
const _x = '\x1B[0m';  // reset

void main(List<String> args) async {
  // ── Parse args ──────────────────────────────────────────────────────────────
  final arbDir    = _flag(args, 'arb-dir')  ?? 'lib/l10n';
  final template  = _flag(args, 'template') ?? 'app_en.arb';
  final output    = _flag(args, 'output')   ?? 'app_localizations.dart';
  final locales   = (_flag(args, 'locales') ?? 'en,ar').split(',').map((e) => e.trim()).toList();
  final dryRun    = args.contains('--dry-run');

  _banner();

  final root = Directory.current.path;

  // Guard: must be run from project root
  if (!File('$root/pubspec.yaml').existsSync()) {
    _err('Run this from the Flutter project root (where pubspec.yaml is).');
    exit(1);
  }

  if (dryRun) _warn('DRY RUN — no files will be modified.\n');

  // ── Steps ───────────────────────────────────────────────────────────────────
  await _step1_pubspec(root, dryRun);
  await _step2_l10nYaml(root, arbDir, template, output, locales, dryRun);
  await _step3_arbStubs(root, arbDir, locales, template, dryRun);
  await _step4_pubGet(root, dryRun);
  await _step5_genL10n(root, dryRun);
  _step6_usage(output, arbDir);
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — patch pubspec.yaml
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _step1_pubspec(String root, bool dry) async {
  _header('1/5  Patching pubspec.yaml');

  final file    = File('$root/pubspec.yaml');
  var   content = file.readAsStringSync();
  bool  changed = false;

  // 1a. Add flutter_localizations under dependencies:
  if (!content.contains('flutter_localizations')) {
    content = content.replaceFirst(
      RegExp(r'(dependencies:\s*\n\s*flutter:\s*\n\s*sdk:\s*flutter)'),
      '\$1\n\n  flutter_localizations:\n    sdk: flutter',
    );
    _ok('Added flutter_localizations dependency');
    changed = true;
  } else {
    _skip('flutter_localizations already present');
  }

  // 1b. Add intl
  if (!content.contains(RegExp(r'^\s*intl:', multiLine: true))) {
    // Insert after flutter_localizations block
    content = content.replaceFirst(
      'flutter_localizations:\n    sdk: flutter',
      'flutter_localizations:\n    sdk: flutter\n  intl: ^0.20.0',
    );
    _ok('Added intl: ^0.20.0 dependency');
    changed = true;
  } else {
    _skip('intl already present');
  }

  // 1c. Add generate: true under flutter: section
  if (!content.contains('generate: true')) {
    // Find "flutter:\n" section and insert generate: true
    content = content.replaceFirstMapped(
      RegExp(r'(^flutter:\s*\n)', multiLine: true),
      (m) => '${m.group(1)}  generate: true\n',
    );
    _ok('Added `generate: true` to flutter: section');
    changed = true;
  } else {
    _skip('generate: true already set');
  }

  if (changed && !dry) {
    file.writeAsStringSync(content);
    _ok('pubspec.yaml saved ✓');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — create l10n.yaml
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _step2_l10nYaml(
  String root,
  String arbDir,
  String template,
  String output,
  List<String> locales,
  bool dry,
) async {
  _header('2/5  Creating l10n.yaml');

  final file = File('$root/l10n.yaml');

  if (file.existsSync()) {
    _skip('l10n.yaml already exists — skipping');
    return;
  }

  final content = '''
# Flutter localization configuration
# Docs: https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization

arb-dir: $arbDir
template-arb-file: $template
output-localization-file: $output

# Uncomment to suppress the @@locale key requirement in non-template files:
# require-resource-attributes: false

# Uncomment for nullable getter support:
# nullable-getter: false
''';

  if (!dry) file.writeAsStringSync(content);
  _ok('Created l10n.yaml');
  _detail('  arb-dir  : $arbDir');
  _detail('  template : $template');
  _detail('  output   : $output');
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — scaffold starter ARB files
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _step3_arbStubs(
  String root,
  String arbDir,
  List<String> locales,
  String template,
  bool dry,
) async {
  _header('3/5  Scaffolding ARB files in $arbDir/');

  final dir = Directory('$root/$arbDir');
  if (!dry && !dir.existsSync()) {
    dir.createSync(recursive: true);
    _ok('Created directory: $arbDir/');
  }

  // Starter keys for demonstration
  final starterTranslations = {
    'en': {
      'appName'        : 'My App',
      'loading'        : 'Loading...',
      'error_generic'  : 'Something went wrong',
      'retry_btn'      : 'Retry',
      'cancel_btn'     : 'Cancel',
      'save_btn'       : 'Save',
    },
    'ar': {
      'appName'        : 'تطبيقي',
      'loading'        : 'جارٍ التحميل...',
      'error_generic'  : 'حدث خطأ ما',
      'retry_btn'      : 'إعادة المحاولة',
      'cancel_btn'     : 'إلغاء',
      'save_btn'       : 'حفظ',
    },
  };

  for (final locale in locales) {
    final fileName  = 'app_$locale.arb';
    final filePath  = '$root/$arbDir/$fileName';
    final file      = File(filePath);

    if (file.existsSync()) {
      _skip('$fileName already exists — skipping');
      continue;
    }

    final translations = starterTranslations[locale] ?? {};
    final isTemplate   = fileName == template;

    final arb = <String, dynamic>{'@@locale': locale};

    for (final entry in translations.entries) {
      arb[entry.key] = entry.value;
      if (isTemplate) {
        arb['@${entry.key}'] = {'description': entry.key.replaceAll('_', ' ')};
      }
    }

    const encoder = JsonEncoder.withIndent('  ');
    if (!dry) file.writeAsStringSync(encoder.convert(arb));
    _ok('Created $fileName  (${translations.length} starter keys)');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — flutter pub get
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _step4_pubGet(String root, bool dry) async {
  _header('4/5  Running flutter pub get');

  if (dry) { _skip('[dry-run] Skipped'); return; }

  final result = await Process.run(
    'flutter', ['pub', 'get'],
    workingDirectory: root,
    runInShell: true,
  );

  if (result.exitCode == 0) {
    _ok('flutter pub get succeeded');
  } else {
    _err('flutter pub get failed:\n${result.stderr}');
    exit(1);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 5 — flutter gen-l10n
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _step5_genL10n(String root, bool dry) async {
  _header('5/5  Running flutter gen-l10n');

  if (dry) { _skip('[dry-run] Skipped'); return; }

  final result = await Process.run(
    'flutter', ['gen-l10n'],
    workingDirectory: root,
    runInShell: true,
  );

  if (result.exitCode == 0) {
    _ok('flutter gen-l10n succeeded — Dart classes generated!');

    // Show what was generated
    final genDir = Directory('$root/.dart_tool/flutter_gen/gen_l10n');
    if (genDir.existsSync()) {
      final files = genDir.listSync().whereType<File>().toList();
      _detail('  Generated ${files.length} file(s):');
      for (final f in files) {
        _detail('    → ${f.path.split(Platform.pathSeparator).last}');
      }
    }
  } else {
    _err('flutter gen-l10n failed:\n${result.stderr}');
    _warn('Make sure l10n.yaml is correct and .arb files are valid JSON.');
    exit(1);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 6 — print usage guide
// ─────────────────────────────────────────────────────────────────────────────
void _step6_usage(String output, String arbDir) {
  final className = output
      .replaceFirst('.dart', '')
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join();

  print('\n$_b$_c━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_x');
  print('$_b🎉 Setup complete! Here\'s how to use it:$_x\n');

  print('${_b}1. main.dart — add delegates & locales:$_x');
  print('''${_c}import 'package:flutter_gen/gen_l10n/$output';

MaterialApp(
  localizationsDelegates: $className.localizationsDelegates,
  supportedLocales:       $className.supportedLocales,
  home: MyHomePage(),
);$_x
''');

  print('${_b}2. Access translations anywhere:$_x');
  print('''${_c}// Option A: via context extension
Text(context.l10n.appName)

// Option B: direct lookup
$className.of(context)!.appName$_x
''');

  print('${_b}3. Add a context extension (optional but recommended):$_x');
  print('''${_c}// lib/core/extensions/l10n_extension.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/$output';

extension L10nX on BuildContext {
  $className get l10n => $className.of(this)!;
}$_x
''');

  print('${_b}4. After every ARB change, run:$_x');
  print('${_y}   flutter gen-l10n$_x\n');
  print('   Or set `generate: true` in pubspec.yaml to auto-run on `flutter run`.\n');

  print('${_b}5. Add translations:$_x');
  print('${_y}   dart run lib/core/tools/localization/main_localization.dart$_x\n');

  print('$_c━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_x\n');
}

// ─────────────────────────────────────────────────────────────────────────────
// UI helpers
// ─────────────────────────────────────────────────────────────────────────────
void _banner() {
  print('''
$_b$_c
╔══════════════════════════════════════════════════════╗
║      ⚙️   Flutter gen-l10n Setup Script   ⚙️         ║
║          Automatic localization wiring               ║
╚══════════════════════════════════════════════════════╝
$_x''');
}

void _header(String msg) => print('\n$_b$_y▶ $msg$_x');
void _ok(String msg)     => print('  $_g✅ $msg$_x');
void _skip(String msg)   => print('  $_c⏭  $msg$_x');
void _warn(String msg)   => print('  $_y⚠️  $msg$_x');
void _err(String msg)    => print('  $_r❌ $msg$_x');
void _detail(String msg) => print('$_c$msg$_x');

String? _flag(List<String> args, String name) {
  final match = args.firstWhere(
    (a) => a.startsWith('--$name='),
    orElse: () => '',
  );
  return match.isEmpty ? null : match.split('=').skip(1).join('=');
}
