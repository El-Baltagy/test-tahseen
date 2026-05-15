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
      path: CodegenLoader.assetTranslationsPath,
      assetLoader: CodegenLoader(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tahseen',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: Scaffold(),
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey(debugLabel: "Main Navigator");