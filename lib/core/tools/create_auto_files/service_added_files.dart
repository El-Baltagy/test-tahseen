import 'dart:io';
import '../create_auto_files/path_constants.dart';
import 'path_constants.dart';

class ServiceAddRequiredFiles extends BaseAddRequiredFiles {
  ServiceAddRequiredFiles();

  @override
  makeRequiredFiles(String folder) async {
      super.makeRequiredFiles(folder);

      final repoDir = Directory(PathConstants().folderPath(folder));

      ///create service folder
      if (!repoDir.existsSync()) {
        repoDir.createSync(recursive: true);
        print('📁 Created service folder: ${repoDir.path}');
      }

      _createServiceClass(repoDir.path);
  }
}

void _createServiceClass(String  repoPath){
  final filePath = '$repoPath/${PathConstants().serviceFileName()}';
  final file = File(filePath);

  if (!file.existsSync()) {
    final content =
    '''
import 'package:${PathConstants().projectName}/core/base/base_service.dart';
import 'package:${PathConstants().projectName}/core/base/base_local_repo.dart';
import 'package:${PathConstants().projectName}/features/screens/${PathConstants().name}/data/repo/remote/${PathConstants().repoFileName()}';

class ${PathConstants().serviceName()} extends BaseService {
  ${PathConstants().serviceName()}(this._remoteRepo, this._localRepo);
  
  final ${PathConstants().repoName()} _remoteRepo;
  final BaseLocalRepo _localRepo;
}
''';
    file.writeAsStringSync(content);
    print('📄 Created service Dart file: $filePath');
  } else {
    print('⚠️ service Dart file already exists: $filePath');
  }
}
