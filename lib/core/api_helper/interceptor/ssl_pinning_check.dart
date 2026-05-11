import 'package:dio/dio.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';
import 'package:tahseen/flavor_config.dart';

class SSLPinningCheck extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 🛡️ Skip SSL Pinning in Dev to allow using debugging proxies (Charles/Proxyman)
    if (AppFlavorConfig.isDev) {
      return handler.next(options);
    }

    /// Exclude the upgrade API from SSL Pinning
    if (options.path.contains('/upgrade') || options.path.contains('/version')) {
      return handler.next(options);
    }

    /// Otherwise Verifies the SSL certificate before making the request.
    try {
      await HttpCertificatePinning.check(
        serverURL: options.baseUrl,
        sha: SHA.SHA256,
        allowedSHAFingerprints: _allowedFingerprints,
        timeout: 50,
      );
      return handler.next(options);
    } catch (e) {
      // Pinning failed! Block request.
      return handler.reject(DioException(
        requestOptions: RequestOptions(path: options.baseUrl),
        error: 'SSL Pinning Verification Failed: Potential MITM attack detected.',
        type: DioExceptionType.connectionError,
      ));
    }
  }

  // These should be your real server fingerprints
  // In a real Fintech app, you might load these from AppConfig per flavor
  static const List<String> _allowedFingerprints = [
    'PASTE_YOUR_SHA256_FINGERPRINT_1_HERE',
    'PASTE_YOUR_SHA256_FINGERPRINT_2_HERE',
  ];
}
