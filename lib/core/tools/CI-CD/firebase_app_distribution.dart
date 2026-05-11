import 'dart:io';

void main() async {
  print('🔥 Setting up Firebase App Distribution helper...');

  // 1. Create testers.txt
  final testersFile = File('testers.txt');
  if (!testersFile.existsSync()) {
    print('\n👥 No testers.txt found.');
    print('Please enter the emails of your testers (separated by commas or spaces),');
    print('or just press Enter to use defaults:');

    String? input = stdin.readLineSync();
    if (input == null || input.trim().isEmpty) {
      testersFile.writeAsStringSync('tester1@example.com\ntester2@example.com');
      print('✅ Created testers.txt with placeholder emails.');
    } else {
      // Clean up input and join with newlines
      final emails = input
          .split(RegExp(r'[,\s]+'))
          .map((e) => e.trim())
          .where((e) => e.contains('@'))
          .join('\n');

      if (emails.isEmpty) {
        testersFile.writeAsStringSync('tester1@example.com');
        print('⚠️ No valid emails detected. Created testers.txt with a placeholder.');
      } else {
        testersFile.writeAsStringSync(emails);
        print('✅ Created testers.txt with ${emails.split('\n').length} testers.');
      }
    }
  } else {
    print('✅ testers.txt already exists.');
  }

  // 2. Check for Firebase CLI
  if (!await _checkCommand('firebase')) {
    print('⚠️ Firebase CLI not found. Please install it: npm install -g firebase-tools');
  } else {
    print('✅ Firebase CLI found.');
  }

  // 3. Provide Service Account instructions
  print('\n' + '━' * 60);
  print('🔑 SERVICE ACCOUNT SETUP (REQUIRED FOR AUTO-DEPLOY):');
  print('1. Go to: https://console.firebase.google.com/');
  print('2. Project Settings > Service Accounts.');
  print('3. Click "Generate New Private Key".');
  print('4. Save it as "service-account.json" in this project root.');
  print('5. 💡 We have already added this file to your .gitignore for safety.');
  print('━' * 60 + '\n');

  _updateGitignore();
}

void _updateGitignore() {
  final gitignore = File('.gitignore');
  if (gitignore.existsSync()) {
    String content = gitignore.readAsStringSync();
    if (!content.contains('service-account.json')) {
      gitignore.writeAsStringSync('$content\n\n# Firebase Secrets\nservice-account.json\n');
      print('✅ Verified service-account.json is in .gitignore');
    }
  }
}

Future<bool> _checkCommand(String cmd) async {
  try {
    final result = await Process.run(cmd, ['--version'], runInShell: true);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}
