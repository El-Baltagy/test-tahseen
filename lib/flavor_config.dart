import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:tahseen/core/api_helper/dio_helper.dart';
import 'package:tahseen/core/api_helper/interceptor/attestation_interceptor.dart';
import 'package:tahseen/core/api_helper/interceptor/auth_interceptor.dart';
import 'package:tahseen/core/api_helper/interceptor/retry_interceptor.dart';
import 'package:tahseen/core/api_helper/interceptor/signer_interceptor.dart';
import 'package:tahseen/core/api_helper/interceptor/ssl_pinning_check.dart';

enum Flavor { dev, prod }

class AppFlavorConfig {
  final String baseUrl;
  final String appTitle;
  final Flavor flavor;
  final List<Interceptor> interceptors;
  final FirebaseOptions? firebaseOptions;
  static AppFlavorConfig? _instance;

  factory AppFlavorConfig({
    required String baseUrl,
    required String appTitle,
    required Flavor flavor,
    required List<Interceptor> interceptors,
    required FirebaseOptions? firebaseOptions,
  }) {
    _instance ??= AppFlavorConfig._(baseUrl, appTitle, flavor, interceptors,firebaseOptions);
    return _instance!;
  }

  AppFlavorConfig._(this.baseUrl, this.appTitle, this.flavor, this.interceptors,this.firebaseOptions);

  static AppFlavorConfig get instance {
    if (_instance == null) {
      throw Exception('AppConfig has not been initialized. Call initialize() in main().');
    }
    return _instance!;
  }

  static bool get isDev => instance.flavor == Flavor.dev;
  static bool get isProd => instance.flavor == Flavor.prod;

  static const String _rawFlavor = String.fromEnvironment('FLUTTER_APP_FLAVOR');

  static void initialize() {
    switch (_rawFlavor) {
      case 'dev':
        AppFlavorConfig(
          firebaseOptions: defaultTargetPlatform == TargetPlatform.android ? const FirebaseOptions(
    apiKey: 'AIzaSyAj7aZ4OWvnNDPn0ziElScJFzh0j2QT3QM',
    appId: '1:725070483051:android:25013c3f27775bbdd92b2e',
    messagingSenderId: '725070483051',
    projectId: 'tahseen1',
    storageBucket: 'tahseen1.firebasestorage.app',
  ) : const FirebaseOptions(
    apiKey: 'AIzaSyA_leIRnbvR5P7-lPfRNtOvxVRqr5vWwDU',
    appId: '1:725070483051:ios:46825cdf35aff6e7d92b2e',
    messagingSenderId: '725070483051',
    projectId: 'tahseen1',
    storageBucket: 'tahseen1.firebasestorage.app',
    iosBundleId: 'com.app.tahseen.dev',
  ),
        
          flavor: Flavor.dev,
          baseUrl: 'https://dev-api.tahseen.com',
          appTitle: 'Tahseen [DEV]',
          interceptors: [],
        );
        break;
      case 'prod' || '':
        AppFlavorConfig(
          firebaseOptions: defaultTargetPlatform == TargetPlatform.android ? const FirebaseOptions(
    apiKey: 'AIzaSyAj7aZ4OWvnNDPn0ziElScJFzh0j2QT3QM',
    appId: '1:725070483051:android:3fb9f7ea1e870c3cd92b2e',
    messagingSenderId: '725070483051',
    projectId: 'tahseen1',
    storageBucket: 'tahseen1.firebasestorage.app',
  ) : const FirebaseOptions(
    apiKey: 'AIzaSyA_leIRnbvR5P7-lPfRNtOvxVRqr5vWwDU',
    appId: '1:725070483051:ios:76653b671c3cdcc3d92b2e',
    messagingSenderId: '725070483051',
    projectId: 'tahseen1',
    storageBucket: 'tahseen1.firebasestorage.app',
    iosBundleId: 'com.app.tahseen.tahseen',
  ),
          
          flavor: Flavor.prod,
          baseUrl: 'https://api.tahseen.com',
          appTitle: 'Tahseen',
          interceptors: [
            SSLPinningCheck(),
            AttestationInterceptor(),
            AuthInterceptor(
              dio: DioHelper().dio,
              getAccessToken: DioHelper().getToken,
              refreshToken: DioHelper().refreshToken,
            ),
            SignerInterceptor(getToken: DioHelper().getToken),
            RetryInterceptor(),
          ]
        );
        break;
    }
  }
}
