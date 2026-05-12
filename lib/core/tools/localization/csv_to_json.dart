// ─────────────────────────────────────────────────────────────────────────────
// csv_to_json.dart
// Converts a CSV file (exported from Excel / Google Sheets) into .json files.


import 'dart:convert';
import 'dart:io';

import 'generate_key.dart';

void main(List<String> args) {
  final csvPath = args.isNotEmpty ? args[0] : 'assets/l10n/translations.csv';
  final outputDir = args.length > 1 ? args[1] : 'assets/l10n';

  final csvFile = File(csvPath);
  if (!csvFile.existsSync()) {
    print('❌ CSV file not found: $csvPath');
    exit(1);
  }

  print('📂 Reading CSV: $csvPath');
  final lines = csvFile.readAsLinesSync(encoding: utf8).where((l) => l.trim().isNotEmpty).toList();

  if (lines.length < 2) {
    print('❌ CSV must have a header row and at least one data row.');
    exit(1);
  }

  // ── Parse header ────────────────────────────────────────────────────────────
  final header = _splitCsvLine(lines.first);
  if (header.length < 2) {
    print('❌ CSV must have at least 2 columns: key + one language.');
    exit(1);
  }

  // First column is always "key", rest are language codes
  final langCodes = header.skip(1).toList(); // e.g. ['en', 'ar']
  print('🌍 Detected languages: ${langCodes.join(', ')}');

  // ── Build per-language maps ──────────────────────────────────────────────────
  // { 'en': { 'login_title': 'Login', ... }, 'ar': { ... } }
  final Map<String, Map<String, String>> langMaps = {
    for (final lang in langCodes) lang: {},
  };

  int autoKeyCount = 0;
  int skipped = 0;

  Map<String, int> missingCounts = {for (final lang in langCodes) lang: 0};

  for (final line in lines.skip(1)) {
    final cols = _splitCsvLine(line);
    if (cols.isEmpty) continue;

    // Raw key from column 0 — auto-generate if blank
    String rawKey = cols[0].trim();
    if (rawKey.isEmpty) {
      // Use English text (col 1) to generate key
      final enText = cols.length > 1 ? cols[1].trim() : '';
      if (enText.isEmpty) {
        skipped++;
        continue;
      }
      rawKey = toSnakeCase(enText);
      autoKeyCount++;
    } else {
      rawKey = toSnakeCase(rawKey); // normalise existing keys too
    }

    for (int i = 0; i < langCodes.length; i++) {
      final lang = langCodes[i];
      final colIndex = i + 1;
      final value = colIndex < cols.length ? cols[colIndex].trim() : '';
      
      // Always add the key to guarantee perfect synchronization across all files
      langMaps[lang]![rawKey] = value;

      if (value.isEmpty) {
        missingCounts[lang] = missingCounts[lang]! + 1;
      }
    }
  }

  // ── Write json files ──────────────────────────────────────────────────────────
  final outDirectory = Directory(outputDir);
  if (!outDirectory.existsSync()) {
    outDirectory.createSync(recursive: true);
    print('📁 Created output directory: $outputDir');
  }

  for (final lang in langCodes) {
    final entries = langMaps[lang]!;
    final json = _buildArb(lang, entries);
    final outPath = '$outputDir/app_$lang.json';
    File(outPath).writeAsStringSync(json, encoding: utf8);
    print('✅ Written ${entries.length} keys → $outPath');
    
    if (missingCounts[lang]! > 0) {
      print('   ⚠️  $lang is missing ${missingCounts[lang]} translations (Added as empty strings).');
    }
  }

  if (autoKeyCount > 0) print('🔑 Auto-generated $autoKeyCount key(s) from text.');
  if (skipped > 0) print('⚠️  Skipped $skipped row(s) with no key and no text.');
  print('\n Done! All json files are perfectly synced and ready in: $outputDir');
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Produces a formatted JSON string with @@locale and sorted keys.
String _buildArb(String locale, Map<String, String> entries) {
  final sorted = Map.fromEntries(
    entries.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );

  final buffer = StringBuffer('{\n');
  buffer.writeln('  "@@locale": "$locale",');

  final keysList = sorted.keys.toList();
  for (int i = 0; i < keysList.length; i++) {
    final key = keysList[i];
    final value = _escapeJson(sorted[key]!);
    final comma = i < keysList.length - 1 ? ',' : '';
    buffer.writeln('  "$key": "$value"$comma');
  }

  buffer.write('}');
  return buffer.toString();
}

/// Minimal CSV line splitter (handles quoted fields with commas inside).
List<String> _splitCsvLine(String line) {
  final result = <String>[];
  final buffer = StringBuffer();
  bool inQuotes = false;

  for (int i = 0; i < line.length; i++) {
    final char = line[i];

    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        // Escaped quote inside quoted field
        buffer.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char == ',' && !inQuotes) {
      result.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  result.add(buffer.toString());
  return result;
}

/// Escapes characters that are special inside JSON strings.
String _escapeJson(String s) => s
    .replaceAll(r'\', r'\\')
    .replaceAll('"', r'\"')
    .replaceAll('\n', r'\n')
    .replaceAll('\r', '');


