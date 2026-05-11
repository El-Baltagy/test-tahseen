import 'dart:io';

void main() {
  print('🐙 Generating GitHub Actions Workflow...');

  final workflowDir = Directory('.github/workflows');
  if (!workflowDir.existsSync()) workflowDir.createSync(recursive: true);

  final workflowFile = File('.github/workflows/deploy.yml');
  workflowFile.writeAsStringSync('''name: Build & Deploy to Firebase

on:
  push:
    branches: [ staging, production ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.13.0'
        cache: true

    - name: Setup Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.0'
        bundler-cache: true

    - name: Install Dependencies
      run: flutter pub get

    - name: Install Fastlane
      run: gem install fastlane

    - name: Create Service Account File
      run: echo '\${{ secrets.SERVICE_ACCOUNT_JSON }}' > service-account.json

    - name: Deploy Android to Firebase
      run: cd android && fastlane distribute flavor:\${{ github.ref_name == 'staging' && 'dev' || 'prod' }}
      env:
        FIREBASE_ANDROID_APP_ID: \${{ secrets.FIREBASE_ANDROID_APP_ID }}

    # Optional: iOS deployment (requires macOS runner)
    # - name: Deploy iOS to Firebase
    #   run: cd ios && fastlane distribute flavor:\${{ github.ref_name == 'staging' && 'dev' || 'prod' }}
    #   env:
    #     FIREBASE_IOS_APP_ID: \${{ secrets.FIREBASE_IOS_APP_ID }}
    #     APPLE_ID: \${{ secrets.APPLE_ID }}
    #     ITC_TEAM_ID: \${{ secrets.ITC_TEAM_ID }}
''');

  print('✅ Generated .github/workflows/deploy.yml');
  print('\n------------------------------------------------------------');
  print('🐙 GITHUB SECRETS REQUIRED:');
  print('1. SERVICE_ACCOUNT_JSON: Content of your service-account.json');
  print('2. FIREBASE_ANDROID_APP_ID: Your Firebase Android App ID');
  print('------------------------------------------------------------\n');
}
