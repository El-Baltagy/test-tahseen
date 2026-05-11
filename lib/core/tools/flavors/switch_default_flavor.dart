import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('❌ Please provide a flavor name. Usage: dart switch_default_flavor.dart <flavor>');
    print('Example: dart switch_default_flavor.dart dev');
    exit(1);
  }

  final targetFlavor = args.first.toLowerCase();
  
  print('🔄 Switching global default flavor to: $targetFlavor\n');

  // 1. Update App Config (Dart)
  updateAppConfig(targetFlavor);

  // 2. Extract Package IDs from pubspec.yaml
  final packageIds = extractPackageIds(targetFlavor);
  if (packageIds == null) {
    print('❌ Could not find package IDs for flavor "$targetFlavor" in pubspec.yaml');
    exit(1);
  }

  // 3. Update Android (build.gradle.kts)
  updateAndroidPackageId(packageIds['android']!);

  // 4. Update iOS (project.pbxproj)
  updateIosBundleId(packageIds['ios']!);

  // 5. Update Firebase Configurations (Copy flavor files to root)
  updateFirebaseConfigs(targetFlavor);
  
  print('\n🚀 Project is now fully defaulted to: $targetFlavor');
}

void updateAppConfig(String targetFlavor) {
  // We check both common paths for app_config.dart
  File file = File('lib/flavor_config.dart');

  if (!file.existsSync()) {
    print('❌ Could not find ${file.path}');
    return;
  }

  String content = file.readAsStringSync();

  // Step 1: Remove ` || ''` from any case statement that currently has it.
  final removeEmptyStringRegex = RegExp(r"case\s+'(\w+)'\s*\|\|\s*'':");
  content = content.replaceAllMapped(removeEmptyStringRegex, (match) {
    return "case '${match.group(1)}':";
  });

  // Step 2: Add ` || ''` to the target flavor.
  final addEmptyStringRegex = RegExp(r"case\s+'" + targetFlavor + r"':");
  
  if (!content.contains(addEmptyStringRegex)) {
    print("❌ Flavor '$targetFlavor' not found in app_config.dart switch cases!");
    exit(1);
  }

  content = content.replaceFirst(addEmptyStringRegex, "case '$targetFlavor' || '':");
  file.writeAsStringSync(content);
  print('✅ Updated app_config.dart (Dart logic)');
}

Map<String, String>? extractPackageIds(String flavor) {
  final file = File('pubspec.yaml');
  if (!file.existsSync()) return null;

  final content = file.readAsStringSync();
  
  // Refined regex to find applicationId/bundleId inside the specific flavor block
  final flavorBlockRegex = RegExp(flavor + r':[\s\S]*?(?:applicationId|bundleId):\s+"([^"]+)"[\s\S]*?(?:applicationId|bundleId):\s+"([^"]+)"');
  final match = flavorBlockRegex.firstMatch(content);

  if (match != null) {
    return {
      'android': match.group(1)!,
      'ios': match.group(2)!,
    };
  }
  return null;
}

void updateAndroidPackageId(String newId) {
  final file = File('android/app/build.gradle.kts');
  if (!file.existsSync()) {
    print('⚠️ android/app/build.gradle.kts not found, skipping Android update.');
    return;
  }

  String content = file.readAsStringSync();
  
  // Update applicationId in defaultConfig block
  final regex = RegExp(r'(applicationId\s*=\s*")[^"]+(")');
  
  if (content.contains(regex)) {
    content = content.replaceFirstMapped(regex, (match) => '${match.group(1)}$newId${match.group(2)}');
    file.writeAsStringSync(content);
    print('✅ Updated Android applicationId to: $newId');
  }
}

void updateIosBundleId(String newId) {
  final file = File('ios/Runner.xcodeproj/project.pbxproj');
  if (!file.existsSync()) {
    print('⚠️ ios/Runner.xcodeproj/project.pbxproj not found, skipping iOS update.');
    return;
  }

  String content = file.readAsStringSync();
  
  // Update PRODUCT_BUNDLE_IDENTIFIER, excluding the one for RunnerTests
  final regex = RegExp(r'(PRODUCT_BUNDLE_IDENTIFIER\s*=\s*)(?![^;]*\.RunnerTests)[^;]+(?=;)');
  
  content = content.replaceAllMapped(regex, (match) => '${match.group(1)}$newId');
  file.writeAsStringSync(content);
  print('✅ Updated iOS bundleId to: $newId');
}

void updateFirebaseConfigs(String flavor) {
  print('📂 Syncing Firebase configuration for "$flavor"...');

  // 1. Android Sync
  final androidSource = File('android/app/src/$flavor/google-services.json');
  final androidDest = File('android/app/google-services.json');

  if (androidSource.existsSync()) {
    androidSource.copySync(androidDest.path);
    print('   ✅ Android: Synced google-services.json to root');
  } else {
    print('   ⚠️ Android: Source google-services.json not found at ${androidSource.path}');
  }

  // 2. iOS Sync
  final iosSource = File('ios/Runner/Firebase/$flavor/GoogleService-Info.plist');
  final iosDest = File('ios/Runner/GoogleService-Info.plist');

  if (iosSource.existsSync()) {
    iosSource.copySync(iosDest.path);
    print('   ✅ iOS: Synced GoogleService-Info.plist to root');
  } else {
    print('   ⚠️ iOS: Source GoogleService-Info.plist not found at ${iosSource.path}');
  }
}

