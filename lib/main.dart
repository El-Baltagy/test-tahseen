import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tahseen/flavor_config.dart';
import 'package:tahseen/localization.dart';

 void  main() async {
  AppFlavorConfig.initialize();
  WidgetsFlutterBinding.ensureInitialized();


  await Future.wait([
    Firebase.initializeApp(options: AppFlavorConfig.instance.firebaseOptions),
    EasyLocalization.ensureInitialized(),
    CodegenLoader.init()
  ]);




  runApp(
    EasyLocalization(
      supportedLocales: CodegenLoader.supportedLocales,
      fallbackLocale:  CodegenLoader.fallBackLocale,
      startLocale: CodegenLoader().currentLocale,
      path: CodegenLoader.assetTranslationsPath,
      assetLoader: CodegenLoader(),
      child:Scaffold(),
    ),
  );
}