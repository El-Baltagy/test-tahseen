import 'dart:io';
import '../create_auto_files/path_constants.dart';
import 'path_constants.dart';

class UIAddRequiredFiles extends BaseAddRequiredFiles {
  UIAddRequiredFiles(this.isNotifier, {required this.screenFileName, required this.screenName});
  final bool isNotifier;
  final String screenFileName,screenName;

  //PathConstants().screenFileName() PathConstants().screenName()
  @override
  makeRequiredFiles(String folder) async {
    super.makeRequiredFiles(folder);

    final file = File(
      '${PathConstants().folderPath(folder)}/${screenFileName}',
    );

    if (!file.existsSync()) {
      // final String widgetName = PathConstants().screenName();
      final String notifierClassInstant = PathConstants()
          .tolowerCasTheFirstCharachter(PathConstants().notifierName());

      String content = isNotifier
          ? _getStringNotifierOnly(screenName, notifierClassInstant)
          : _getStringBlocOnly(screenName, notifierClassInstant);

      file.writeAsStringSync(content);
      print('📄 Created Dart file: ${PathConstants().folderPath(folder)}');
    }

    // Create widgets folder inside screen folder
    final widgetsDir = Directory(
      '${PathConstants().folderPath(folder)}/widgets',
    );
    if (!widgetsDir.existsSync()) {
      widgetsDir.createSync(recursive: true);
      print('📁 Created widgets folder: ${widgetsDir.path}');
    }
  }
}

String _getStringNotifierOnly(String widgetName, String notifierClassInstant) {
  return '''

@RoutePage()
class $widgetName extends StatefulWidget {
  const $widgetName({super.key});

  @override
  State<$widgetName> createState() => _${widgetName}State();
}

class _${widgetName}State extends State<$widgetName> {
 final ${PathConstants().notifierName()} $notifierClassInstant=AppSingleton()()();
  
  @override
  Widget build(BuildContext context) {
  
    return ValueListenableBuilder(valueListenable:$notifierClassInstant.notifier! , builder: (context, value, child) {
      return Scaffold(
        body: Placeholder(),
      );
    },);
  }
}

''';
}

String _getStringBlocOnly(String widgetName, String notifierClassInstant) {
  return '''import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahseen/core/constants/app_singleton.dart';
import 'package:tahseen/features/screens/${PathConstants().name}/controller/${PathConstants().cubitFileName()}';
import 'package:tahseen/features/screens/${PathConstants().name}/controller/${PathConstants().stateFileName()}';





@RoutePage()
class $widgetName extends StatefulWidget implements AutoRouteWrapper{
  const $widgetName({super.key});
  // 2. Implement the wrappedRoute method
  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider<${PathConstants().cubitName()}>(
      // Use your singleton to get the Cubit instance
      create: (context) =>${PathConstants().cubitName()}(AppSingleton()()()),
      child: this, // 'this' refers to the AuthPage itself
    );
  }
  @override
  State<$widgetName> createState() => _${widgetName}State();
}

class _${widgetName}State extends ${widgetName}BaseState {

  @override
  Widget build(BuildContext context) {
     return BlocListener<${PathConstants().cubitName()}, ${PathConstants().stateName()}>(
      listener: (context, state) {
        // TODO: implement listener}
      },
      child: Scaffold(

      ),
    );
    
  }
}


abstract class  ${widgetName}BaseState extends State<$widgetName> {
  final ${PathConstants().cubitName()} argData=${PathConstants().cubitName()}.get();
  @override
  void initState() {
    // TODO: implement initState

    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
}
''';
}
