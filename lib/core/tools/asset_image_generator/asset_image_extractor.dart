import 'dart:io';

/// Usage:
///   dart run tool/extract_assets.dart <scanDir> <outputFile>
/// Example:
///   dart run tool/extract_assets.dart assets/images lib/core/constants/app_assets.dart

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Usage: dart run tool/extract_assets.dart <scanDir> <outputFile>');
    exit(1);
  }

  final String scanDirPath = args[0];
  // If user provides a 2nd argument, use it; otherwise default for backward compatibility
  final String outputPath = args.length > 1 ? args[1] : 'lib/core/constants/app_assets.dart';

  final scanDir = Directory(scanDirPath);
  final outputFile = File(outputPath);

  if (!scanDir.existsSync()) {
    print('❌ Scan directory not found: ${scanDir.path}');
    exit(2);
  }

  print('🔄 Scanning: ${scanDir.path}');
  print('💾 Output:   ${outputFile.path}');

  final buffer = StringBuffer();
  buffer.writeln('// ---------------------------------------------------------------------');
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// ---------------------------------------------------------------------');
  buffer.writeln('');
  buffer.writeln('class AppAssets {');
  buffer.writeln('  AppAssets._();\n');

  // Normalize base path for cross-platform (Windows uses \, Dart needs /)
  final String basePath = scanDir.path.replaceAll('\\', '/');
  
  // Note: We do NOT create a static _assetPath variable anymore.
  // We put full paths in the variables so they are easier to use/export if needed.

  final files = scanDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => !f.path.split(Platform.pathSeparator).last.startsWith('.')); // Ignore .DS_Store, .gitkeep

  int count = 0;
  for (final file in files) {
    // RELATIVE PATH CALCULATION
    // Windows: assets\images\logo.png
    // Base:    assets\images
    // Rel:     logo.png
    
    String relativeName = file.path.replaceAll('\\', '/');
    String baseNameNormalized = basePath;
    
    if (relativeName.startsWith(baseNameNormalized)) {
      relativeName = relativeName.substring(baseNameNormalized.length);
    }
    
    if (relativeName.startsWith('/')) {
        relativeName = relativeName.substring(1);
    }

    // GENERATE VARIABLE NAME
    // logo.png -> logoPng
    final varName = _toLowerCamelCase(relativeName);

    // FULL FLUTTER ASSET PATH
    // assets/images/logo.png
    final fullPath = '$basePath/$relativeName';

    buffer.writeln("  /// Assets for [$varName]");
    buffer.writeln("  /// Path: $fullPath");
    buffer.writeln("  static const String $varName = '$fullPath';");
    count++;
  }

  buffer.writeln('}');

  // Create directory if it doesn't exist
  if (!outputFile.parent.existsSync()) {
      outputFile.parent.createSync(recursive: true);
  }
  
  await outputFile.writeAsString(buffer.toString());

  print('✅ Generated $count assets!');
}

/// Converts paths like "icons/home_icon.svg" to "iconsHomeIconSvg"
String _toLowerCamelCase(String input) {
  // 1. Replace separators with underscores
  String cleaned = input.replaceAll(' ', '_').replaceAll('/', '_').replaceAll('.', '_').replaceAll('-', '_');
  
  // 2. Remove all non-alphanumeric (except underscore)
  cleaned = cleaned.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
  
  // 3. Split by underscore and capitalize
  List<String> parts = cleaned.split('_');
  StringBuffer sb = StringBuffer();
  
  for (int i = 0; i < parts.length; i++) {
    String part = parts[i];
    if (part.isEmpty) continue;
    
    if (i == 0) {
      sb.write(part.toLowerCase());
    } else {
      sb.write(part[0].toUpperCase() + part.substring(1).toLowerCase());
    }
  }
  
  return sb.toString();
}
