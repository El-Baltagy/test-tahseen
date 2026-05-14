import 'dart:io';
import '../create_auto_files/path_constants.dart';
import 'path_constants.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run singleton_add_requried_date.dart <featureName> [isCubit]');
    return;
  }
  final featureName = args[0];
  final isCubit = args.length > 1 ? args[1] == 'true' : true;
  PathConstants().setData(featureName);
  await AddRequiredDataToSL(isCubit)();
}

class AddRequiredDataToSL {
  AddRequiredDataToSL(this.isCubit);
  final bool isCubit;

  Future<void> call() async {
    final file = File(PathConstants().singltonPath);
    String originalContent = '';
    if (!file.existsSync()) {
      originalContent = '''
import 'package:get_it/get_it.dart';

class AppSingleton {
  AppSingleton._();

  static final AppSingleton _instance = AppSingleton._();

  factory AppSingleton() => _instance;

  final _sl = GetIt.instance;

  GetIt call()=>_sl;
  
  void init(){


  }
}
      ''';
      await file.writeAsString(originalContent);
    }

    originalContent = await file.readAsString();
    late String controllerTxt, controllerFileName;
    if (isCubit) {
      controllerTxt =
          '_sl.registerFactory(() => ${PathConstants().cubitName()}(_sl()));';
      controllerFileName = PathConstants().cubitFileName();
    } else {
      controllerTxt =
          '_sl.registerLazySingleton(() => ${PathConstants().notifierName()}(_sl()));';
      controllerFileName = PathConstants().notifierFileName();
    }

    final importLines = originalContent
        .split('\n')
        .where((line) => line.trim().startsWith('import'))
        .toList();

    originalContent = originalContent.replaceFirst(
      importLines.first,
      '''import 'package:${PathConstants().projectName}/features/screens/${PathConstants().name}/data/repo/remote/${PathConstants().repoFileName()}';
import 'package:tahseen/features/screens/${PathConstants().name}/service/${PathConstants().serviceFileName()}';
import 'package:tahseen/features/screens/${PathConstants().name}/controller/$controllerFileName';
${importLines.first}''',
    );

    final initRegex = RegExp(r'void\s+init\s*\(\)\s*\{');
    if (originalContent.contains(initRegex)) {
      String hint = '///..................${PathConstants().name}.................///';
      if (originalContent.contains('$hint')) {
        print('⚠️ this Di is already registered.');
        return;
      }

      String additionalCode = '''    $hint
    _sl.registerLazySingleton(() => ${PathConstants().repoName()}(_sl()));
    _sl.registerLazySingleton(() => ${PathConstants().serviceName()}(_sl(), _sl()));
    $controllerTxt''';

      originalContent = originalContent.replaceFirst(
        initRegex,
        'void init(){\n$additionalCode\n',
      );
    }
    await file.writeAsString(originalContent);
  }
}
