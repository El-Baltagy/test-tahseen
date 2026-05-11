import 'dart:io';

void main() async {
  final flavorConfigFile = File('lib/flavor_config.dart');
  if (!flavorConfigFile.existsSync()) {
    print('❌ lib/flavor_config.dart not found.');
    return;
  }

  // Find all firebase_options_*.dart
  final libDir = Directory('lib');
  final optionFiles = libDir.listSync()
      .whereType<File>()
      .where((f) => f.path.contains('firebase_options_') && f.path.endsWith('.dart'))
      .toList();

  if (optionFiles.isEmpty) {
    print('ℹ️ No firebase_options_*.dart files found.');
    return;
  }

  String configContent = flavorConfigFile.readAsStringSync();

  // 1. Prepare flavor_config.dart (Add imports and field)
  configContent = _prepareConfig(configContent);

  // 2. Extract and Inject each flavor
  for (var file in optionFiles) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final flavor = fileName.replaceFirst('firebase_options_', '').replaceFirst('.dart', '');

    print('🔄 Processing flavor: $flavor');
    final optionsContent = file.readAsStringSync();

    final androidOptions = _extractOptions(optionsContent, 'android');
    final iosOptions = _extractOptions(optionsContent, 'ios');

    if (androidOptions != null && iosOptions != null) {
      final injection = 'firebaseOptions: defaultTargetPlatform == TargetPlatform.android ? const $androidOptions : const $iosOptions,';

      // More robust injection: find the case block and replace/inject
      final casePattern = RegExp("case\\s+'$flavor'[^:]*:[\\s\\S]*?AppFlavorConfig\\(([\\s\\S]*?)\\);", multiLine: true);

      if (configContent.contains(casePattern)) {
        configContent = configContent.replaceFirstMapped(casePattern, (match) {
          String block = match.group(1)!;
          
          // 1. Remove firebaseOptions: null,
          block = block.replaceFirst(RegExp(r'firebaseOptions:\s*null\s*,?'), '');
          
          // 2. If firebaseOptions already exists (e.g. from previous run), replace it
          if (block.contains('firebaseOptions:')) {
            block = block.replaceFirst(RegExp(r'firebaseOptions:\s*defaultTargetPlatform[\s\S]*?\),'), injection);
          } else {
            // Otherwise prepend it
            block = '\n          $injection' + block;
          }
          
          return match.group(0)!.replaceFirst(match.group(1)!, block);
        });
      } else {
        print('⚠️ Could not find case for $flavor in flavor_config.dart');
      }
    }

    // Delete the file after processing
    file.deleteSync();
    print('🗑️ Deleted $fileName');
  }

  flavorConfigFile.writeAsStringSync(configContent);
  print('\x1B[32m🚀 Successfully moved all Firebase configs into lib/flavor_config.dart\x1B[0m');
}

String _prepareConfig(String content) {
  // 1. Add Imports
  if (!content.contains('firebase_core.dart')) {
    content = "import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;\nimport 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;\n$content";
  }

  // 2. Add field to class
  if (!content.contains('final FirebaseOptions? firebaseOptions;')) {
    content = content.replaceFirst('static AppFlavorConfig? _instance;', 'final FirebaseOptions? firebaseOptions;\n  static AppFlavorConfig? _instance;');
  }

  // 3. Add parameter to factory constructor
  if (!content.contains('required FirebaseOptions? firebaseOptions,')) {
    content = content.replaceFirst('required List<Interceptor> interceptors,', 'required List<Interceptor> interceptors,\n    required FirebaseOptions? firebaseOptions,');
  }

  // 4. Update factory body call to internal constructor
  if (!content.contains('interceptors, firebaseOptions') && !content.contains('interceptors,firebaseOptions')) {
     content = content.replaceFirst('interceptors', 'interceptors, firebaseOptions');
  }

  // 5. Update internal constructor definition
  if (!content.contains('this.firebaseOptions')) {
    content = content.replaceFirst('this.interceptors', 'this.interceptors, this.firebaseOptions');
  }

  return content;
}

String? _extractOptions(String content, String platform) {
  final regex = RegExp('static const FirebaseOptions $platform = (FirebaseOptions\\([\\s\\S]*?\\);)');
  final match = regex.firstMatch(content);
  if (match != null) {
    var options = match.group(1)?.replaceFirst(';', '') ?? '';
    return options.trim();
  }
  return null;
}
