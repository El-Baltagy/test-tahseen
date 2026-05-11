import 'dart:io';

void main() {
  print('🔵 Generating Bitbucket Pipelines Workflow...');

  final pipelineFile = File('bitbucket-pipelines.yml');
  pipelineFile.writeAsStringSync('''image: runmymind/docker-android-sdk

pipelines:
  branches:
    staging:
      - step:
          name: Build and Deploy Dev to Firebase
          deployment: Staging
          caches:
            - gradle
          script:
            - export FLUTTER_VERSION=3.13.0
            - curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_\$FLUTTER_VERSION-stable.tar.xz
            - tar xf flutter_linux_\$FLUTTER_VERSION-stable.tar.xz
            - export PATH="\$PATH:`pwd`/flutter/bin"
            - flutter pub get
            - gem install fastlane
            - echo "\$SERVICE_ACCOUNT_JSON" > service-account.json
            - cd android && fastlane distribute flavor:dev
          services:
            - docker

    production:
      - step:
          name: Build and Deploy Prod to Firebase
          deployment: Production
          caches:
            - gradle
          script:
            - export FLUTTER_VERSION=3.13.0
            - curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_\$FLUTTER_VERSION-stable.tar.xz
            - tar xf flutter_linux_\$FLUTTER_VERSION-stable.tar.xz
            - export PATH="\$PATH:`pwd`/flutter/bin"
            - flutter pub get
            - gem install fastlane
            - echo "\$SERVICE_ACCOUNT_JSON" > service-account.json
            - cd android && fastlane distribute flavor:prod
          services:
            - docker
''');

  print('✅ Generated bitbucket-pipelines.yml');
  print('\n------------------------------------------------------------');
  print('🔵 BITBUCKET REPOSITORY VARIABLES REQUIRED:');
  print('1. SERVICE_ACCOUNT_JSON: Content of your service-account.json');
  print('2. FIREBASE_ANDROID_APP_ID: Your Firebase Android App ID');
  print('------------------------------------------------------------\n');
}
