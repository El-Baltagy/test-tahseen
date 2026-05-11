// lib/core/tools/CI-CD/fastlane.dart
import 'dart:io';
import 'dart:async';
import 'dart:convert';

Future<void> main() async {
  print('🚀 Initializing Fastlane for Android and iOS...');

  // 1. Locate Ruby (or install via winget)
  String? rubyBin = _findRubyBinPath();
  bool hasRuby = rubyBin != null || await _checkCommand('ruby') || await _checkCommand('gem');

  if (!hasRuby) {
    print('🔍 Ruby not found. Installing via winget...');
    final result = await Process.run(
      'winget',
      [
        'install',
        '-e',
        '--id',
        'RubyInstallerTeam.Ruby.3.2',
        '--accept-source-agreements',
        '--accept-package-agreements',
      ],
      runInShell: true,
    );
    if (result.exitCode == 0) {
      print('✅ Ruby installation triggered. Restart terminal/IDE then re‑run this script.');
      return;
    } else {
      print('❌ Ruby install failed. Install manually from https://rubyinstaller.org/');
      print('ℹ️ Continuing with file generation only.');
    }
  }

  // 2. Ensure MSYS2 (required for native gems like fastlane on Windows)
  bool msysReady = false;
  if (rubyBin != null && Platform.isWindows) {
    msysReady = await _ensureMSYS2(rubyBin);
  } else if (!Platform.isWindows) {
    msysReady = true; // Assume Unix-like systems have build tools or don't need MSYS2
  }

  if (!msysReady && Platform.isWindows) {
    print('⚠️ MSYS2 could not be prepared. Fastlane installation may fail.');
  }

  // 3. Install Fastlane gem and Bundler (Skip if already present)
  if (rubyBin != null) {
    if (!await _checkCommand('bundle', rubyBin: rubyBin)) {
      print('📦 Installing Bundler...');
      await _runCommand('gem', ['install', 'bundler'], rubyBin: rubyBin);
    } else {
      print('✅ Bundler already installed.');
    }
    
    if (!await _checkCommand('fastlane', rubyBin: rubyBin)) {
      print('📦 Installing Fastlane gem globally...');
      await _runCommand('gem', ['install', 'fastlane', '-NV'], rubyBin: rubyBin);
    } else {
      print('✅ Fastlane already installed.');
    }
  }

  // 4. Generate Android & iOS Fastlane configs
  await _setupAndroidFastlane(rubyBin: rubyBin);
  await _setupIosFastlane(rubyBin: rubyBin);

  // 5. Generate .env.template
  _generateEnvTemplate();

  print('\n\x1B[32m✅ Fastlane setup completed successfully!\x1B[0m');
  print('👉 Next steps:');
  print('1. Fill in the .env file (copy from .env.template).');
  print('2. Run "bundle install" in android/ and ios/ directories.');
  print('3. Run "fastlane distribute flavor:dev" to deploy.');
}

// -----------------------------------------------------------------
// Helper: Locate Ruby bin directory on Windows
// -----------------------------------------------------------------
String? _findRubyBinPath() {
  if (!Platform.isWindows) return null;
  
  // Try 'where' command first
  try {
    final res = Process.runSync('where', ['ruby'], runInShell: true);
    if (res.exitCode == 0) {
      final line = res.stdout.toString().split('\n').first.trim();
      if (line.isNotEmpty) {
        return File(line).parent.path;
      }
    }
  } catch (_) {}

  const candidates = [
    r'C:\Ruby34-x64\bin',
    r'C:\Ruby33-x64\bin',
    r'C:\Ruby32-x64\bin',
    r'C:\Ruby31-x64\bin',
  ];
  for (final p in candidates) {
    if (Directory(p).existsSync()) return p;
  }
  return null;
}

// -----------------------------------------------------------------
// Helper: Verify a command exists
// -----------------------------------------------------------------
Future<bool> _checkCommand(String cmd, {String? rubyBin}) async {
  try {
    final env = Map<String, String>.from(Platform.environment);
    if (rubyBin != null) {
      final sep = Platform.isWindows ? ';' : ':';
      env['PATH'] = '$rubyBin$sep${env['PATH']}';
    }
    // 1. Try direct version check
    final res = await Process.run(cmd, ['--version'], runInShell: true, environment: env);
    if (res.exitCode == 0) return true;

    // 2. Fallback: Check 'gem list'
    if (cmd == 'fastlane' || cmd == 'bundle') {
      final gemName = cmd == 'bundle' ? 'bundler' : 'fastlane';
      final gemList = await Process.run('gem', ['list', '-i', gemName], runInShell: true, environment: env);
      return gemList.stdout.toString().trim() == 'true';
    }
    return false;
  } catch (_) {
    return false;
  }
}

// -----------------------------------------------------------------
// Helper: Ensure MSYS2 (gcc, make, etc.) via ridk or manual download
// -----------------------------------------------------------------
Future<bool> _ensureMSYS2(String rubyBin) async {
  final env = Map<String, String>.from(Platform.environment);
  final sep = Platform.isWindows ? ';' : ':';
  
  // Inject candidate paths for checking
  const msysCandidates = [
    r'C:\msys64\mingw64\bin',
    r'C:\msys64\usr\bin',
    r'C:\msys64\ucrt64\bin',
    r'C:\Ruby32-x64\msys64\mingw64\bin',
    r'C:\Ruby32-x64\msys64\usr\bin',
    r'C:\Ruby32-x64\msys64\ucrt64\bin',
  ];
  
  String currentPath = env['PATH'] ?? '';
  for (var p in msysCandidates) {
    if (Directory(p).existsSync()) currentPath = '$p$sep$currentPath';
  }
  env['PATH'] = '$rubyBin$sep$currentPath';
  
  // Check if gcc is actually working
  print('🔍 Checking for working C compiler (gcc)...');
  try {
    final gccCheck = await Process.run('gcc', ['--version'], runInShell: true, environment: env);
    if (gccCheck.exitCode == 0) {
      print('✅ C compiler (gcc) is ready.');
      return true;
    }
  } catch (_) {}

  print('\x1B[31m-------------------------------❌ Error: C compiler (gcc) not found or not working.'
      '-----------------------------\x1B[0m');

  print('🛠️  MANUAL FIX REQUIRED:');
  print('Please open a NEW PowerShell window and follow these steps:');
  print('\n1️⃣  Paste this to enable scripts:');
  print('\x1B[33mSet-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force\x1B[0m');

  print('\n2️⃣  Paste this to install build tools (choose option 2 then 3):');
  print('\x1B[33mridk install 2 3\x1B[0m');

  print('------------------------------------------------------------');

  stdout.write('\n👉 Have you completed the manual installation? (y/n): ');
  final response = stdin.readLineSync()?.toLowerCase();
  
  if (response == 'y') {
    print('🔄 Re-checking compiler...');
    final finalCheck = await Process.run('gcc', ['--version'], runInShell: true, environment: env);
    if (finalCheck.exitCode == 0) {
      print('✅ Compiler is now working!');
      return true;
    } else {
      print('❌ Compiler still not found. Please ensure ridk install finished successfully.');
    }
  }

  print('------------------------------------------------------------');
  print('💡 AUTO-FIX FAILED. Please ensure build tools are installed.');
  print('Manual command: ridk install 2 3');
  print('------------------------------------------------------------');
  
  return false;
}

// -----------------------------------------------------------------
// Helper: Run a command with Ruby bin injected into PATH
// -----------------------------------------------------------------
Future<void> _runCommand(String cmd, List<String> args, {String? rubyBin, String? cwd}) async {
  final env = Map<String, String>.from(Platform.environment);
  final sep = Platform.isWindows ? ';' : ':';
  
  // Collect all necessary paths to inject
  List<String> extraPaths = [];
  if (rubyBin != null) extraPaths.add(rubyBin);
  
  if (Platform.isWindows) {
    // MSYS2 paths required for compiling native extensions (make, gcc, etc.)
    const msysCandidates = [
      r'C:\msys64\mingw64\bin',
      r'C:\msys64\usr\bin',
      r'C:\Ruby32-x64\msys64\mingw64\bin', // Sometimes bundled inside Ruby folder
      r'C:\Ruby32-x64\msys64\usr\bin',
    ];
    for (var p in msysCandidates) {
      if (Directory(p).existsSync()) extraPaths.add(p);
    }
  }

  if (extraPaths.isNotEmpty) {
    env['PATH'] = '${extraPaths.join(sep)}$sep${env['PATH']}';
  }
  
  print('🏃 Running: $cmd ${args.join(' ')}');
  final result = await Process.run(cmd, args, runInShell: true, workingDirectory: cwd, environment: env);
  
  if (result.exitCode != 0) {
    print('⚠️ Error: ${result.stderr}');
  } else if (result.stdout.toString().isNotEmpty) {
    print(result.stdout);
  }
}

// -----------------------------------------------------------------
// Android Fastlane setup
// -----------------------------------------------------------------
Future<void> _setupAndroidFastlane({String? rubyBin}) async {
  final fastfile = File('android/fastlane/Fastfile');
  if (fastfile.existsSync()) {
    print('✅ Android Fastlane already configured. Skipping setup.');
    return;
  }

  print('\n🤖 Configuring Android Fastlane...');
  final dir = Directory('android/fastlane');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  // Gemfile
  File('android/Gemfile').writeAsStringSync('''source "https://rubygems.org"
gem "fastlane"
''');

  // Pluginfile
  File('android/fastlane/Pluginfile').writeAsStringSync('''# Autogenerated by fastlane
#
# This file is used to manage plugins for fastlane.
# To learn more about plugins, check out:
# https://docs.fastlane.tools/plugins/plugins-intro/

gem 'fastlane-plugin-firebase_app_distribution'
''');

  // Appfile
  File('android/fastlane/Appfile').writeAsStringSync('''json_key_file("../../service-account.json")
package_name(ENV["ANDROID_PACKAGE_NAME"] || "com.app.tahseen.dev")
''');

  // Fastfile
  File('android/fastlane/Fastfile').writeAsStringSync('''default_platform(:android)

platform :android do
  desc "Build and upload to Firebase App Distribution"
  lane :distribute do |options|
    flavor = options[:flavor] || "dev"
    app_id = ENV["FIREBASE_ANDROID_APP_ID_#{flavor.upcase}"] || ENV["FIREBASE_ANDROID_APP_ID"]
    
    unless app_id
      UI.user_error!("Missing FIREBASE_ANDROID_APP_ID for flavor #{flavor}")
    end

    # 1. Prepare project files for the target flavor
    UI.message("🔄 Switching project to flavor: #{flavor}")
    sh("cd ../.. && dart lib/core/tools/flavors/switch_default_flavor.dart #{flavor}")

    # 2. Build the Flutter APK
    sh("cd ../.. && flutter build apk --release --flavor #{flavor}")
    
    firebase_app_distribution(
      app: app_id,
      android_artifact_path: "../../build/app/outputs/flutter-apk/app-#{flavor}-release.apk",
      release_notes: options[:notes] || "Automated build for #{flavor}",
      testers_file: "../../testers.txt"
    )
  end
end
''');

  print('✅ Android Fastlane configured.');
  
  print('🔌 Installing plugins via Bundler for Android...');
  await _runCommand('bundle', ['install'], cwd: 'android', rubyBin: rubyBin);
}

// -----------------------------------------------------------------
// iOS Fastlane setup
// -----------------------------------------------------------------
Future<void> _setupIosFastlane({String? rubyBin}) async {
  final fastfile = File('ios/fastlane/Fastfile');
  if (fastfile.existsSync()) {
    print('✅ iOS Fastlane already configured. Skipping setup.');
    return;
  }

  print('\n🍎 Configuring iOS Fastlane...');
  final dir = Directory('ios/fastlane');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  // Gemfile
  File('ios/Gemfile').writeAsStringSync('''source "https://rubygems.org"
gem "fastlane"
''');

  // Pluginfile
  File('ios/fastlane/Pluginfile').writeAsStringSync('''# Autogenerated by fastlane
gem 'fastlane-plugin-firebase_app_distribution'
''');

  // Appfile
  File('ios/fastlane/Appfile').writeAsStringSync('''app_identifier(ENV["IOS_BUNDLE_ID"] || "com.app.tahseen.dev")
apple_id(ENV["APPLE_ID"])
itc_team_id(ENV["ITC_TEAM_ID"])
''');

  // Fastfile
  File('ios/fastlane/Fastfile').writeAsStringSync('''default_platform(:ios)

platform :ios do
  desc "Build and upload to Firebase App Distribution"
  lane :distribute do |options|
    flavor = options[:flavor] || "dev"
    app_id = ENV["FIREBASE_IOS_APP_ID_#{flavor.upcase}"] || ENV["FIREBASE_IOS_APP_ID"]
    
    unless app_id
      UI.user_error!("Missing FIREBASE_IOS_APP_ID for flavor #{flavor}")
    end

    # 1. Prepare project files for the target flavor
    UI.message("🔄 Switching project to flavor: #{flavor}")
    sh("cd ../.. && dart lib/core/tools/flavors/switch_default_flavor.dart #{flavor}")

    # 2. Build the Flutter IPA
    sh("cd ../.. && flutter build ipa --release --flavor #{flavor} --no-codesign")
    
    # Dynamically find the IPA
    ipa_path = Dir["../../build/ios/ipa/*.ipa"].first
    
    firebase_app_distribution(
      app: app_id,
      ipa_path: ipa_path,
      release_notes: options[:notes] || "Automated build for #{flavor}",
      testers_file: "../../testers.txt"
    )
  end
end
''');

  print('✅ iOS Fastlane configured.');
  
  print('🔌 Installing plugins via Bundler for iOS...');
  await _runCommand('bundle', ['install'], cwd: 'ios', rubyBin: rubyBin);
}

// -----------------------------------------------------------------
// Helper: Generate .env.template
// -----------------------------------------------------------------
void _generateEnvTemplate() {
  final template = '''# Fastlane & Firebase Configuration Template
# Copy this to .env and fill in the values

# Firebase App IDs (Get these from Firebase Console)
FIREBASE_ANDROID_APP_ID_DEV=1:XXXXXXXXXXXX:android:XXXXXXXXXXXXXXXXXXXXXX
FIREBASE_ANDROID_APP_ID_STATG=1:XXXXXXXXXXXX:android:XXXXXXXXXXXXXXXXXXXXXX
FIREBASE_ANDROID_APP_ID_PROD=1:XXXXXXXXXXXX:android:XXXXXXXXXXXXXXXXXXXXXX

FIREBASE_IOS_APP_ID_DEV=1:XXXXXXXXXXXX:ios:XXXXXXXXXXXXXXXXXXXXXX
FIREBASE_IOS_APP_ID_STATG=1:XXXXXXXXXXXX:ios:XXXXXXXXXXXXXXXXXXXXXX
FIREBASE_IOS_APP_ID_PROD=1:XXXXXXXXXXXX:ios:XXXXXXXXXXXXXXXXXXXXXX

# Apple Credentials (For App Store/TestFlight - optional for App Distribution)
APPLE_ID=your-email@example.com
ITC_TEAM_ID=XXXXXXXXXX

# Package Names (Optional overrides)
ANDROID_PACKAGE_NAME=com.app.tahseen.dev
IOS_BUNDLE_ID=com.app.tahseen.dev
''';

  final file = File('.env.template');
  file.writeAsStringSync(template);
  print('📝 Generated .env.template in root directory.');
}
