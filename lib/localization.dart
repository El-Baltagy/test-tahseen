import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CodegenLoader extends RootBundleAssetLoader {
  CodegenLoader._internal();

  static final CodegenLoader _instance =
  CodegenLoader._internal();

  factory CodegenLoader() => _instance;

  final Map<String, Map<String, dynamic>> _cache = {};

  static const String  assetTranslationsPath = 'assets/l10n';
  static Locale get fallBackLocale =>  const Locale('en');
  static List<Locale> supportedLocales = [];

  Locale _currentLocale = const Locale('en');
  Locale get currentLocale => _currentLocale;


  void setLocale(Locale locale) {
    _currentLocale = locale;
  }


  static Future<void> init() async {
    final manifestContent =
    await rootBundle.loadString('AssetManifest.json');

    final Map<String, dynamic> manifestMap =
    json.decode(manifestContent);

    final localeFiles = manifestMap.keys
        .where(
          (path) =>
      path.startsWith('$assetTranslationsPath/') &&
          path.endsWith('.json'),
    )
        .toList();

    supportedLocales = localeFiles.map((filePath) {
      final fileName = filePath.split('/').last;

      final localeCode = fileName
          .split('_')
          .last
          .replaceAll('.json', '');

      return Locale(localeCode);
    }).toList();
    setLocale(  Locale('en'));
  }

  @override
  Future<Map<String, dynamic>> load(
      String path,
      Locale locale,
      ) async {
    final localeKey = locale.languageCode;

    if (_cache.containsKey(localeKey)) {
      return _cache[localeKey]!;
    }

    final jsonString = await rootBundle.loadString(
      '$assetTranslationsPath/app_$localeKey.json',
    );

    final Map<String, dynamic> jsonMap =
    json.decode(jsonString);

    _cache[localeKey] = jsonMap;

    return jsonMap;
  }
}