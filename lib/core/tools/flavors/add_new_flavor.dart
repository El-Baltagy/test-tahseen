import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Please provide a flavor name. Usage: dart add_new_flavor.dart <flavor>');
    return;
  }

  final newFlavor = args.first.toLowerCase();
  
  print('🚀 Starting automation for flavor: $newFlavor\n');

  // 1. Update App Config (Dart)
  updateAppConfig(newFlavor);

  // 2. Update pubspec.yaml (Flavorizr)
  updatePubspec(newFlavor);

  // 3. Update Android flavorizr.gradle.kts
  updateAndroidFlavorizr(newFlavor);

  // 4. Create Android Source Folders
  createAndroidFlavorFolders(newFlavor);

  print('\n✅ File updates completed!');
  print('------------------------------------------------------------');
  print('👉 NEXT STEPS:');
  print('1. Run Firebase configuration for the new flavor:');
  print('   dart run lib/core/tools/firebase/add_firebase.dart');
  print('2. Run Flavorizr to update native projects:');
  print('   ${getFlavorizrCommand()}');
  print('------------------------------------------------------------\n');
  
  print('✨ Flavor "$newFlavor" automated setup finished!');
}

String getFlavorizrCommand() {
  final isWindows = Platform.isWindows;
  final List<String> processors = [
    'android:androidManifest',
    'android:flavorizrGradle',
    'android:buildGradle',
    'android:icons',
    'google:firebase',
  ];

  if (!isWindows) {
    processors.addAll([
      'ios:podfile',
      'ios:xcconfig',
      'ios:buildTargets',
      'ios:schema',
      'ios:icons',
      'ios:plist',
      'ios:launchScreen',
    ]);
  }

  return 'flutter pub run flutter_flavorizr -p ${processors.join(' -p ')}';
}

void updateAppConfig(String newFlavor) {
  final filePath = 'lib/flavor_config.dart';
  final file = File(filePath);

  if (!file.existsSync()) {
    print('❌ lib/flavor_config.dart not found!');
    return;
  }

  String content = file.readAsStringSync();

  if (content.contains('Flavor.$newFlavor')) {
    print('⚠️ Flavor "$newFlavor" already exists in flavor_config.dart.');
    return;
  }

  // 1. Update Enum
  content = content.replaceFirstMapped(
    RegExp(r'enum Flavor \{ (.*?) \}'),
    (match) => 'enum Flavor { ${match.group(1)}, $newFlavor }',
  );

  // 2. Add Getter
  final lastGetter = content.lastIndexOf('static bool get is');
  if (lastGetter != -1) {
    final endOfGetter = content.indexOf(';', lastGetter) + 1;
    final newGetter = '\n  static bool get is${newFlavor[0].toUpperCase()}${newFlavor.substring(1)} => instance.flavor == Flavor.$newFlavor;';
    content = content.substring(0, endOfGetter) + newGetter + content.substring(endOfGetter);
  }

  // 3. Add Switch Case
  final lastBreak = content.lastIndexOf('break;');
  if (lastBreak != -1) {
    final endOfSwitchBlock = content.indexOf(';', lastBreak) + 1;
    final newCase = '''
      case '$newFlavor':
        AppFlavorConfig(
          firebaseOptions: defaultTargetPlatform == TargetPlatform.android ? const FirebaseOptions(
            apiKey: 'PLACEHOLDER',
            appId: 'PLACEHOLDER',
            messagingSenderId: 'PLACEHOLDER',
            projectId: 'PLACEHOLDER',
            storageBucket: 'PLACEHOLDER',
          ) : const FirebaseOptions(
            apiKey: 'PLACEHOLDER',
            appId: 'PLACEHOLDER',
            messagingSenderId: 'PLACEHOLDER',
            projectId: 'PLACEHOLDER',
            storageBucket: 'PLACEHOLDER',
            iosBundleId: 'com.app.tahseen.$newFlavor',
          ),
          flavor: Flavor.$newFlavor,
          baseUrl: 'https://$newFlavor-api.tahseen.com',
          appTitle: 'Tahseen [${newFlavor.toUpperCase()}]',
          interceptors: [],
        );
        break;''';
    content = content.substring(0, endOfSwitchBlock) + '\n' + newCase + content.substring(endOfSwitchBlock);
  }

  file.writeAsStringSync(content);
  print('✅ Updated flavor_config.dart');
}

void updatePubspec(String newFlavor) {
  final file = File('pubspec.yaml');
  if (!file.existsSync()) {
    print('❌ pubspec.yaml not found!');
    return;
  }

  String content = file.readAsStringSync();

  if (content.contains('$newFlavor:')) {
    print('⚠️ Flavor "$newFlavor" already exists in pubspec.yaml.');
    return;
  }

  // Find the flavors: section under flavorizr:
  final flavorsRegex = RegExp(r'flavors:\s*\n');
  final match = flavorsRegex.firstMatch(content);
  
  if (match == null) {
    print('❌ Could not find "flavors:" section in pubspec.yaml');
    return;
  }

  final newFlavorConfig = '''    $newFlavor:
      app:
        name: "Tahseen [${newFlavor.toUpperCase()}]"
      android:
        applicationId: "com.app.tahseen.$newFlavor"
      ios:
        bundleId: "com.app.tahseen.$newFlavor"
      icon: "assets/Main Icon.png"
      firebase:
        config: "ios/Runner/Firebase/$newFlavor/GoogleService-Info.plist"
''';

  final insertionPoint = match.end;
  content = content.substring(0, insertionPoint) + newFlavorConfig + content.substring(insertionPoint);

  file.writeAsStringSync(content);
  print('✅ Updated pubspec.yaml (flavorizr section)');
}

void updateAndroidFlavorizr(String newFlavor) {
  final file = File('android/app/flavorizr.gradle.kts');
  if (!file.existsSync()) {
    print('⚠️ android/app/flavorizr.gradle.kts not found, skipping Android update.');
    return;
  }

  String content = file.readAsStringSync();

  if (content.contains('create("$newFlavor")')) {
    print('⚠️ Flavor "$newFlavor" already exists in flavorizr.gradle.kts.');
    return;
  }

  // Find the productFlavors block
  final productFlavorsIndex = content.indexOf('productFlavors {');
  if (productFlavorsIndex == -1) {
    print('❌ Could not find "productFlavors" block in flavorizr.gradle.kts');
    return;
  }

  // Find the closing brace of productFlavors
  final lastBraceIndex = content.lastIndexOf('}');
  if (lastBraceIndex == -1) return;
  
  final productFlavorsEnd = content.lastIndexOf('}', lastBraceIndex - 1);

  final newFlavorBlock = '''
        create("$newFlavor") {
            dimension = "flavor-type"
            applicationId = "com.app.tahseen.$newFlavor"
            resValue(type = "string", name = "app_name", value = "Tahseen [${newFlavor.toUpperCase()}]")
        }
''';

  content = content.substring(0, productFlavorsEnd) + newFlavorBlock + content.substring(productFlavorsEnd);
  file.writeAsStringSync(content);
  print('✅ Updated android/app/flavorizr.gradle.kts');
}

void createAndroidFlavorFolders(String flavor) {
  final basePath = 'android/app/src/$flavor/res';
  final mipmapFolders = [
    'mipmap-mdpi',
    'mipmap-hdpi',
    'mipmap-xhdpi',
    'mipmap-xxhdpi',
    'mipmap-xxxhdpi',
  ];

  print('📂 Initializing Android flavor folders for "$flavor"...');

  try {
    for (var folder in mipmapFolders) {
      final path = '$basePath/$folder';
      final dir = Directory(path);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
        print('   ✅ Created: $path');
      } else {
        print('   ℹ️ Already exists: $path');
      }
    }
  } catch (e) {
    print('⚠️ Error creating Android folders: $e');
  }
}