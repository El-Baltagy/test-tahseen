//
//  TokenSaverPlugin.swift
//  token_saver

//  Complete native-only Secure Enclave backed token saver plugin for iOS.
//  Uses: Secure Enclave (wrap/unwrap AES),
//  CryptoKit (AES.GCM),
//  Keychain storage.
//

import Flutter
import UIKit
import CryptoKit
import Security

public class TokenSaverPlugin: NSObject, FlutterPlugin {
    // Channel name must match Dart
    private let channelName = "token_saver"

    // Keychain account names (per tokenKey)
    // wrapped_<tokenKey> -> wrapped AES key bytes
    // cipher_<tokenKey>  -> stored ciphertext string "ivBase64|ciphertextBase64|tagBase64"
    private func wrappedAccount(for tokenKey: String) -> String { return "wrapped_\(tokenKey)" }
    private func cipherAccount(for tokenKey: String) -> String { return "cipher_\(tokenKey)" }

    // tag for the Secure Enclave private key
    private let enclaveTag = "com.example.token_saver.enclaveKey"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "token_saver", binaryMessenger: registrar.messenger())
        let instance = TokenSaverPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "saveToken":
            guard let args = call.arguments as? [String:Any],
            let key = args["key"] as? String,
            let value = args["value"] as? String else {
                result(FlutterError(code: "ARG", message: "Missing key/value", details: nil)); return
            }
            do {
                try saveTokenNative(tokenKey: key, plaintext: value)
                result(true)
            } catch {
                result(FlutterError(code: "ERR", message: error.localizedDescription, details: nil))
            }

        case "getToken":
            guard let args = call.arguments as? [String:Any], let key = args["key"] as? String else {
                result(FlutterError(code: "ARG", message: "Missing key", details: nil)); return
            }
            do {
                let p = try getTokenNative(tokenKey: key)
                result(p)
            } catch {
                result(FlutterError(code: "ERR", message: error.localizedDescription, details: nil))
            }

        case "deleteToken":
            guard let args = call.arguments as? [String:Any], let key = args["key"] as? String else {
                result(FlutterError(code: "ARG", message: "Missing key", details: nil)); return
            }
            do {
                try deleteTokenNative(tokenKey: key)
                result(true)
            } catch {
                result(FlutterError(code: "ERR", message: error.localizedDescription, details: nil))
            }

        case "rotateKey":
            guard let args = call.arguments as? [String:Any], let key = args["key"] as? String else {
                result(FlutterError(code: "ARG", message: "Missing key", details: nil)); return
            }
            do {
                try rotateKeyNative(tokenKey: key)
                result(true)
            } catch {
                result(FlutterError(code: "ERR", message: error.localizedDescription, details: nil))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Keychain helpers (generic functions keyed by tokenKey)

    private func keychainQuery(account: String) -> [String: Any] {
        return [kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: account]
    }

    private func saveToKeychain(account: String, data: Data) throws {
        var q = keychainQuery(account: account)
        SecItemDelete(q as CFDictionary) // remove existing
        q[kSecValueData as String] = data
        q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let status = SecItemAdd(q as CFDictionary, nil)
        if status != errSecSuccess {
            throw NSError(domain: "KC_SAVE", code: Int(status), userInfo: nil)
        }
    }

    private func readFromKeychain(account: String) throws -> Data? {
        var q = keychainQuery(account: account)
        q[kSecReturnData as String] = kCFBooleanTrue
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &item)
        if status == errSecSuccess {
            return item as? Data
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw NSError(domain: "KC_READ", code: Int(status), userInfo: nil)
        }
    }

    private func deleteFromKeychain(account: String) {
        let q = keychainQuery(account: account)
        SecItemDelete(q as CFDictionary)
    }

    // MARK: - Secure Enclave keypair (private non-exportable)

    private func ensureEnclaveKeyPair() throws -> SecKey {
        // Try to find existing private key
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: enclaveTag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess {
            return (item as! SecKey)
        } else if status == errSecItemNotFound {
            // create new key
            let access = SecAccessControlCreateWithFlags(nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .privateKeyUsage,
                nil)!
            let attributes: [String: Any] = [
                kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                kSecAttrKeySizeInBits as String: 256,
                kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
                kSecPrivateKeyAttrs as String: [
                    kSecAttrIsPermanent as String: true,
                    kSecAttrApplicationTag as String: enclaveTag,
                    kSecAttrAccessControl as String: access
                ]
            ]
            var error: Unmanaged<CFError>?
            guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
                throw error!.takeRetainedValue() as Error
            }
            return privateKey
        } else {
            throw NSError(domain: "ENCLAVE_CHECK", code: Int(status), userInfo: nil)
        }
    }

    private func getEnclavePublicKey() throws -> SecKey {
        let privateKey = try ensureEnclaveKeyPair()
        guard let pub = SecKeyCopyPublicKey(privateKey) else {
            throw NSError(domain: "ENCLAVE_PUB", code: -1, userInfo: nil)
        }
        return pub
    }

    // MARK: - AES wrapping + AES-GCM via CryptoKit

    // Create a random AES key and store its wrapped form (wrapped by enclave public key) in Keychain
    private func createAndStoreWrappedAES(tokenKey: String) throws {
        // Generate AES key bytes (256-bit)
        var keyBytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, keyBytes.count, &keyBytes)
        if status != errSecSuccess { throw NSError(domain: "RAND", code: Int(status), userInfo: nil) }
        let aesData = Data(keyBytes)

        // Wrap AES with enclave public key using ECIES-like algorithm
        let pub = try getEnclavePublicKey()
        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorX963SHA256AESGCM
        guard SecKeyIsAlgorithmSupported(pub, .encrypt, algorithm) else {
            throw NSError(domain: "ALG", code: -1, userInfo: [NSLocalizedDescriptionKey: "Algorithm not supported for public key"])
        }
        var error: Unmanaged<CFError>?
        guard let wrapped = SecKeyCreateEncryptedData(pub, algorithm, aesData as CFData, &error) as Data? else {
            throw error!.takeRetainedValue() as Error
        }

        // Save wrapped AES into Keychain under wrappedAccount
        try saveToKeychain(account: wrappedAccount(for: tokenKey), data: wrapped)
    }

    // Unwrap AES by calling Secure Enclave private key (SecKeyCreateDecryptedData)
    private func unwrapAES(tokenKey: String) throws -> Data {
        // read wrapped
        if let wrapped = try readFromKeychain(account: wrappedAccount(for: tokenKey)) {
            return try decryptWrapped(wrapped: wrapped)
        } else {
            // if not present, create new one and return it
            try createAndStoreWrappedAES(tokenKey: tokenKey)
            guard let newWrapped = try readFromKeychain(account: wrappedAccount(for: tokenKey)) else {
                throw NSError(domain: "WRAP_MISSING", code: -1, userInfo: nil)
            }
            return try decryptWrapped(wrapped: newWrapped)
        }
    }

    private func decryptWrapped(wrapped: Data) throws -> Data {
        // find the private key in Secure Enclave
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: enclaveTag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status != errSecSuccess {
            throw NSError(domain: "ENCLAVE_PRIV", code: Int(status), userInfo: nil)
        }
        let priv = item as! SecKey

        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorX963SHA256AESGCM
        guard SecKeyIsAlgorithmSupported(priv, .decrypt, algorithm) else {
            throw NSError(domain: "ALG", code: -1, userInfo: nil)
        }
        var error: Unmanaged<CFError>?
        guard let aesData = SecKeyCreateDecryptedData(priv, algorithm, wrapped as CFData, &error) as Data? else {
            throw error!.takeRetainedValue() as Error
        }
        return aesData
    }

    // AES-GCM encryption using CryptoKit with unwrapped AES key. Store ciphertext in Keychain
    private func encryptAndStoreCiphertext(tokenKey: String, plaintext: String) throws {
        let aesData = try unwrapAES(tokenKey: tokenKey)
        let key = SymmetricKey(data: aesData)
        let data = Data(plaintext.utf8)
        let sealed = try AES.GCM.seal(data, using: key)
        // store iv|ciphertext|tag
        let iv = sealed.nonce.withUnsafeBytes { Data($0) }
        let ivB64 = iv.base64EncodedString()
        let ctB64 = sealed.ciphertext.base64EncodedString()
        let tagB64 = sealed.tag.base64EncodedString()
        let storedStr = "\(ivB64)|\(ctB64)|\(tagB64)"
        try saveToKeychain(account: cipherAccount(for: tokenKey), data: Data(storedStr.utf8))
    }

    private func readAndDecryptCiphertext(tokenKey: String) throws -> String? {
        guard let storedData = try readFromKeychain(account: cipherAccount(for: tokenKey)) else { return nil }
        guard let storedStr = String(data: storedData, encoding: .utf8) else { return nil }
        let parts = storedStr.split(separator: "|")
        if parts.count != 3 { throw NSError(domain: "BAD_STORE", code: -1, userInfo: nil) }
        guard let iv = Data(base64Encoded: String(parts[0])),
        let ct = Data(base64Encoded: String(parts[1])),
        let tag = Data(base64Encoded: String(parts[2])) else {
            throw NSError(domain: "BAD_B64", code: -1, userInfo: nil)
        }
        let aesData = try unwrapAES(tokenKey: tokenKey)
        let key = SymmetricKey(data: aesData)
        let nonce = try AES.GCM.Nonce(data: iv)
        let sealed = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ct, tag: tag)
        let clear = try AES.GCM.open(sealed, using: key)
        return String(data: clear, encoding: .utf8)
    }

    // MARK: - Public wrappers used in plugin methods:

    private func saveTokenNative(tokenKey: String, plaintext: String) throws {
        // Ensure wrapped AES exists; create if needed; then encrypt and store
        if (try readFromKeychain(account: wrappedAccount(for: tokenKey))) == nil {
            try createAndStoreWrappedAES(tokenKey: tokenKey)
        }
        try encryptAndStoreCiphertext(tokenKey: tokenKey, plaintext: plaintext)
    }

    private func getTokenNative(tokenKey: String) throws -> String? {
        return try readAndDecryptCiphertext(tokenKey: tokenKey)
    }

    private func deleteTokenNative(tokenKey: String) throws {
        // delete ciphertext and wrapped AES key (and optionally keep enclave key)
        deleteFromKeychain(account: cipherAccount(for: tokenKey))
        deleteFromKeychain(account: wrappedAccount(for: tokenKey))
        // Note: we keep Secure Enclave private key (shared across tokens) — it's per-app tag.
    }

    // Rotate: Unwrap existing AES, decrypt stored cipher (if any), create new wrapped AES, re-encrypt
    private func rotateKeyNative(tokenKey: String) throws {
        // decrypt existing plaintext if exists
        var plaintext: String? = nil
        if let existing = try readFromKeychain(account: cipherAccount(for: tokenKey)) {
            if let str = String(data: existing, encoding: .utf8) {
                // decrypt with current AES
                let parts = str.split(separator: "|")
                if parts.count == 3 {
                    guard let iv = Data(base64Encoded: String(parts[0])),
                    let ct = Data(base64Encoded: String(parts[1])),
                    let tag = Data(base64Encoded: String(parts[2])) else {
                        throw NSError(domain: "BAD_B64", code: -1, userInfo: nil)
                    }
                    let aesData = try unwrapAES(tokenKey: tokenKey) // unwrapping current AES
                    let key = SymmetricKey(data: aesData)
                    let nonce = try AES.GCM.Nonce(data: iv)
                    let sealed = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ct, tag: tag)
                    let clear = try AES.GCM.open(sealed, using: key)
                    plaintext = String(data: clear, encoding: .utf8)
                }
            }
        }

        // Delete wrapped AES for this token
        deleteFromKeychain(account: wrappedAccount(for: tokenKey))

        // Create new wrapped AES (this will call ensureEnclaveKeyPair internally)
        try createAndStoreWrappedAES(tokenKey: tokenKey)

        // Re-encrypt plaintext if existed
        if let pt = plaintext {
            try encryptAndStoreCiphertext(tokenKey: tokenKey, plaintext: pt)
        }
    }
}
