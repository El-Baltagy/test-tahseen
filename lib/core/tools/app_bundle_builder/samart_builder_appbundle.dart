import 'dart:convert';
import 'dart:io';
import 'flavors/switch_default_flavor.dart' as flavor_switcher;

/// 🚀 Smart Builder Pro 🚀
///
/// Usage:
///   dart tools/samart_builder_appbundle.dart [version-flags] [build-flags] [git-flags]
///
/// Version Flags:
///   --major       : Bump major version (2.0.0 -> 3.0.0)
///   --minor       : Bump minor version (2.1.0 -> 2.2.0)
///   --patch       : Bump patch version (2.1.3 -> 2.1.4)
///   --keep        : Keep current version (just build)
///
/// Build Flags:
///   --apk         : Build Android APK
///   --bundle      : Build Android App Bundle (Default)
///   --ipa         : Build iOS IPA (Mac only)
///   --no-build    : Skip build entirely (update version only)
///
/// Git Flags:
///   --git-commit  : Commit the version change automatically
///   --git-tag     : Create a git tag (e.g., v1.0.0+1)
///   --push        : Push changes and tags to remote (implies --git-commit and --git-tag)
///
/// Example:
///   dart tools/samart_builder_appbundle.dart --minor --apk --git-tag

Future<void> main(List<String> args) async {
  print('\n🤖 ------------------------------------------');
  print('      Welcome to Smart Builder Pro        ');
  print('------------------------------------------ 🤖\n');

  final File pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) _exit('❌ pubspec.yaml not found');

  // 1. Parsing pubspec.yaml
  final List<String> lines = pubspec.readAsLinesSync();
  final int versionIndex = lines.indexWhere((l) => l.trim().startsWith('version:'));
  if (versionIndex == -1) _exit('❌ version not found in pubspec.yaml');

  final String oldVersionRaw = lines[versionIndex].split(':').last.trim();
  final AppVersion oldVersion = AppVersion.parse(oldVersionRaw);

  print('📌 Current Version: $oldVersionRaw');

  // 2. Determine New Version
  final AppVersion newVersion = oldVersion.clone();
  bool versionChanged = false;

  if (args.contains('--major')) {
    newVersion.bumpMajor();
    versionChanged = true;
  } else if (args.contains('--minor')) {
    newVersion.bumpMinor();
    versionChanged = true;
  } else if (args.contains('--patch')) {
    newVersion.bumpPatch();
    versionChanged = true;
  } else if (args.contains('--keep')) {
    print('⏸️  Keeping version unchanged.');
  } else {
    // If no flag provided, ask user or error out? 
    // For safety, let's strictly require a flag unless it's a dry run.
    _exit('⚠️  Please specify a version bump: --major, --minor, --patch, or --keep');
  }

  // 3. Write New Version
  if (versionChanged) {
    if (args.contains('--keep')) {
       // logic collision, but code flows naturally. If keep is there, we didn't bump.
    } else {
       // Always increment build number if not strictly "keeping" exact version?
       // Usually CD pipelines increment build number on every run.
       // Here we only increment build number if version changed OR if we assume build ref.
       // Let's stick to standard: bump version = bump build. 
    }
    
    lines[versionIndex] = 'version: $newVersion';
    pubspec.writeAsStringSync(lines.join('\n'));
    print('✅ Version bumped: $oldVersionRaw ➡️ $newVersion');
  }

  // 4. Git Integration
  if (args.contains('--git-commit') || args.contains('--push') || args.contains('--git-tag')) {
    await _runCommand('git', ['add', 'pubspec.yaml']);
    if (args.contains('--git-commit') || args.contains('--push')) {
      final String message = "🔖 Bump version to $newVersion";
      await _runCommand('git', ['commit', '-m', message]);
    }
  }

  if (args.contains('--git-tag') || args.contains('--push')) {
    final String tagName = "v$newVersion";
    // Check if tag exists
    final tagExists = await _runSilently('git', ['rev-parse', tagName]);
    if (tagExists) {
        print('⚠️  Tag $tagName already exists. Skipping tag.');
    } else {
        await _runCommand('git', ['tag', '-a', tagName, '-m', 'Release $newVersion']);
    }
  }

  if (args.contains('--push')) {
    print('⬆️  Pushing to remote...');
    await _runCommand('git', ['push']);
    await _runCommand('git', ['push', '--tags']);
  }

  // 5. Flavor Protection
  if (!args.contains('--no-build')) {
    print('🎨 Switching to PRODUCTION flavor...');
    await flavor_switcher.main(['prod']);
  }

  // 6. Build
  if (args.contains('--no-build')) {
    print('🏁 Done (Skipping build).');
    return;
  }

  String buildCmd = 'appbundle'; // Default
  if (args.contains('--apk')) buildCmd = 'apk';
  if (args.contains('--ipa')) buildCmd = 'ipa';

  print('🚀 Starting Flutter Build ($buildCmd)...');
  
  // Using start to stream output
  final Process process = await Process.start(
      Platform.isWindows ? 'flutter.bat' : 'flutter',
      [
        'build', 
        buildCmd, 
        '--release', 
        '--obfuscate', 
        '--split-debug-info=build/app/outputs/symbols'
      ],
      runInShell: true,
  );


  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);

  final int exitCode = await process.exitCode;
  if (exitCode == 0) {
    print('\n🎉 Build Success!');
  } else {
    print('\n❌ Build Failed with exit code $exitCode');
    exit(exitCode);
  }
}

// --- Helpers ---

class AppVersion {
  int major;
  int minor;
  int patch;
  int build;

  AppVersion(this.major, this.minor, this.patch, this.build);

  static AppVersion parse(String raw) {
    try {
      final parts = raw.split('+');
      final versionParts = parts[0].split('.');
      final build = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      return AppVersion(
        int.parse(versionParts[0]),
        int.parse(versionParts[1]),
        int.parse(versionParts[2]),
        build,
      );
    } catch (e) {
      _exit('❌ Failed to parse version "$raw". Ensure it follows X.Y.Z+N format.');
      throw e; 
    }
  }

  void bumpMajor() { major++; minor=0; patch=0; build++; }
  void bumpMinor() { minor++; patch=0; build++; }
  void bumpPatch() { patch++; build++; }
  
  AppVersion clone() => AppVersion(major, minor, patch, build);

  @override
  String toString() => '$major.$minor.$patch+$build';
}

Future<void> _runCommand(String cmd, List<String> args) async {
  print('   > $cmd ${args.join(' ')}');
  final result = await Process.run(cmd, args, runInShell: true);
  if (result.exitCode != 0) {
    print('❌ Command failed: ${result.stderr}');
    exit(result.exitCode);
  }
}

Future<bool> _runSilently(String cmd, List<String> args) async {
  final result = await Process.run(cmd, args, runInShell: true);
  return result.exitCode == 0;
}

Never _exit(String message) {
  print(message);
  exit(1);
}
