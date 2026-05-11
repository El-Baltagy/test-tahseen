import 'dart:io';

Future<void> main() async {
  final envFile = File('.env');
  final androidPath = 'android/fastlane/.env';
  
  print('\n📝 Let\'s set up your Firebase App IDs.');
  print('You can find these in Firebase Console > Project Settings.');

  String content = '# Fastlane & Firebase Configuration\n';
     content += 'FIREBASE_ANDROID_APP_ID_DEV=replace_me_with_DEV_App_ID\n';
      content += 'FIREBASE_ANDROID_APP_ID_PROD=replace_me_with_PROD_App_ID\n';


     content += 'FIREBASE_ANDROID_APP_ID=replace_me_with_DEV_App_ID\n';

  // Write to root and to android/fastlane
  envFile.writeAsStringSync(content);
  
  final fastlaneEnv = File(androidPath);
  if (!fastlaneEnv.parent.existsSync()) {
    fastlaneEnv.parent.createSync(recursive: true);
  }
  fastlaneEnv.writeAsStringSync(content);

  print('\x1B[32m✅ Generated .env file in root and $androidPath\x1B[0m');
}
