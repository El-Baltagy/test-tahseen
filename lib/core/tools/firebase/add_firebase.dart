import 'dart:io';
import '../utils_spinner.dart';
import '../create_auto_files/path_constants.dart';
import '../flavors/switch_default_flavor.dart';

const String kFirebaseCustomPath = r'D:\programmes\firebase.exe';

void main() async {
  print('\x1B[2J\x1B[0;0H'); // Clear console
  print('🔥 \x1B[31mFirebase CLI Setup for Tahseen Project\x1B[0m');
  print('===========================================');

  // 1. Check for Firebase CLI
  if (!await _checkCommand('firebase')) {
    print('❌ \x1B[31mFirebase CLI not found.\x1B[0m');
    stdout.write('Would you like to attempt automatic installation? [y/N]: ');
    final installChoice = stdin.readLineSync()?.trim().toLowerCase() ?? '';
    
    if (installChoice == 'y') {
      await _installFirebaseCLI();
      // Re-check after installation
      if (!await _checkCommand('firebase')) {
         print('❌ \x1B[31mInstallation failed or firebase is still not in PATH.\x1B[0m');
         print('Please restart your terminal or install manually: https://firebase.google.com/docs/cli');
         return;
      }
    } else {
      print('👉 Install it manually: https://firebase.google.com/docs/cli#install_the_firebase_cli');
      return;
    }
  }

  // 1.5. Check for Login
  if (!await _checkFirebaseLogin()) {
    print('\n👤 \x1B[33mYou are not logged into Firebase.\x1B[0m');
    stdout.write('Would you like to log in now? [Y/n]: ');
    final loginChoice = stdin.readLineSync()?.trim().toLowerCase() ?? 'y';
    if (loginChoice == '' || loginChoice == 'y') {
      await _triggerFirebaseLogin();
    } else {
       print('⚠️ Warning: Many Firebase commands require login.');
    }
  } else {
    print('✅ \x1B[32mAlready logged into Firebase.\x1B[0m');
  }

  // 2. Check/Install FlutterFire CLI
  final flutterFireSpinner = Spinner('Checking FlutterFire CLI');
  flutterFireSpinner.start();
  if (!await _checkCommand('flutterfire')) {
    flutterFireSpinner.stop('Installing FlutterFire CLI...');
    final installSpinner = Spinner('Activating flutterfire_cli');
    installSpinner.start();
    await Process.run('dart', ['pub', 'global', 'activate', 'flutterfire_cli'], runInShell: true);
    installSpinner.stop('✅ FlutterFire CLI activated!');
  } else {
    flutterFireSpinner.stop('✅ FlutterFire CLI is ready.');
  }

  // 3. Add Firebase Core and others
  final pubspecFile = File('pubspec.yaml');
  final pubContent = pubspecFile.readAsStringSync();
  
  if (!pubContent.contains('firebase_core:')) {
    final pubspecSpinner = Spinner('Adding firebase_core');
    pubspecSpinner.start();
    await Process.run('flutter', ['pub', 'add', 'firebase_core'], runInShell: true);
    pubspecSpinner.stop('✅ firebase_core added.');
  }

  print('\n📦 Would you like to add common Firebase plugins?');
  final plugins = {
    'firebase_auth': 'Authentication',
    'cloud_firestore': 'Firestore Database',
    'firebase_messaging': 'Cloud Messaging (Push)',
    'firebase_analytics': 'Analytics',
    'firebase_crashlytics': 'Crashlytics',
    'firebase_storage': 'Storage',
  };

  for (var entry in plugins.entries) {
    if (!pubContent.contains('${entry.key}:')) {
      stdout.write('Add ${entry.value} (${entry.key})? [y/N]: ');
      final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';
      if (input == 'y') {
        final spinner = Spinner('Adding ${entry.key}');
        spinner.start();
        await Process.run('flutter', ['pub', 'add', entry.key], runInShell: true);
        spinner.stop('✅ ${entry.key} added.');
      }
    }
  }

  // 4. Configuration Mode
  final flavors = _getFlavorsFromGradle();
  
  if (flavors.isEmpty) {
    print('\nℹ️ \x1B[34mNo multi-flavor setup detected (flavorizr.gradle.kts missing or empty).\x1B[0m');
    print('Proceeding with standard configuration.');
    await _configureStandard();
  } else {
    print('2) Multi-Flavor (${flavors.map((f) => f.name).join(', ')})');
    await _configureFlavors(flavors);
    // print('\n\x1B[33mConfiguration Mode:\x1B[0m');
    // print('1) Standard (Single project, default paths)');
    // print('2) Multi-Flavor (${flavors.map((f) => f.name).join(', ')})');
    // stdout.write('Select an option (1-2) [Default: 1]: ');
    // final choice = stdin.readLineSync()?.trim() ?? '1';

    // if (choice == '2') {
    //   await _configureFlavors(flavors);
    // } else {
    //   await _configureStandard();
    // }
  }

  print('\n\x1B[32m🚀 Firebase setup steps completed!\x1B[0m');
  print('-------------------------------------------');

  // 5. Automatic Migration
  print('\n📦 \x1B[34mMoving Firebase configuration into flavor_config.dart...\x1B[0m');
  final migrationProcess = await Process.start(
    'dart',
    ['run', 'lib/core/tools/firebase/move_firebase_config_into_flavor.dart'],
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  await migrationProcess.exitCode;
/// 5 switch into dev
  final autoSwitch = await Process.start(
    'dart',
    ['run', 'lib/core/tools/flavors/switch_default_flavor.dart','dev'],
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  await autoSwitch.exitCode;
  print('\nNext Steps:');
  print('1. Ensure you have initialized Firebase in main.dart:');
  print('   await Firebase.initializeApp(options: AppFlavorConfig.instance.firebaseOptions);');
  print('2. For Crashlytics/Messaging, additional native setup may be required.');

  // 6. Update Native Files
  print('\n🛠️  Updating native build files...');
  _updateProjectBuildGradle();
  _updateAppBuildGradle();
  _updateIosAppDelegate();
}


Future<String> _getFirebaseCommand() async {
  if (await _checkCommand('firebase')) return 'firebase';
  
  if (Platform.isWindows && File(kFirebaseCustomPath).existsSync()) {
    return kFirebaseCustomPath;
  }
  
  return 'firebase'; // Fallback
}

List<FlavorData> _getFlavorsFromGradle() {
  final file = File('android/app/flavorizr.gradle.kts');
  if (!file.existsSync()) return [];

  final content = file.readAsStringSync();
  final flavors = <FlavorData>[];
  
  // Regex to find create("flavorName") and its applicationId
  final regExp = RegExp(r'create\("(.+?)"\)\s*\{[\s\S]*?applicationId\s*=\s*"(.+?)"', multiLine: true);
  final matches = regExp.allMatches(content);

  for (final match in matches) {
    if (match.groupCount >= 2) {
      flavors.add(FlavorData(match.group(1)!, match.group(2)!));
    }
  }

  return flavors;
}

class FlavorData {
  final String name;
  final String applicationId;
  FlavorData(this.name, this.applicationId);
}

Future<bool> _checkCommand(String command) async {
  try {
    final result = await Process.run(command, ['--version'], runInShell: true);
    if (result.exitCode == 0) return true;
    
    // Check for constant path on Windows
    if (command == 'firebase' && Platform.isWindows) {
      if (File(kFirebaseCustomPath).existsSync()) {
        final pResult = await Process.run(kFirebaseCustomPath, ['--version'], runInShell: true);
        if (pResult.exitCode == 0) return true;
      }
    }
    return false;
  } catch (_) {
    if (command == 'firebase' && Platform.isWindows) {
       try {
         if (File(kFirebaseCustomPath).existsSync()) {
           final pResult = await Process.run(kFirebaseCustomPath, ['--version'], runInShell: true);
           if (pResult.exitCode == 0) return true;
         }
       } catch (__) {
         return false;
       }
    }
    return false;
  }
}

Future<void> _configureStandard() async {
  print('\n📝 \x1B[34mConfiguring Firebase...\x1B[0m');
  print('The FlutterFire CLI will now open. Please follow the prompts.');
  
  final command = await _getFlutterFireCommand();
  final executable = command.split(' ').first;
  final args = [...command.split(' ').skip(1), 'configure'];

  final process = await Process.start(
    executable,
    args,
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  await process.exitCode;
}

Future<void> _configureFlavors(List<FlavorData> flavors) async {
  for (final flavor in flavors) {
    print('\n📝 \x1B[34mConfiguring ${flavor.name.toUpperCase()} flavor...\x1B[0m');
    await _runFlutterFireConfig(
      flavor: flavor.name,
      output: 'lib/firebase_options_${flavor.name}.dart',
      bundleId: flavor.applicationId,
      packageName: flavor.applicationId,
    );
  }
}

Future<void> _runFlutterFireConfig({
  required String flavor,
  required String output,
  required String bundleId,
  required String packageName,
}) async {
  print('--- Configuring for $flavor ---');
  final command = await _getFlutterFireCommand();
  final executable = command.split(' ').first;
  final baseArgs = command.split(' ').skip(1).toList();

  final process = await Process.start(
    executable,
    [
      ...baseArgs,
      'configure',
      '--out=$output',
      '--ios-bundle-id=$bundleId',
      '--android-package-name=$packageName',
    ],
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  await process.exitCode;

  // Move Native Files to Flavor Folders
  print('📦 Moving native config files for $flavor...');

  // 1. Android: google-services.json
  final androidSource = File('android/app/google-services.json');
  if (androidSource.existsSync()) {
    final androidTargetDir = Directory('android/app/src/$flavor');
    if (!androidTargetDir.existsSync()) androidTargetDir.createSync(recursive: true);
    androidSource.renameSync('${androidTargetDir.path}/google-services.json');
    print('✅ Moved google-services.json to android/app/src/$flavor/');
  }

  // 2. iOS: GoogleService-Info.plist
  final iosSource = File('ios/Runner/GoogleService-Info.plist');
  if (iosSource.existsSync()) {
    final iosTargetDir = Directory('ios/Runner/Firebase/$flavor');
    if (!iosTargetDir.existsSync()) iosTargetDir.createSync(recursive: true);
    iosSource.renameSync('${iosTargetDir.path}/GoogleService-Info.plist');
    print('✅ Moved GoogleService-Info.plist to ios/Runner/Firebase/$flavor/');
  }
}

Future<String> _getFlutterFireCommand() async {
  if (await _checkCommand('flutterfire')) return 'flutterfire';
  return 'dart pub global run flutterfire_cli:flutterfire';
}

Future<bool> _checkFirebaseLogin() async {
  final command = await _getFirebaseCommand();
  try {
    final result = await Process.run(command, ['projects:list'], runInShell: true);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

Future<void> _triggerFirebaseLogin() async {
  final command = await _getFirebaseCommand();
  print('\n🔑 \x1B[34mOpening Firebase login...\x1B[0m');
  final process = await Process.start(
    command,
    ['login'],
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  await process.exitCode;
}

Future<void> _installFirebaseCLI() async {
  print('Attempting to install Firebase CLI automatically...');
  
  if (await _checkCommand('npm')) {
    final spinner = Spinner('Installing via npm');
    spinner.start();
    await Process.run('npm', ['install', '-g', 'firebase-tools'], runInShell: true);
    spinner.stop('✅ Firebase CLI installed via npm!');
    return;
  }

  if (Platform.isWindows) {
    print('NPM not found. Attempting to download standalone binary for Windows...');
    final spinner = Spinner('Downloading firebase.exe');
    spinner.start();
    
    final targetDir = Directory(kFirebaseCustomPath).parent;
    if (!targetDir.existsSync()) targetDir.createSync(recursive: true);
    
    await Process.run('powershell', [
      '-Command',
      'Invoke-WebRequest -Uri "https://firebase.tools/bin/win/latest" -OutFile "$kFirebaseCustomPath"'
    ], runInShell: true);
    spinner.stop('✅ Downloaded firebase.exe to $kFirebaseCustomPath');
    print('\x1B[33m⚠️ Note: Firebase is now available at: $kFirebaseCustomPath\x1B[0m');
    return;
  }

  print('❌ \x1B[31mCould not install automatically.\x1B[0m');
  print('Please install manually: https://firebase.google.com/docs/cli');
}

void _updateProjectBuildGradle() {
  final ktsFile = File('android/build.gradle.kts');
  final groovyFile = File('android/build.gradle');

  if (ktsFile.existsSync()) {
    var content = ktsFile.readAsStringSync();
    if (!content.contains('com.google.gms.google-services')) {
      final pluginBlock = 'plugins {\n    id("com.google.gms.google-services") version "4.4.4" apply false\n}\n\n';
      if (content.contains('plugins {')) {
        content = content.replaceFirst('plugins {', 'plugins {\n    id("com.google.gms.google-services") version "4.4.4" apply false');
      } else {
        content = pluginBlock + content;
      }
      ktsFile.writeAsStringSync(content);
      print('✅ Updated android/build.gradle.kts');
    }
  } else if (groovyFile.existsSync()) {
    var content = groovyFile.readAsStringSync();
    if (!content.contains('com.google.gms.google-services')) {
      final pluginBlock = 'plugins {\n    id \'com.google.gms.google-services\' version \'4.4.4\' apply false\n}\n\n';
      if (content.contains('plugins {')) {
        content = content.replaceFirst('plugins {', 'plugins {\n    id \'com.google.gms.google-services\' version \'4.4.4\' apply false');
      } else {
        content = pluginBlock + content;
      }
      groovyFile.writeAsStringSync(content);
      print('✅ Updated android/build.gradle');
    }
  }
}

void _updateAppBuildGradle() {
  final ktsFile = File('android/app/build.gradle.kts');
  final groovyFile = File('android/app/build.gradle');

  if (ktsFile.existsSync()) {
    var content = ktsFile.readAsStringSync();
    bool updated = false;

    // Add plugin
    if (!content.contains('id("com.google.gms.google-services")')) {
      content = content.replaceFirst('plugins {', 'plugins {\n    id("com.google.gms.google-services")');
      updated = true;
    }

    // Add dependencies
    if (!content.contains('com.google.firebase:firebase-bom')) {
      final depBlock = '\ndependencies {\n    implementation(platform("com.google.firebase:firebase-bom:34.13.0"))\n    implementation("com.google.firebase:firebase-analytics")\n}\n';
      if (content.contains('dependencies {')) {
        content = content.replaceFirst('dependencies {', 'dependencies {\n    implementation(platform("com.google.firebase:firebase-bom:34.13.0"))\n    implementation("com.google.firebase:firebase-analytics")');
      } else {
        content += depBlock;
      }
      updated = true;
    }

    if (updated) {
      ktsFile.writeAsStringSync(content);
      print('✅ Updated android/app/build.gradle.kts');
    }
  } else if (groovyFile.existsSync()) {
    var content = groovyFile.readAsStringSync();
    bool updated = false;

    // Add plugin
    if (!content.contains('com.google.gms.google-services')) {
      content = content.replaceFirst('plugins {', 'plugins {\n    id \'com.google.gms.google-services\'');
      updated = true;
    }

    // Add dependencies
    if (!content.contains('com.google.firebase:firebase-bom')) {
      final depBlock = '\ndependencies {\n    implementation platform(\'com.google.firebase:firebase-bom:34.13.0\')\n    implementation \'com.google.firebase:firebase-analytics\'\n}\n';
      if (content.contains('dependencies {')) {
        content = content.replaceFirst('dependencies {', 'dependencies {\n    implementation platform(\'com.google.firebase:firebase-bom:34.13.0\')\n    implementation \'com.google.firebase:firebase-analytics\'');
      } else {
        content += depBlock;
      }
      updated = true;
    }

    if (updated) {
      groovyFile.writeAsStringSync(content);
      print('✅ Updated android/app/build.gradle');
    }
  }
}

void _updateIosAppDelegate() {
  final file = File('ios/Runner/AppDelegate.swift');
  if (!file.existsSync()) return;

  var content = file.readAsStringSync();
  bool updated = false;

  if (!content.contains('import FirebaseCore')) {
    content = content.replaceFirst('import Flutter', 'import Flutter\nimport FirebaseCore');
    updated = true;
  }

  if (!content.contains('FirebaseApp.configure()')) {
    content = content.replaceFirst(
      'GeneratedPluginRegistrant.register(with: self)',
      'FirebaseApp.configure()\n    GeneratedPluginRegistrant.register(with: self)',
    );
    updated = true;
  }

  if (updated) {
    file.writeAsStringSync(content);
    print('✅ Updated ios/Runner/AppDelegate.swift');
  }
}
