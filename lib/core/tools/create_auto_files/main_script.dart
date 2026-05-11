import 'dart:convert';
import 'dart:io';
import '../create_auto_files/path_constants.dart';
import 'package:${PathConstants().projectName}/core/tools/create_auto_files/path_constants.dart';
import 'package:${PathConstants().projectName}/core/tools/create_auto_files/repo_added_files.dart'
    show RepoAddRequiredFiles;
import 'package:${PathConstants().projectName}/core/tools/create_auto_files/route_generator_data.dart';
import 'package:${PathConstants().projectName}/core/tools/create_auto_files/service_added_files.dart';
import 'package:${PathConstants().projectName}/core/tools/create_auto_files/singleton_add_requried_date.dart';
import 'package:${PathConstants().projectName}/core/tools/create_auto_files/ui_added_files.dart'
    show UIAddRequiredFiles;
import 'controller_added_files.dart' show ControllerAddRequiredFiles;

Future<void> main(List<dynamic> args) async {
  if (args.isEmpty) {
    print('❌ Please provide a mainFolderName.');
    print('Usage: dart run tools/create_feature_folders.dart <mainFolderName>');
    exit(1);
  }


  final mainFolderName = args[0] as String;
  PathConstants().setData(mainFolderName);

  List<String> secondayName = [];

  if (args.length > 1) {
    secondayName = args.skip(1).where((e) => !e.toString().startsWith('--')).map((e) => e.toString()).toList();
  }

  bool isNotifier = false, isCubit = false;

  final dir = Directory('lib/features/screens');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final folders = dir
      .listSync()
      .where((entity) => entity is Directory)
      .map((e) => e.uri.pathSegments[e.uri.pathSegments.length - 2])
      // .map((e) => e.path.split('\\').last)
      .toList();

  if (!folders.contains(mainFolderName)) {
    stdout.write('Do you want generate this feature with cubit [Y/N]: ');
    final input =
        stdin.readLineSync(encoding: utf8)?.trim().toLowerCase() ?? '';
    if (input.isEmpty || input.toString()[0].toLowerCase() == 'y') {
      isCubit = true;
    } else {
      isNotifier = true;
    }

    ControllerAddRequiredFiles(
      isNotifier,
      isCubit,
    ).makeRequiredFiles('controller');
    RepoAddRequiredFiles(isNotifier).makeRequiredFiles('data');
    ServiceAddRequiredFiles().makeRequiredFiles('service');
    await AddRequiredDataToSL(isCubit)();
  } else {
    if (secondayName.isEmpty) {
      print('❌ mainFolderName is already defined');
      exit(1);
    }
  }

  if (secondayName.isEmpty) {
    secondayName.add(mainFolderName);
  }

  for (String x in secondayName) {
    UIAddRequiredFiles(
      isNotifier,
      screenFileName: PathConstants().screenFileName(x),
      screenName: PathConstants().screenName(x),
    ).makeRequiredFiles('ui');
    await addAutoRoute(
      PathConstants().routeName(x),
      PathConstants().screenFileName(x),
    );
  }

  if (!args.contains('--no-build')) {
    await makeBuildRunner();
  }

  print('✅ Feature structure created successfully inside lib/features/screens');
}

