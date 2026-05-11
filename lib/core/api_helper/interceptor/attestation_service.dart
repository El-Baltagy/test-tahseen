import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:app_attest_integrity/app_attest_integrity.dart';

/// ----------------------------------------------------------------------------
/// 🛡️ THE HARDWARE COMMUNICATOR (AttestationService)
/// ----------------------------------------------------------------------------
/// This service acts as the "Brain" of our App Attestation architecture.
/// Its only job is to communicate directly with the physical security chips 
/// inside the user's device (Apple Secure Enclave or Google TrustZone).
/// 
/// It asks the hardware to generate a cryptographic token that proves:
/// 1. The app is genuine, unmodified, and downloaded from the official store.
/// 2. The device is a real, physical phone (not a hacker's emulator).
/// 3. The OS is secure (not rooted or jailbroken).
/// ----------------------------------------------------------------------------
class AttestationService {
  static const AppAttestIntegrity _appAttestIntegrity = AppAttestIntegrity();

  // iOS App Attest is a two-step process that requires saving the generated Key ID
  // to be used later for signing the actual request data.
  String? _iOSKeyID;

  /// Retrieves a hardware-signed token proving the app's integrity.
  /// The [nonce] (Number used ONCE) is a challenge from the backend to prevent replay attacks.
  Future<String> getAttestationToken(String nonce) async {
    
    // ⚠️ THE SAFETY NET
    // Hardware attestation completely blocks emulators and debug mode by design.
    // If we don't bypass this during development, the app would crash locally.
    // This check ensures hardware attestation only runs in the final Release AppBundle.
    if (kDebugMode) {
      return 'SIMULATED_TOKEN_\${Platform.operatingSystem}_\$nonce';
    }

    try {
      // The payload we want the hardware to sign and mathematically lock.
      final clientDataBase64 = base64Encode(utf8.encode(jsonEncode({'challenge': nonce})));

      if (Platform.isIOS) {
        // 🍎 THE IOS FLOW (Two-Step Process)
        
        // Step 1: Generate iOS Attestation Key if we haven't already.
        // This talks to the Apple Secure Enclave and generates a unique cryptographic key pair 
        // for this specific device. We save the public Key ID in memory.
        if (_iOSKeyID == null) {
          final response = await _appAttestIntegrity.iOSgenerateAttestation(nonce);
          _iOSKeyID = response?.keyId;
          
          if (_iOSKeyID == null) throw Exception("Failed to generate iOS Attestation Key");
          
          // Note for Production: In a real app, the very first time you generate this, 
          // you should send `response.attestation` to your backend. 
          // Your backend uses this to "register" the device's public key forever.
        }

        // Step 2: Generate the specific assertion for this request.
        // This uses the newly generated key to mathematically sign the client data.
        final assertion = await _appAttestIntegrity.verify(
          clientData: clientDataBase64,
          iOSkeyID: _iOSKeyID,
        );
        return assertion;

      }

      else if (Platform.isAndroid) {
        // 🤖 THE ANDROID FLOW
        
        // Step 1: Warm-up Server
        // We pass the Google Cloud Project Number to wake up Google Play Services
        // and prepare the connection to Google's backend.
        const cloudProjectNumber = 1234567890; // REPLACE with your Google Cloud Project Number
        await _appAttestIntegrity.androidPrepareIntegrityServer(cloudProjectNumber);

        // Step 2: Request the Integrity Token
        // Google analyzes the phone (checks for root, modifications) and generates 
        // the cryptographic token proving the phone is clean.
        final assertion = await _appAttestIntegrity.verify(
          clientData: clientDataBase64,
        );
        return assertion;
      }

      return 'UNSUPPORTED_PLATFORM';
    } catch (e) {
      throw Exception('Hardware Attestation Failed: \$e');
    }
  }
}
