# Token Saver Plugin 🔐

A high-security Flutter plugin for storing sensitive string data (like Auth Tokens, API Keys, or Private Secrets) using **Hardware-Backed Encryption**. 

Unlike standard storage solutions, this plugin ensures that your encryption keys **never leave the physical secure hardware** of the device.

---

## 🚀 Key Features

- **Hardware Isolation**: Uses **Android StrongBox / TEE** and **iOS Secure Enclave**.
- **AES-256-GCM**: Industry-standard authenticated encryption.
- **Root/Jailbreak Resistance**: Keys are non-exportable; even a compromised OS cannot extract the encryption keys.
- **Key Rotation**: Built-in support to rotate underlying hardware keys for advanced security compliance.
- **Simple API**: Easy-to-use static methods for common operations.

---

## 🛡️ Why use this instead of standard secure storage?

Standard secure storage solutions (like `flutter_secure_storage`) are excellent for general use, but they often rely on software-based key management or standard OS-level Keychain access. 

**Token Saver** is designed for high-stakes environments (Finance, Crypto, Medical, or Enterprise) because:
1. **Physical Security**: The encryption key is generated inside a dedicated hardware chip. 
2. **Anti-Extraction**: There is no way to read the private key bytes out of the hardware.
3. **Tamper Proof**: The hardware co-processor is isolated from the main CPU/OS, providing a secondary layer of defense.

---

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  token_saver:
    path: ./plugins/token_saver
```

---

## 🛠️ Usage

### 1. Save a Token
Securely encrypt and store a sensitive value.
```dart
import 'package:token_saver/secure_token_manager.dart';

await HWSecureSaver.save("access_token", "your_very_sensitive_token_here");
```

### 2. Retrieve a Token
Decrypted using the hardware key and returned as a string.
```dart
String? token = await HWSecureSaver.get("access_token");
 print("Retrieved: $token");
```

### 3. Delete a Token
Removes the encrypted blob and deletes the associated hardware key.
```dart
await HWSecureSaver.delete("access_token");
```

### 4. Rotate Keys (Advanced)
Generates a **new hardware key**, decrypts the existing data with the old key, and re-encrypts it with the new one. Use this periodically to enhance security.
```dart
await HWSecureSaver.rotate("access_token", "optional_new_value_if_refreshing");
```

---

## 📑 Security Specifications

### Android
- **Implementation**: Android KeyStore System.
- **Hardware**: Sets `setIsStrongBoxBacked(true)` for devices that support it (Pixel 3+). Falls back to TEE (Trusted Execution Environment) on older devices.
- **Key Properties**: Non-exportable AES-256 key, GCM mode, no padding.

### iOS
- **Implementation**: Secure Enclave.
- **Hardware**: Dedicated isolated hardware co-processor (iPhone 5s+).
- **Mechanism**: Wrapped Key architecture. A random AES key is wrapped by an EC keypair inside the Secure Enclave.
- **Keychain**: Encrypted blobs are stored with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.

---

## 📝 License
This project is licensed under the MIT License.
