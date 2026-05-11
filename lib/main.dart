import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tahseen/flavor_config.dart';

Future<void> main() async {
  AppFlavorConfig.initialize();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: AppFlavorConfig.instance.firebaseOptions);
}