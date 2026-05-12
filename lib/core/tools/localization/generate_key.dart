import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  String englishValue = '';

  if (args.isNotEmpty) {
    englishValue = args.join(' ');
  } else {
    stdout.write('Enter the English text to add: ');
    englishValue = stdin.readLineSync(encoding: utf8) ?? '';
  }

  if (englishValue.trim().isEmpty) {
    print('❌ Error: English text cannot be empty.');
    return;
  }

  // Generate snake_case key
  final key = toSnakeCase(englishValue);
  print('🔑 Generated key: $key');

  final csvPath = 'assets/l10n/translations.csv';
  final file = File(csvPath);

  if (!await file.exists()) {
    print('❌ Error: CSV file not found at $csvPath');
    return;
  }

  // Read the CSV file to determine the number of columns (languages)
  final lines = await file.readAsLines(encoding: utf8);
  if (lines.isEmpty) {
    print('❌ Error: CSV is empty.');
    return;
  }

  final headers = lines.first.split(',');
  final int columnCount = headers.length;

  // Build the new row: [key, englishValue, empty, empty...]
  List<String> newRow = List.filled(columnCount, '');
  newRow[0] = key;
  newRow[1] = _escapeCsv(englishValue);

  final newLine = newRow.join(',');

  // Append to the CSV file
  await file.writeAsString('\n' + newLine, mode: FileMode.append, encoding: utf8);
  
  print('✅ Successfully added "$englishValue" with key "$key" to $csvPath');
  print('💡 Run the auto_translate script next to fill in the other languages!');
}

/// Converts a human-readable string into snake_case.
/// Examples:
/// "Enter your email" -> "enter_your_email"
/// "Login Screen UI" -> "login_screen_ui"
String toSnakeCase(String text) {
  final cleanText = text
      .trim()
      // Replace any non-alphanumeric (except spaces) with space
      .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
      // Collapse multiple spaces into underscore
      .replaceAll(RegExp(r'\s+'), '_')
      .toLowerCase();

  if (cleanText.isEmpty) return 'empty_key';

  // Remove leading digits (keys must start with a letter)
  return cleanText.replaceFirstMapped(RegExp(r'^(\d)'), (m) => '_${m.group(1)}')
                  .replaceAll(RegExp(r'_+$'), '');
}

/// Escapes a CSV value if it contains commas
String _escapeCsv(String value) {
  if (value.contains(',')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
