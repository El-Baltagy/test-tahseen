import 'dart:convert';
import 'dart:io';
import '../create_auto_files/path_constants.dart';
import 'package:${PathConstants().projectName}/core/tools/create_auto_files/path_constants.dart';
import 'package:${PathConstants().projectName}/core/tools/create_auto_files/route_generator_data.dart';

import 'add_auto_functions_and_models.dart';

// ─── Entry Point ─────────────────────────────────────────────────────────────
//
// Usage:
//   dart run lib/core/tools/create_auto_functions/add_function_script.dart \
//       <featureName> <functionName> <returnType> <paramType>
//
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main(List<dynamic> args) async {
  if (args.length < 4) {
    _printUsage();
    exit(1);
  }

  final featureName  = args[0].toString();
  final functionName = args[1].toString();
  final returnType   = args[2].toString();
  final paramType    = args[3].toString();

  PathConstants().setData(featureName);
  final p = PathConstants();

  final baseFeature = 'lib/features/screens/$featureName';
  final repoPath    = '$baseFeature/data/repo/remote/${featureName}_repo.dart';
  final svcPath     = '$baseFeature/service/${p.serviceFileName()}';
  final cubitPath   = '$baseFeature/controller/${p.cubitFileName()}';
  final statePath   = '$baseFeature/controller/${p.stateFileName()}';

  final requiredFiles = [repoPath, svcPath, cubitPath, statePath];
  for (final path in requiredFiles) {
    if (!File(path).existsSync()) {
      stderr.writeln('❌ File not found: $path');
      exit(1);
    }
  }

  print('📝 Adding "$functionName" to all layers of "$featureName"...');

  final String snakeMethod = functionName.replaceAllMapped(RegExp(r'(?<!^)([A-Z])'), (Match m) => '_${m.group(0)}').toLowerCase();

  // ── 1. AppConstant ───────────────────────────────────────────────────────
  final keyCodeName = '${functionName}KeyCode';
  final cacheKeyName = '${functionName}KeyCash';
  await _registerConstant(cacheKeyName, '${featureName}_${functionName}_cache');
  await _registerIntConstant(keyCodeName, '${featureName}_$functionName'.hashCode % 10000);

  // ── 2. Remote Repo ───────────────────────────────────────────────────────
  await _injectImport(filePath: repoPath, importLine: "import 'package:${PathConstants().projectName}/core/constants/app_constant.dart';");
  await _injectImport(filePath: repoPath, importLine: "import 'package:dartz/dartz.dart';");
  await _injectImport(filePath: repoPath, importLine: "import 'package:${PathConstants().projectName}/core/api_helper/dio_error_handler.dart';");
  await _injectImport(filePath: repoPath, importLine: "import 'package:${PathConstants().projectName}/features/screens/$featureName/data/model/$snakeMethod/$snakeMethod.dart';");
  await _injectImport(filePath: repoPath, importLine: "import 'package:${PathConstants().projectName}/features/screens/$featureName/data/model/$snakeMethod/${snakeMethod}_req_param.dart';");

  await _injectIntoClass(
    filePath: repoPath,
    className: p.repoName(),
    displayName: 'remote repo',
    injection: '''
   Future<Either<Failure, $returnType>> ${toPascalLowerCase(functionName)+'Api'}(
    $paramType? parameter, {
    CancelToken? cancelToken,
  }) async {
    return handleResponse(
      onCallData: dio.getData(
        uri: EndPoints.$functionName,
        cancelToken: cancelToken,
      ),
      asObject: $returnType.fromJson,
    );
  }''',
    checkDuplicate: 'Future<Either<Failure, $returnType>> ${toPascalLowerCase(functionName)+'Api'}(',
  );

  // ── 3. Service ───────────────────────────────────────────────────────────
  await _injectImport(filePath: svcPath, importLine: "import 'package:${PathConstants().projectName}/core/constants/app_constant.dart';");
  await _injectImport(filePath: svcPath, importLine: "import 'package:${PathConstants().projectName}/core/constants/app_typedef.dart';");
  await _injectImport(filePath: svcPath, importLine: "import 'package:${PathConstants().projectName}/features/screens/$featureName/data/model/$snakeMethod/$snakeMethod.dart';");
  await _injectImport(filePath: svcPath, importLine: "import 'package:${PathConstants().projectName}/features/screens/$featureName/data/model/$snakeMethod/${snakeMethod}_req_param.dart';");

  await _injectIntoClass(
    filePath: svcPath,
    className: p.serviceName(),
    displayName: 'service',
    injection: '''
  Future<void> ${toPascalLowerCase(functionName)+'Serv'}(
    RequestCallbackObserver<$returnType, $paramType> requestInfo,
  ) {
    const cacheKey = AppConstant.$cacheKeyName;
    return requestInfo.handleRequest(
      fetchFromClient: (token) => _remoteRepo.${toPascalLowerCase(functionName)+'Api'}(
        requestInfo.parameter,
        cancelToken: token,
      ),
      fetchLocal: () async {
        final json = await _localRepo.readData(cacheKey);
        return json == null ? null : $returnType.fromJson(json);
      },
      saveLocal: (old, newData) async {
        if (newData != null) {
          await _localRepo.saveData(cacheKey, newData.toJson());
        }
      },
      clearLocal: () => _localRepo.clearData(cacheKey),
    );
  }''',
    checkDuplicate: 'Future<void> ${toPascalLowerCase(functionName)+'Serv'}(',
  );

  // ── 4. State ─────────────────────────────────────────────────────────────
  await _injectImport(filePath: statePath, importLine: "import 'package:${PathConstants().projectName}/core/base/base_state.dart';");

  await _appendToEndOfFile(
    filePath: statePath,
    displayName: 'state',
    injection: '''
class ${returnType}State extends ${p.stateName()} {
  final BaseEmit baseEmit;
  ${returnType}State(this.baseEmit);
}''',
    checkDuplicate: 'class ${returnType}State ',
  );

  // ── 5. Cubit ─────────────────────────────────────────────────────────────
  await _injectImport(filePath: cubitPath, importLine: "import 'package:${PathConstants().projectName}/core/api_helper/cancel/cancel_manager.dart';");
  await _injectImport(filePath: cubitPath, importLine: "import 'package:${PathConstants().projectName}/features/screens/$featureName/controller/${featureName}_state.dart';");
  await _injectImport(filePath: cubitPath, importLine: "import 'package:${PathConstants().projectName}/features/screens/$featureName/data/model/$snakeMethod/$snakeMethod.dart';");
  await _injectImport(filePath: cubitPath, importLine: "import 'package:${PathConstants().projectName}/features/screens/$featureName/data/model/$snakeMethod/${snakeMethod}_req_param.dart';");

  // Inject KeyCode getter before init()
  await _injectBeforeInit(
    filePath: cubitPath,
    injection: '  int get $keyCodeName => AppConstant.$keyCodeName;',
    checkDuplicate: 'int get $keyCodeName',
  );

  await _injectIntoClass(
    filePath: cubitPath,
    className: p.cubitName(),
    displayName: 'cubit',
    injection: '''
  Future<void> ${toPascalLowerCase(functionName)+'Func'}(RequestTypeBackV2 requestType, {$paramType? parameter}) async {
    await CancelManager.runCancelableFun($keyCodeName, (token) async {
      await _service.${toPascalLowerCase(functionName)+'Serv'}(
        RequestCallbackObserver<$returnType, $paramType>(
          baseRequestBackType: requestType.toRequestType(),
          parameter: parameter ,
          cancelToken: token,
          onLoadCallback: () => safeEmit(${returnType}State(Loading())),
          onRightCallback: (data) => safeEmit(${returnType}State(Success(data))),
          onLeftCallback: (failure) => safeEmit(${returnType}State(ErrorState(failure))),
        ),
      );
    });
  }''',
    checkDuplicate: 'Future<void> ${toPascalLowerCase(functionName)+'Func'}(',
  );

  // Update close() method
  await _updateCloseMethod(
    filePath: cubitPath,
    keyCodeName: keyCodeName,
  );

  // ── 6. Route ─────────────────────────────────────────────────────────────
  await addAutoRoute(
    p.routeName(featureName),
    p.screenFileName(featureName),
  );

  print('✅ "$functionName" successfully added to "$featureName"');
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Future<void> _registerConstant(String name, String value) async {
  final file = File('lib/core/constants/app_constant.dart');
  if (!file.existsSync()) return;
  final content = await file.readAsString();
  if (content.contains('static const String $name')) return;
  final lastBrace = content.lastIndexOf('}');
  if (lastBrace == -1) return;
  final updated = content.substring(0, lastBrace) + '  static const String $name = \'$value\';\n' + content.substring(lastBrace);
  await file.writeAsString(updated);
}

Future<void> _registerIntConstant(String name, int value) async {
  final file = File('lib/core/constants/app_constant.dart');
  if (!file.existsSync()) return;
  final content = await file.readAsString();
  if (content.contains('static const int $name')) return;
  final lastBrace = content.lastIndexOf('}');
  if (lastBrace == -1) return;
  final updated = content.substring(0, lastBrace) + '  static const int $name = $value;\n' + content.substring(lastBrace);
  await file.writeAsString(updated);
}

Future<void> _injectBeforeInit({required String filePath, required String injection, required String checkDuplicate}) async {
  final file = File(filePath);
  String content = await file.readAsString();
  if (content.contains(checkDuplicate)) return;
  final initIndex = content.indexOf('init()');
  if (initIndex == -1) return;
  // Find the @override before init or just before init()
  final overrideMatch = RegExp(r'@override\s+init\(\)').firstMatch(content);
  final targetIndex = overrideMatch?.start ?? initIndex;
  final updated = content.substring(0, targetIndex) + '$injection\n  ' + content.substring(targetIndex);
  await file.writeAsString(updated);
}

Future<void> _updateCloseMethod({required String filePath, required String keyCodeName}) async {
  final file = File(filePath);
  String content = await file.readAsString();
  final String cancelLine = '    CancelManager.cancel($keyCodeName);';
  
  if (content.contains(cancelLine)) return;

  if (content.contains('Future<void> close()')) {
    // Append to existing close()
    final closeMatch = RegExp(r'Future<void> close\(\) \{').firstMatch(content);
    if (closeMatch != null) {
      final insertPos = content.indexOf('{', closeMatch.start) + 1;
      final updated = content.substring(0, insertPos) + '\n    // add every key in file\n' + cancelLine + content.substring(insertPos);
      await file.writeAsString(updated);
    }
  } else {
    // Add new close() before the last brace
    final lastBrace = content.lastIndexOf('}');
    final String closeMethod = '''
  @override
  Future<void> close() {
    // add every key in file
$cancelLine
    return super.close();
  }
''';
    final updated = content.substring(0, lastBrace) + closeMethod + content.substring(lastBrace);
    await file.writeAsString(updated);
  }
}

Future<void> _injectIntoClass({required String filePath, required String className, required String displayName, required String injection, required String checkDuplicate}) async {
  final file = File(filePath);
  final content = await file.readAsString();
  if (content.contains(checkDuplicate)) {
    print('⚠️  [$displayName] "$checkDuplicate" already exists — skipped.');
    return;
  }
  final lastBrace = content.lastIndexOf('}');
  if (lastBrace == -1) return;
  final updated = content.substring(0, lastBrace) + '\n$injection\n' + content.substring(lastBrace);
  await file.writeAsString(updated);
  print('✅ [$displayName] injected "$checkDuplicate"');
}

Future<void> _appendToEndOfFile({required String filePath, required String displayName, required String injection, required String checkDuplicate}) async {
  final file = File(filePath);
  final content = await file.readAsString();
  if (content.contains(checkDuplicate)) {
    print('⚠️  [$displayName] "$checkDuplicate" already exists — skipped.');
    return;
  }
  final updated = content.trim() + '\n\n$injection\n';
  await file.writeAsString(updated);
}

Future<void> _injectImport({required String filePath, required String importLine, bool optional = false}) async {
  final file = File(filePath);
  if (!file.existsSync()) return;
  if (optional) {
    final match = RegExp(r"import 'package:${PathConstants().projectName}/(.*)';").firstMatch(importLine);
    if (match != null) {
      final subPath = match.group(1);
      if (!File('lib/$subPath').existsSync()) return;
    }
  }
  final content = await file.readAsString();
  if (content.contains(importLine)) return;
  final updated = '$importLine\n$content';
  await file.writeAsString(updated);
}

void _printUsage() {
  stderr.writeln('Usage: dart run add_function_script.dart <feature> <function> <Return> <Param>');
}
String toPascalLowerCase(String input) {
  return PathConstants().toPascalCase(input,lowerCaseFirstChar: true);
}
