import 'package:dio/dio.dart';
import 'package:tahseen/core/api_helper/interceptor/attestation_service.dart';
import 'package:tahseen/flavor_config.dart';
class AttestationInterceptor extends Interceptor {
  final AttestationService _attestationService = AttestationService();

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 🛡️ Skip Attestation in Dev to support Emulators and Debug builds
    if (AppFlavorConfig.isDev) {
      options.headers['X-Hardware-Attestation'] = 'DEVELOPMENT_MOCK_TOKEN';
      return handler.next(options);
    }

    final bool isCriticalEndpoint = options.path.contains('/auth') || options.path.contains('/payment');

    if (isCriticalEndpoint) {
      try {
        final String nonce = DateTime.now().millisecondsSinceEpoch.toString();
        final String token = await _attestationService.getAttestationToken(nonce);
        options.headers['X-Hardware-Attestation'] = token;
      } catch (e) {
        return handler.reject(DioException(
          requestOptions: options,
          error: 'Security Policy Violation: Could not verify device hardware.',
        ));
      }
    }

    return handler.next(options);
  }
}
