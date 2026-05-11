import 'dart:io';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final report = File('unused_files_report.txt');

  if (!report.existsSync()) {
    print('❌ Error: No report found. Run detect_unused.dart first.');
    return;
  }

  final lines = report.readAsLinesSync()
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .toList();

  if (lines.isEmpty) {
    print('✅ No unused files to delete.');
    return;
  }

  print('${dryRun ? "[DRY RUN] " : ""}Deleting ${lines.length} files...');
  
  for (final path in lines) {
    final file = File(path);
    if (file.existsSync()) {
      if (dryRun) {
        print('Would delete: $path');
      } else {
        file.deleteSync();
        print('Deleted: $path');
      }
    }
  }
  
  if (!dryRun) report.deleteSync();
  print('✨ Cleanup complete.');
}
