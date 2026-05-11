import 'dart:io';

void main() async {
  print('🚀 === Tahseen CI/CD Auto-Deploy Setup === 🚀');
  print('This script will configure Fastlane, Firebase Distribution, and GitHub Actions.\n');

  // 1. Run Fastlane Setup
  _printStep('1. Configuring Fastlane (Android & iOS)');
  await _runScript('lib/core/tools/CI-CD/fastlane.dart');
  
  if (!_confirmContinue()) return;

  // 2. Run Firebase Setup & Configure App IDs
  _printStep('2. Configuring Firebase App Distribution & App IDs');
  await _runScript('lib/core/tools/CI-CD/firebase_app_distribution.dart');
  await _runScript('lib/core/tools/CI-CD/configure_app_ids.dart');

  if (!_confirmContinue()) return;

  // 3. Detect Platform and Run CI/CD Setup
  final platform = await _detectPlatform();
  _printStep('3. Generating $platform Actions/Pipelines');
  
  if (platform == 'GitHub') {
    await _runScript('lib/core/tools/CI-CD/github_actions.dart');
  } else if (platform == 'Bitbucket') {
    await _runScript('lib/core/tools/CI-CD/bitbucket_actions.dart');
  } else {
    print('❓ Remote platform not detected. Which one are you using? (1: GitHub, 2: Bitbucket)');
    final choice = stdin.readLineSync();
    if (choice == '1') {
      await _runScript('lib/core/tools/CI-CD/github_actions.dart');
    } else {
      await _runScript('lib/core/tools/CI-CD/bitbucket_actions.dart');
    }
  }

  print('\n\x1B[32m✨ CI/CD Setup Complete! ✨\x1B[0m');
  print('-------------------------------------------');
  print('🚩 FINAL CHECKLIST:');
  print('1. Download "service-account.json" from Firebase and put it in root.');
  print('2. Add your testers to "testers.txt".');
  print('3. Go to your Repository Settings > Secrets/Variables and add:');
  print('   - SERVICE_ACCOUNT_JSON');
  print('   - FIREBASE_ANDROID_APP_ID');
  print('4. Push to "staging" or "production" branch to trigger deploy!');
  print('-------------------------------------------\n');
}

bool _confirmContinue() {
  stdout.write('\n👉 Do you want to continue to the next step? (y/n): ');
  final response = stdin.readLineSync()?.toLowerCase();
  if (response != 'y') {
    print('\x1B[33m🛑 Setup paused. Re-run the script when you are ready.\x1B[0m');
    return false;
  }
  return true;
}

Future<String> _detectPlatform() async {
  try {
    final result = await Process.run('git', ['remote', '-v'], runInShell: true);
    if (result.exitCode == 0) {
      final output = result.stdout.toString().toLowerCase();
      if (output.contains('github.com')) return 'GitHub';
      if (output.contains('bitbucket.org')) return 'Bitbucket';
    }
  } catch (_) {}
  return 'Unknown';
}

void _printStep(String step) {
  print('\n🔹 $step...');
}

Future<void> _runScript(String path) async {
  final process = await Process.start(
    'dart',
    ['run', path],
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  await process.exitCode;
}
