import 'dart:convert';
import 'dart:io';

/// Script to automatically translate empty values in the localization CSV
/// using the LibreTranslate API (https://docs.libretranslate.com).
/// 
/// Usage: 
/// dart tools/localization/auto_translate.dart
void main() async {
  // Path to your CSV file
  final csvPath = 'assets/l10n/translations.csv';
  final file = File(csvPath);

  if (!await file.exists()) {
    print('Error: CSV file not found at $csvPath');
    return;
  }

  // Define the LibreTranslate API endpoint. 
  // Note: Public instances might have rate limits or require an API key. 
  // If you host your own, change this URL to your local instance (e.g., http://localhost:5000/translate)
  final String apiUrl = 'https://translate.argosopentech.com/translate';
  // Other public instances can be found at https://github.com/LibreTranslate/LibreTranslate#mirrors
  
  final lines = await file.readAsLines(encoding: utf8);
  if (lines.isEmpty) {
    print('CSV is empty.');
    return;
  }

  // Parse headers
  final headers = lines.first.split(',');
  if (headers.length < 2) {
    print('CSV must have at least a key and one language column.');
    return;
  }

  // Assume the first language column after 'key' is the source language (e.g. 'en')
  final sourceLang = headers[1].trim();
  final targetLangs = headers.sublist(2).map((e) => e.trim()).toList();
  
  print('Source language: $sourceLang');
  print('Target languages: $targetLangs');

  List<String> updatedLines = [lines.first];
  bool hasChanges = false;
  
  final httpClient = HttpClient();

  try {
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        updatedLines.add(line);
        continue;
      }

      // Split line keeping comma escapes in mind (simple split for now)
      final parts = line.split(',');
      final key = parts[0];
      final sourceText = parts.length > 1 ? parts[1] : '';

      List<String> newParts = [key, sourceText];

      for (int j = 0; j < targetLangs.length; j++) {
        final colIndex = j + 2;
        String targetText = parts.length > colIndex ? parts[colIndex] : '';
        final targetLang = targetLangs[j];

        // If target text is missing or empty, translate it!
        if (targetText.trim().isEmpty && sourceText.trim().isNotEmpty) {
          print('Translating [$key] from $sourceLang to $targetLang...');
          
          try {
            final translated = await _translateText(
              httpClient, 
              sourceText, 
              sourceLang, 
              targetLang
            );
            targetText = translated;
            hasChanges = true;
            
            // Add a small delay to avoid hitting rate limits on public APIs
            await Future.delayed(Duration(milliseconds: 500));
          } catch (e) {
            print('Failed to translate [$key]: $e');
          }
        }
        newParts.add(targetText);
      }
      updatedLines.add(newParts.join(','));
    }
  } finally {
    httpClient.close();
  }

  if (hasChanges) {
    await file.writeAsString(updatedLines.join('\n') + '\n', encoding: utf8);
    print('✅ Translations successfully updated in $csvPath');
    
    print('\n🔄 Compiling CSV to ARB files...');
    final result = await Process.run('dart', ['run', 'lib/core/tools/localization/csv_to_json.dart']);
    if (result.exitCode == 0) {
      print(result.stdout);
    } else {
      print('❌ Failed to compile ARB files:\n${result.stderr}');
    }
  } else {
    print('✨ No new translations needed. Everything is up to date.');
  }
}

Future<String> _translateText(
  HttpClient client, 
  String text, 
  String source, 
  String target
) async {
  // Using the free Google Translate API endpoint (client=gtx) for reliability
  final encodedText = Uri.encodeComponent(text);
  final url = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$source&tl=$target&dt=t&q=$encodedText';
  
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();
  
  final responseBody = await response.transform(utf8.decoder).join();
  
  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(responseBody);
    // Google Translate returns an array structure: [[[ "ترجمة", "translation", ...]]]
    if (jsonResponse is List && jsonResponse.isNotEmpty && jsonResponse[0] is List && jsonResponse[0].isNotEmpty) {
      return jsonResponse[0][0][0]?.toString() ?? text;
    }
    return text;
  } else {
    throw Exception('API Error: ${response.statusCode} - $responseBody');
  }
}
