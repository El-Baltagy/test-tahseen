// tool/generate_screen_exports.dart
//
// Usage: dart run tool/generate_screen_exports.dart
//
// Scans lib/ for screens with @RoutePage + Stateless/StatefulWidget.
// For each, generates <screen>_export.dart with all imports (as exports),
// and rewrites the screen to import only its exporter.


import 'dart:io';


Future<void> main() async {
  // Define your paths clearly
  const String featureTxt = 'lib/features';
  const String exportTxt = 'lib/export';
  const String packageName = 'tahseen';// from pubspec.yaml

  final libFeaturesDir = Directory(featureTxt);

  if (!libFeaturesDir.existsSync()) {
    print('Error: Folder $featureTxt not found');
    exit(1);
  }

  print('🚀 Generating export mirrored files...');
  /// 1-  if export file not  found create
  var res= await createMirroredExports(libFeaturesDir, exportTxt, packageName);
  /// 2- convert all exports into imports
  await convertExportsToImports(res.$2);
  /// 3-  put it back  into the original path
  await putConvertsExportsIntoOrigionalPath(res.$2);
  /// 4-  run fixer to remove unused import
  await runFixer();
  /// 5- fix relative path To Import Path
   fixRelativePathToImportPath(libFeaturesDir,packageName);
  /// 6- export all imports
  await exportImports( res.$1,featureTxt,exportTxt,packageName);
  print('✅ Done!');
}

Future<(List<File>,List<File>)> createMirroredExports(Directory sourceDir, String targetBase, String packageName) async {
  // 1. Get all dart files
  final dartFiles = sourceDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('.g.'))
      .where((f) => !f.path.contains('.freezed.'))
  ;
  List<File>listExport=[];
  for (final file in dartFiles) {
    // Standardize path to forward slashes for easier manipulation
    String standardPath = file.path.replaceAll('\\', '/');

    // 2. Create the Physical File Path
    // Example: lib/features/auth/login.dart -> lib/export/auth/login.dart
    String localPath = standardPath.replaceFirst(sourceDir.path, targetBase);
    File newFile = File(localPath);
    listExport.add(newFile);
    // 3. Create the Package Export String
    // Example: package:${PathConstants().projectName}/features/auth/login.dart
    // String exportString = standardPath.replaceFirst('lib/', 'package:$packageName/');

    if (!newFile.parent.existsSync()) {
      // 4. Ensure the sub-directories exist before writing
      // (If lib/export/auth/ doesn't exist, newFile.writeAsString will crash)
      await newFile.parent.create(recursive: true);
    }

    if (!newFile.existsSync()) {
      // 5. Write the actual export line into the file
      await newFile.writeAsString("//this is auto generated don't edit manually just run script exporter");
    }

  }
  return (dartFiles.toList(),listExport);
}

Future<void> convertExportsToImports(List<File> listFiles) async{
  for (final File file in listFiles) {
    if (file.existsSync()) {
      final String content=await file.readAsString();
      List<String> importLines = content
          .split('\n')
          .where((line) => line.trim().startsWith('export'))
          .toList();
      StringBuffer stringBuffer = StringBuffer();
      for(String  importLine in importLines){
        stringBuffer.writeln( importLine.replaceFirst('export', 'import'));
      }
      await file.writeAsString(stringBuffer.toString());
    }
  }

}

Future<void> putConvertsExportsIntoOrigionalPath(List<File> listFiles) async{
  for (final File file in listFiles) {
    if (file.existsSync()) {
      final String content=await file.readAsString();
      List<String> importLines = content
          .split('\n')
          .where((line) => line.trim().startsWith('import'))
          .toList();
      File origionalFile=File(file.path.replaceFirst("export", 'features'));
      if (origionalFile.existsSync()) {
        StringBuffer buffer = StringBuffer();
        for(var x in importLines){
          buffer.writeln(x);
        }

      String orgTxt=await  origionalFile.readAsString();
        buffer.writeln(orgTxt);
        await origionalFile.writeAsString(buffer.toString());
      }
    }
  }

}

Future<void> runFixer() async {
  print("🚀 Starting cleanup...");

  // 1. Run Dry Run
  print("Checking for fixes...");
  final dryRun = await Process.run('dart', ['fix', '--dry-run']);
  stdout.write(dryRun.stdout); // Print output to console

  if (dryRun.exitCode == 0) {
    // 2. Run Apply (Only if dry run didn't crash)
    print("\nApplying fixes...");
    final applyFix = await Process.run('dart', ['fix', '--apply']);
    stdout.write(applyFix.stdout);

    if (applyFix.exitCode == 0) {
      print("✅ Successfully cleaned up imports!");
    }
  } else {
    stderr.write(dryRun.stderr);
    print("❌ Dry run failed.");
  }
}

void fixRelativePathToImportPath(Directory libDir,String projectName) {

  libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .forEach((file) {
    var content = file.readAsStringSync();

    // Regex to match relative imports
    final regex = RegExp(r"import\s+'(\.\./[^']+)';");

    content = content.replaceAllMapped(regex, (match) {
      final relativePath = match.group(1)!;
      final absolutePath = File(file.path)
          .parent
          .uri
          .resolve(relativePath)
          .path
          .replaceAll('\\', '/');

      // Strip leading "lib/"
      final libIndex = absolutePath.indexOf('/lib/');
      final packagePath = absolutePath.substring(libIndex + 5);

      return "import 'package:$projectName/$packagePath';";
    });

    file.writeAsStringSync(content);
    print('Fixed imports in ${file.path}');
  });
}

Future<void>exportImports(List<File> listOriginalFiles,String sourcePath, String targetBase,String packageName)async{
  for(File originalFile in listOriginalFiles){

   String originalContent=await originalFile.readAsString();
    final importLines = originalContent
        .split('\n')
        .where((line) => line.trim().startsWith('import'))
        .toList();

   // 3. Write it back
   final String expTxt=_exporterTextInOrigionalSc(originalFile.path,
   sourcePath,targetBase,packageName
   );
   StringBuffer orgBuffer = StringBuffer();
   orgBuffer.writeln("import '${expTxt}';");
   orgBuffer.writeln(originalContent.replaceFirst(importLines.join('\n'), ''));
   await originalFile.writeAsString(orgBuffer.toString());
    StringBuffer buffer = StringBuffer();


    for (final imp in importLines) {
      if (imp!=expTxt) {
        String path=imp  ; // keep semicolon
       if (!path.contains('/')) {
         // Find the position of the last slash
         int lastSlashIndex = _exporterTextInOrigionalSc(originalFile.path,
             sourcePath,
             sourcePath,
           packageName
         ).lastIndexOf('/');
         StringBuffer buffer = StringBuffer();
         buffer.writeln(_exporterTextInOrigionalSc(originalFile.path,
             sourcePath,
             sourcePath,
             packageName
         ).substring(0, lastSlashIndex + 1).trim());
         buffer.writeln(path.replaceAll(RegExp(r"^import '|';$"), ''));

         path = "import '${buffer.toString().replaceAll('\n', '')}';" ;
       }
        path = path.replaceFirst('import', 'export');
        buffer.writeln(path);
      }

    }


    File fileExporter=File(_getExportPathFromOriginalPath(originalFile.path));
    await fileExporter.writeAsString(buffer.toString(),mode: FileMode.append);
  }
}


String _getExportPathFromOriginalPath(String path){
  return path.replaceFirst("features", 'export');
}
String _exporterTextInOrigionalSc(String filePath,String sourcePath, String targetBase,String packageName){

  return  filePath.replaceAll('\\', '/')
      .replaceFirst(sourcePath, targetBase)
      .replaceFirst('lib/', 'package:$packageName/')
  ;

}
