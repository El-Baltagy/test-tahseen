// ─────────────────────────────────────────────────────────────────────────────
// main_localization.dart
// Interactive entry-point for the full Localization Automation Suite.
//
// Usage:
//   dart run lib/core/tools/localization/main_localization.dart
//
// Or run individual sub-commands directly:
//   dart run lib/core/tools/localization/main_localization.dart csv   <csv_path>
//   dart run lib/core/tools/localization/main_localization.dart sync  [--fix] [--sort]
//   dart run lib/core/tools/localization/main_localization.dart unused [--delete]
//   dart run lib/core/tools/localization/main_localization.dart key   "Login Screen Title"
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

// Sub-scripts are imported as libraries and invoked via their main() functions.
import 'csv_to_arb.dart' as csv_tool;
import 'sync_languages.dart' as sync_tool;
import 'detect_unused_keys.dart' as unused_tool;
import 'generate_key.dart' as key_tool;

const _cyan   = '\x1B[36m';
const _green  = '\x1B[32m';
const _yellow = '\x1B[33m';
const _red    = '\x1B[31m';
const _bold   = '\x1B[1m';
const _reset  = '\x1B[0m';

void main(List<String> args) async {
  // ── Direct sub-command ───────────────────────────────────────────────────────
  if (args.isNotEmpty) {
    await _dispatch(args);
    return;
  }

  // ── Interactive menu ─────────────────────────────────────────────────────────
  _printBanner();

  while (true) {
    _printMenu();
    stdout.write('$_bold> Choose an option: $_reset');
    final input = stdin.readLineSync()?.trim() ?? '';

    switch (input) {
      case '1':
        await _runCsvToArb();
      case '2':
        await _runSync();
      case '3':
        await _runUnused();
      case '4':
        await _runGenerateKey();
      case '5':
        await _runAll();
      case '0':
      case 'q':
      case 'exit':
        print('\n👋 Bye!\n');
        exit(0);
      default:
        print('$_red❌ Unknown option: "$input"$_reset');
    }

    print('');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu Handlers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _runCsvToArb() async {
  print('\n$_cyan📋 CSV → ARB Converter$_reset');
  stdout.write('   Path to CSV file: ');
  final csvPath = stdin.readLineSync()?.trim() ?? '';
  if (csvPath.isEmpty) { print('$_red❌ No path provided.$_reset'); return; }

  stdout.write('   Output dir (default: lib/l10n): ');
  final outDir = stdin.readLineSync()?.trim() ?? '';

  final callArgs = [csvPath, if (outDir.isNotEmpty) outDir];
  print('');
  csv_tool.main(callArgs);
}

Future<void> _runSync() async {
  print('\n$_cyan🔄 Sync Languages$_reset');
  stdout.write('   l10n dir (default: lib/l10n): ');
  final dir = stdin.readLineSync()?.trim() ?? '';

  stdout.write('   Reference locale (default: en): ');
  final ref = stdin.readLineSync()?.trim() ?? '';

  stdout.write('   Auto-fix missing keys? [y/N]: ');
  final fix = (stdin.readLineSync()?.trim().toLowerCase() ?? '') == 'y';

  stdout.write('   Sort ARB files? [y/N]: ');
  final sort = (stdin.readLineSync()?.trim().toLowerCase() ?? '') == 'y';

  final callArgs = [
    if (dir.isNotEmpty) dir,
    if (ref.isNotEmpty) '--ref=$ref',
    if (fix) '--fix',
    if (sort) '--sort',
  ];
  print('');
  sync_tool.main(callArgs);
}

Future<void> _runUnused() async {
  print('\n$_cyan🗑  Detect Unused Keys$_reset');
  stdout.write('   l10n dir (default: lib/l10n): ');
  final dir = stdin.readLineSync()?.trim() ?? '';

  stdout.write('   Reference locale (default: en): ');
  final ref = stdin.readLineSync()?.trim() ?? '';

  stdout.write('   Delete unused keys? [y/N]: ');
  final del = (stdin.readLineSync()?.trim().toLowerCase() ?? '') == 'y';

  final callArgs = [
    if (dir.isNotEmpty) dir,
    if (ref.isNotEmpty) '--ref=$ref',
    if (del) '--delete',
  ];
  print('');
  unused_tool.main(callArgs);
}

Future<void> _runGenerateKey() async {
  print('\n$_cyan🔑 Auto-generate Key$_reset');
  while (true) {
    stdout.write('   Enter text (or blank to stop): ');
    final text = stdin.readLineSync()?.trim() ?? '';
    if (text.isEmpty) break;
    key_tool.main([text]);
  }
}

Future<void> _runAll() async {
  print('\n$_bold$_yellow⚙️  Running full pipeline...$_reset\n');

  // 1. CSV → ARB
  stdout.write('1️⃣  Path to CSV (skip with Enter): ');
  final csvPath = stdin.readLineSync()?.trim() ?? '';
  if (csvPath.isNotEmpty) csv_tool.main([csvPath]);

  // 2. Sync
  print('\n2️⃣  Syncing languages...');
  sync_tool.main(['--fix', '--sort']);

  // 3. Unused
  print('\n3️⃣  Detecting unused keys...');
  unused_tool.main([]);

  print('\n$_green✅ Full pipeline complete!$_reset');
}

// ─────────────────────────────────────────────────────────────────────────────
// Direct dispatch (non-interactive)
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _dispatch(List<String> args) async {
  final cmd  = args.first.toLowerCase();
  final rest = args.skip(1).toList();

  switch (cmd) {
    case 'csv':
      csv_tool.main(rest);
    case 'sync':
      sync_tool.main(rest);
    case 'unused':
      unused_tool.main(rest);
    case 'key':
      key_tool.main(rest);
    case 'all':
      // Non-interactive pipeline: csv <path> + sync --fix + unused
      if (rest.isNotEmpty) csv_tool.main(rest);
      sync_tool.main(['--fix', '--sort']);
      unused_tool.main([]);
    default:
      print('$_red❌ Unknown command: "$cmd"$_reset');
      _printUsage();
      exit(1);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UI helpers
// ─────────────────────────────────────────────────────────────────────────────

void _printBanner() {
  print('''
$_bold$_cyan
╔══════════════════════════════════════════════════════╗
║       🌍  Localization Automation Suite  🌍          ║
║              Flutter ARB Tools — Tahseen             ║
╚══════════════════════════════════════════════════════╝
$_reset''');
}

void _printMenu() {
  print('''${_bold}Options:$_reset
  ${_green}1${_reset}  📋  CSV → ARB  (convert Excel/Google Sheets export)
  ${_green}2${_reset}  🔄  Sync Languages  (find missing / extra keys)
  ${_green}3${_reset}  🗑   Detect Unused Keys  (clean dead translations)
  ${_green}4${_reset}  🔑  Generate Key  (text → snake_case key)
  ${_green}5${_reset}  ⚡  Run Full Pipeline  (all steps in sequence)
  ${_yellow}0${_reset}  🚪  Exit
''');
}

void _printUsage() {
  print('''
Usage:
  dart run lib/core/tools/localization/main_localization.dart           # interactive
  dart run lib/core/tools/localization/main_localization.dart csv   <csv_path> [out_dir]
  dart run lib/core/tools/localization/main_localization.dart sync  [dir] [--fix] [--sort] [--ref=en]
  dart run lib/core/tools/localization/main_localization.dart unused [dir] [--delete] [--yes]
  dart run lib/core/tools/localization/main_localization.dart key   "My Text Here"
  dart run lib/core/tools/localization/main_localization.dart all   [csv_path]
''');
}
