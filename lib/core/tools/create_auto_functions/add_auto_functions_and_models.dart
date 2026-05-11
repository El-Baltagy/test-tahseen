import 'dart:convert';
import 'dart:io';
import '../create_auto_files/path_constants.dart';
import '../create_auto_files/main_script.dart' as main_script;
import '../model_creation/create_entity.dart' as create_entity;
import 'add_function_script.dart' as add_function_script;

void main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Please provide the path to your Postman Collection JSON file.');
    print('Usage: tahseen_func <path_to_collection.json>');
    return;
  }

  final file = File(args[0]);

  if (!file.existsSync()) {
    print('❌ Postman collection not found at: ${args[0]}');
    return;
  }
  final content = await file.readAsString();
  final data = json.decode(content);
  final items = data['item'] as List;

  for (var folder in items) {
    if (folder['item'] == null) continue;
    final String folderName = folder['name'] as String;
    print('🚀 Processing folder: $folderName');

    // 1. Create screen/feature structure
    final featureDir = Directory('lib/features/screens/$folderName');
    if (!featureDir.existsSync()) {
      print('   Creating feature structure for: $folderName');
      // Call the logic directly instead of Process.start
      await main_script.main([folderName, '--no-build']);
    } else {
      print('   ⏭️ Feature structure already exists for: $folderName');
    }

    final subItems = folder['item'] as List;
    for (var methodItem in subItems) {
      final String methodName = methodItem['name']as String ;
      final request = methodItem['request'];
      final responseArr = methodItem['response'] as List?;
      
      print('   🛠️ Processing method: $methodName');

      String responseBody = "{}";
      if (responseArr != null && responseArr.isNotEmpty) {
        responseBody = (responseArr[0]['body'] ?? "{}" )as String;
      }

      // 2. Create Model
      final className = toPascalCase(methodName);
      
      // Save response body to data.json
      // We need to ensure this path is relative to the current project or a temp location
      final dataJson = File('lib/core/tools/model_creation/data.json');
      if (!dataJson.parent.existsSync()) dataJson.parent.createSync(recursive: true);
      await dataJson.writeAsString(responseBody);
      
      print('      Generating model: $className');
      await create_entity.main([className, folderName, '--no-build']);

      // 3. Create Request Parameter Class
      await _createReqParamClass(folderName, methodName, request);

      // 4. Add API to EndPoints
      await _addApiToEndPoints(methodName, request);

      // 5. Add function to Repo, Service, and Cubit
      print('      Adding function to layers: $methodName');
      await add_function_script.main([
        folderName,
        methodName,
        className,
        '${toPascalCase(methodName)}ReqParam',
      ]);
    }
  }

  // 6. Final Build Runner
  print('🚀 Running final build_runner for all generated files...');
  final buildRunnerProcess = await Process.start(
    'D:/programmes/flutter_3.38/flutter/bin/flutter.bat',
    ['pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs'],
  );
  buildRunnerProcess.stdout.transform(utf8.decoder).listen((data) => stdout.write('[build_runner] $data'));
  buildRunnerProcess.stderr.transform(utf8.decoder).listen((data) => stderr.write('[build_runner ERROR] $data'));
  await buildRunnerProcess.exitCode;

  print('✅ All tasks finished successfully.');
}



String _toSnakeCase(String input) {
  return input.replaceAllMapped(RegExp(r'(?<!^)([A-Z])'), (Match m) => '_${m.group(0)}').toLowerCase();
}

Future<void> _createReqParamClass(String folderName, String methodName, dynamic request) async {
  final className = '${toPascalCase(methodName)}ReqParam';
  final modelFolder = _toSnakeCase(toPascalCase(methodName));
  final fileName = '${_toSnakeCase(methodName)}_req_param.dart';
  final dirPath = 'lib/features/screens/$folderName/data/model/$modelFolder';
  final dir = Directory(dirPath);
  if (!dir.existsSync()) dir.createSync(recursive: true);
  
  final buffer = StringBuffer();
  buffer.writeln("class $className {");
  
  List<Map<String, String>> params = [];
  
  // Extract headers (excluding common ones like Authorization)
  if (request['header'] != null) {
    for (var h in request['header'] ) {
      if (h['key'].toString().toLowerCase() == 'authorization') continue;
      params.add({'key': h['key'], 'value': 'String'});
    }
  }
  
  // Extract query parameters
  if (request['url'] != null && request['url']['query'] != null) {
    for (var q in request['url']['query']) {
      params.add({'key': q['key'], 'value': 'String'});
    }
  }
  
  // Extract body parameters (formdata)
  if (request['body'] != null && request['body']['formdata'] != null) {
    for (var f in request['body']['formdata']) {
       params.add({'key': f['key'], 'value': 'String'});
    }
  }

  // Deduplicate params
  final seenKeys = <String>{};
  final uniqueParams = <Map<String, String>>[];
  for (var p in params) {
    if (seenKeys.add(p['key']!)) {
      uniqueParams.add(p);
    }
  }

  for (var p in uniqueParams) {
    buffer.writeln("  final ${p['value']} ${p['key']};");
  }
  
  if (uniqueParams.isNotEmpty) {
    buffer.writeln("\n  $className({");
    for (var p in uniqueParams) {
      buffer.writeln("    required this.${p['key']},");
    }
    buffer.writeln("  });");
  } else {
    buffer.writeln("\n  $className();");
  }
  
  buffer.writeln("\n  Map<String, dynamic> toJson() => {");
  for (var p in uniqueParams) {
    buffer.writeln("    '${p['key']}': ${p['key']},");
  }
  buffer.writeln("  };");
  buffer.writeln("}");

  await File('${dir.path}/$fileName').writeAsString(buffer.toString());
  print('      ✅ Created Request Param class: $className');
}

Future<void> _addApiToEndPoints(String methodName, dynamic request) async {
  final file = File('lib/core/constants/app_api.dart');
  if (!file.existsSync()) return;
  String content = await file.readAsString();
  
  final urlData = request['url'];
  String path = "";
  if (urlData is String) {
    path = urlData;
  } else if (urlData is Map) {
    path = urlData['raw'] ?? "";
  }
  
  path = path.replaceFirst(RegExp(r'^https?://[^/]+'), '').replaceFirst('{{url}}', '');
  if (path.contains('?')) {
    path = path.split('?')[0];
  }
  
  final endpointName = methodName;
  final endpointLine = "  static const String $endpointName = \"$path\";";
  
  if (!content.contains('String $endpointName =')) {
    content = content.replaceFirst('abstract class EndPoints {', 'abstract class EndPoints {\n$endpointLine');
    await file.writeAsString(content);
    print('      ✅ Added Endpoint: $endpointName');
  }
}
String toPascalCase(String input) {
  return input.split('_').map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join();
}
