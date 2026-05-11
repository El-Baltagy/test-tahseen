import 'dart:io';
import '../create_auto_files/path_constants.dart';
import 'package:${PathConstants().projectName}/core/tools/create_auto_files/path_constants.dart';



class ControllerAddRequiredFiles extends BaseAddRequiredFiles {
  ControllerAddRequiredFiles(this.isNotifier, this.isCubit);
  final  bool isNotifier,isCubit;

  @override
  makeRequiredFiles(String folder) async {
      super.makeRequiredFiles(folder);
      if (isNotifier) {
       await addNotifierFile(folder);
      }
      if (isCubit) {
        await  addCubitFiles(folder);
      }

  }
}

Future<void> addNotifierFile(String folder) async {

  final filePath = '${PathConstants().notifierPath(folder)}/${PathConstants().notifierFileName()}';
  final file = File(filePath);

  final File typeDefPath = File(PathConstants().typedefPath);
  if (!file.existsSync() && await typeDefPath.exists()) {
  final content =
  '''
import 'package:tahseen/core/base/base_notifier.dart';
import 'package:flutter/material.dart';
import 'package:tahseen/core/constants/app_typedef.dart';
import 'package:tahseen/features/screens/${PathConstants().name}/service/${PathConstants().name}_service.dart';

class ${PathConstants().notifierName()} extends BaseNotifier {
  final ${PathConstants().serviceName()} _service;
  ${PathConstants().notifierName()}(this._service);
    ValueNotifier<${"${PathConstants().notifierName()}Type"}>? notifier;
    @override
  void init() {
      notifier=.new(null);
    // TODO: implement
  }
    @override
  void dispose() {
      notifier?.dispose();
  // TODO: implement
  }
}
''';

  file.writeAsStringSync(content);


    final typedefContents = await typeDefPath.readAsString();

  final updated = typedefContents.replaceFirst('// hint to be replaced with custom text', '''
// hint to be replaced with custom text

/// this is typedef of the ${PathConstants().notifierName()} that located in
/// $filePath
typedef ${"${PathConstants().notifierName()}Type"}=${PathConstants().modelNotifierDataClassName()}?;
'''
  ).replaceFirst('// hint to be replaced with custom import by script', '''
// hint to be replaced with custom import by script
import 'package:tahseen/features/screens/${PathConstants().name}/data/model/${PathConstants().modelNotifierDataFileName()}';''');

    typeDefPath.writeAsStringSync(updated);



  print('📄 Created notifier Dart file: $filePath');
  } else {
  print('⚠️ notifier Dart file already exists: $filePath');
  }

}

Future<void> addCubitFiles(String folder) async {

  final filePath = '${PathConstants().folderPath(folder)}/${PathConstants().cubitFileName()}';
  final file = File(filePath);

  if (!file.existsSync()) {
    final contentt =
    '''
    import 'package:tahseen/core/constants/app_constant.dart';
 import 'package:tahseen/core/base/base_state.dart';
 import 'package:tahseen/core/base/base_service.dart';   
import 'package:tahseen/core/base/base_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahseen/main.dart';
import '${PathConstants().stateFileName()}';
import 'package:tahseen/features/screens/${PathConstants().name}/service/${PathConstants().name}_service.dart';


class ${PathConstants().cubitName()} extends BaseCubit<${PathConstants().stateName()}> {
   ${PathConstants().cubitName()}(this._service) : super(${PathConstants().initialStateName()}()) ;
  final ${PathConstants().serviceName()} _service;
  
     static ${PathConstants().cubitName()} get({BuildContext? context,bool listen=false}) =>
      BlocProvider.of(context??navigatorKey.currentContext!,listen: listen);
  
  @override
  init() {
    // TODO: implement init
   
  }
  
}
''';
    file.writeAsStringSync(contentt);
    print('📄 Created cubit Dart file: $filePath');
  } else {
    print('⚠️ cubit Dart file already exists: $filePath');
  }

  final statePath = '${PathConstants().folderPath(folder)}/${PathConstants().stateFileName()}';
  final state = File(statePath);

  if (!state.existsSync()) {
    final content =
    '''

import 'package:flutter/material.dart';

@immutable
abstract class ${PathConstants().stateName()} {}

class ${PathConstants().initialStateName()} extends ${PathConstants().stateName()} {}
''';
    state.writeAsStringSync(content);
    print('📄 Created state Dart file: $statePath');
  } else {
    print('⚠️ cubit state file already exists: $statePath');
  }

}
