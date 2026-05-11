import 'dart:io';
import 'dart:convert';
import 'add_new_flavor.dart';

void main(List<String> args) async {
  final bool isRemove = args.contains('--remove');

  if (isRemove) {
    print('🗑️ Removing Flutter Flavorizr configuration...');
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) return;

    String content = pubspecFile.readAsStringSync();
    if (content.contains('\nflavorizr:')) {
      final startIndex = content.indexOf('\nflavorizr:');
      content = content.substring(0, startIndex).trim();
      pubspecFile.writeAsStringSync(content + '\n');
      print('✅ Successfully removed flavorizr config from pubspec.yaml');
    } else {
      print('ℹ️ No flavorizr configuration found.');
    }
    return;
  }

  print('🛠️ Setting up Flutter Flavorizr...');

  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('❌ pubspec.yaml not found');
    return;
  }

  // 1. Get Project Name
  String projectName = 'tahseen';
  String pubContent = pubspecFile.readAsStringSync();
  final nameMatch = RegExp(r'^name:\s*(.+)$', multiLine: true).firstMatch(pubContent);
  if (nameMatch != null) projectName = nameMatch.group(1)!.trim();

  // 2. Ensure app_config.dart exists
  final appConfigFile = File('lib/flavor_config.dart');
  if (!appConfigFile.existsSync()) {
    print('📂 app_config.dart not found. Creating it for the first time...');
    final template = '''
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:$projectName/core/api_helper/dio_helper.dart';
import 'package:$projectName/core/api_helper/interceptor/attestation_interceptor.dart';
import 'package:$projectName/core/api_helper/interceptor/auth_interceptor.dart';
import 'package:$projectName/core/api_helper/interceptor/retry_interceptor.dart';
import 'package:$projectName/core/api_helper/interceptor/signer_interceptor.dart';
import 'package:$projectName/core/api_helper/interceptor/ssl_pinning_check.dart';

enum Flavor { dev, prod }

class AppFlavorConfig {
  final String baseUrl;
  final String appTitle;
  final Flavor flavor;
  final List<Interceptor> interceptors;
  final FirebaseOptions? firebaseOptions;
  static AppFlavorConfig? _instance;

  factory AppFlavorConfig({
    required String baseUrl,
    required String appTitle,
    required Flavor flavor,
    required List<Interceptor> interceptors,
    required FirebaseOptions? firebaseOptions,
  }) {
    _instance ??= AppFlavorConfig._(baseUrl, appTitle, flavor, interceptors,firebaseOptions);
    return _instance!;
  }

  AppFlavorConfig._(this.baseUrl, this.appTitle, this.flavor, this.interceptors,this.firebaseOptions);

  static AppFlavorConfig get instance {
    if (_instance == null) {
      throw Exception('AppConfig has not been initialized. Call initialize() in main().');
    }
    return _instance!;
  }

  static bool get isDev => instance.flavor == Flavor.dev;
  static bool get isProd => instance.flavor == Flavor.prod;

  static const String _rawFlavor = String.fromEnvironment('FLUTTER_APP_FLAVOR');

  static void initialize() {
    switch (_rawFlavor) {
      case 'dev' || '':
        AppFlavorConfig(
        firebaseOptions:null,
          flavor: Flavor.dev,
          baseUrl: 'https://dev-api.$projectName.com',
          appTitle: '${projectName[0].toUpperCase()}${projectName.substring(1)} [DEV]',
          interceptors: [],
        );
        break;
      case 'prod':
        AppFlavorConfig(
          firebaseOptions:null,
          flavor: Flavor.prod,
          baseUrl: 'https://api.$projectName.com',
          appTitle: '${projectName[0].toUpperCase()}${projectName.substring(1)}',
          interceptors: [
            SSLPinningCheck(),
            AttestationInterceptor(),
            AuthInterceptor(
              dio: DioHelper().dio,
              getAccessToken: DioHelper().getToken,
              refreshToken: DioHelper().refreshToken,
            ),
            SignerInterceptor(getToken: DioHelper().getToken),
            RetryInterceptor(),
          ]
        );
        break;
    }
  }
}
''';
    appConfigFile.parent.createSync(recursive: true);
    appConfigFile.writeAsStringSync(template);
    print('✅ Successfully created initial lib/core/constants/app_config.dart');
  }


  // 3. Add dev_dependency if missing
  if (!pubContent.contains('flutter_flavorizr:')) {
    print('➕ Adding flutter_flavorizr to dev_dependencies...');
    await Process.run('flutter', ['pub', 'add', 'dev:flutter_flavorizr'], runInShell: true);
    pubContent = pubspecFile.readAsStringSync(); // Reload
  }

  // 4. Generate flavorizr config matching user request
  print('📝 Generating flavorizr configuration...');
  final buffer = StringBuffer();
  buffer.writeln('\nflavorizr:');
  buffer.writeln('  app:');
  buffer.writeln('    android:');
  buffer.writeln('      flavorDimensions: "flavor-type"');
  buffer.writeln('\n  instructions:');
  buffer.writeln('    - "android:androidManifest"');
  buffer.writeln('    - "android:flavorizrGradle"');
  buffer.writeln('    - "android:buildGradle"');
  buffer.writeln('    - "android:icons"');
  buffer.writeln('    - "ios:podfile"');
  buffer.writeln('    - "ios:xcconfig"');
  buffer.writeln('    - "ios:buildTargets"');
  buffer.writeln('    - "ios:schema"');
  buffer.writeln('    - "ios:icons"');
  buffer.writeln('    - "ios:plist"');
  buffer.writeln('    - "ios:launchScreen"');
  buffer.writeln('    - "google:firebase"');
  buffer.writeln('\n  flavors:');

  // dev flavor
  buffer.writeln('    dev:');
  buffer.writeln('      app:');
  buffer.writeln('        name: "Tahseen [DEV]"');
  buffer.writeln('      android:');
  buffer.writeln('        applicationId: "com.app.tahseen.dev"');
  buffer.writeln('      ios:');
  buffer.writeln('        bundleId: "com.app.tahseen.dev"');
  buffer.writeln('      icon: "assets/Main Icon.png"');
  buffer.writeln('      firebase:');
  buffer.writeln('        config: "ios/Runner/Firebase/dev/GoogleService-Info.plist"');

  // prod flavor
  buffer.writeln('    prod:');
  buffer.writeln('      app:');
  buffer.writeln('        name: "Tahseen"');
  buffer.writeln('      android:');
  buffer.writeln('        applicationId: "com.app.tahseen.tahseen"');
  buffer.writeln('      ios:');
  buffer.writeln('        bundleId: "com.app.tahseen.tahseen"');
  buffer.writeln('      icon: "assets/Main Icon.png"');
  buffer.writeln('      firebase:');
  buffer.writeln('        config: "ios/Runner/Firebase/prod/GoogleService-Info.plist"');

  // Remove existing flavorizr config if any
  if (pubContent.contains('\nflavorizr:')) {
     final startIndex = pubContent.indexOf('\nflavorizr:');
     pubContent = pubContent.substring(0, startIndex).trim();
  }

  pubspecFile.writeAsStringSync(pubContent.trim() + buffer.toString());
  createAndroidFlavorFolders('dev');
  createAndroidFlavorFolders('prod');
  print('✅ Successfully configured flavorizr in pubspec.yaml');

  print('\n✅ File updates completed!');
  print('------------------------------------------------------------');
  print('👉 FINAL STEP: To update icons and native manifests,');
  print('   please copy and paste the following command into your terminal:');
  print('------------------------------------------------------------\n');

  print(getFlavorizrCommand());


}
