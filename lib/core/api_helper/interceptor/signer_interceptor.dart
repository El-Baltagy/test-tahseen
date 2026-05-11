import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// 🛡️ Universal HMAC Security Interceptor
/// Supports two levels of security via the [useTotp] flag:
/// - false (Level 2): Uses Global Secret + User Token as the key.
/// - true  (Level 3): Uses Time-Based OTP to generate a self-destructing key every 30s.
class SignerInterceptor extends Interceptor {
  SignerInterceptor({
    this.getToken,
    this.useTotp = false, // Set to true to activate TOTP (Time-Based One-Time Password))
  });

  /// The function to retrieve the current user's token
  final Future<String?> Function()? getToken;

  /// Whether to use the advanced Time-Based OTP algorithm
  final bool useTotp;

  /// The Master Base Secret (Never changes, never sent over network)
  static const String _baseSecret = 'SECURE_TAHSEEN_MASTER_KEY_2024';

  /// Level 3 Logic: Generates a temporary secret key valid for only 30 seconds.
  String _generateTotpKey(String? userToken) {
    final int currentTimeInSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final int timeStep = currentTimeInSeconds ~/ 30; // 30-second window

    final String combinedSecret = userToken != null && userToken.isNotEmpty 
        ? '\${_baseSecret}_\$userToken'
        : _baseSecret;

    final hmac = Hmac(sha256, utf8.encode(combinedSecret));
    final temporaryKey = hmac.convert(utf8.encode(timeStep.toString()));

    return temporaryKey.toString();
  }

  /// Level 2 Logic: Generates a static key based on the user session.
  String _generateStaticKey(String? userToken) {
    return userToken != null && userToken.isNotEmpty 
        ? '${_baseSecret}_$userToken'
        : _baseSecret;
  }

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final String requestTimestamp = DateTime.now().millisecondsSinceEpoch.toString();

    // 1. Get user token
    final String? userToken = getToken != null ? await getToken!() : null;

    // 2. Decide which secret key to use based on the flag
    final String secretKeyToUse = useTotp 
        ? _generateTotpKey(userToken) 
        : _generateStaticKey(userToken);

    // 3. Prepare Data to sign (Method + Path + Timestamp + JSON Body)
    String dataToSign = '${options.method}|${options.path}|$requestTimestamp';
    
    if (options.data != null && options.data is Map) {
      dataToSign += '|${jsonEncode(options.data)}';
    }

    // 4. Sign the Request
    final hmac = Hmac(sha256, utf8.encode(secretKeyToUse));
    final signature = hmac.convert(utf8.encode(dataToSign));

    // 5. Inject Headers
    options.headers['X-App-Signature'] = signature.toString();
    options.headers['X-App-Timestamp'] = requestTimestamp;
    
    // Optional identifier so the backend knows which logic to use
    options.headers['X-Security-Level'] = useTotp ? 'TOTP' : 'STATIC';

    return handler.next(options);
  }
}
