import 'dart:io';
import '../create_auto_files/path_constants.dart';
import 'path_constants.dart';


class RepoAddRequiredFiles extends BaseAddRequiredFiles {
  RepoAddRequiredFiles(this.isNotifier);
  final bool isNotifier;

  @override
  makeRequiredFiles(String folder) async {
    super.makeRequiredFiles(folder);

    final modelDir = Directory('${PathConstants().folderPath(folder)}/model');
    final repoRemoteDir = Directory(PathConstants().remoteRepoPath());

    ///create folder
    if (!modelDir.existsSync()) {
      modelDir.createSync(recursive: true);
      print('📁 Created model folder: ${modelDir.path}');
    }
    // _createNotiferDataClass(modelDir.path,isNotifier);

    ///create repo folder (remote)
    create_Repo(repoRemoteDir);
  }

  create_Repo(Directory dir){
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      print('📁 Created repo folder: ${dir.path}');
    }
    _createRepoClass(dir.path);
  }
}

// ... (_createNotiferDataClass)

_createRepoClass(String repoPath) {
  final filePath = '$repoPath/${PathConstants().repoFileName()}';
  final file = File(filePath);

  if (!file.existsSync()) {
    final content =
        '''
import 'package:${PathConstants().projectName}/core/constants/app_api.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:${PathConstants().projectName}/core/api_helper/dio_error_handler.dart';
import 'package:${PathConstants().projectName}/core/api_helper/dio_helper.dart';
import 'package:${PathConstants().projectName}/core/api_helper/response_handler.dart';
import 'package:${PathConstants().projectName}/core/base/base_remote_repo.dart';

class ${PathConstants().repoName()} extends BaseRepo {
  final DioHelper dio;
  ${PathConstants().repoName()}(this.dio);
}

''';
    file.writeAsStringSync(content);
    print('📄 Created repo Dart file: $filePath');
  } else {
    print('⚠️ Repo Dart file already exists: $filePath');
  }
}


