package com.example.token_saver

import android.content.Context
import android.os.Build
import android.util.Base64
import android.util.Log
import androidx.annotation.NonNull
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** TokenSaverPlugin (Android native-only) */
class TokenSaverPlugin: FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel : MethodChannel
    private lateinit var applicationContext: Context

    companion object {
        private const val TAG = "TokenSaverPlugin"
        private const val CHANNEL_NAME = "token_saver"
        private const val KEY_ALIAS_PREFIX = "token_saver_hw_aes_" // alias per token key
        private const val PREFS_NAME = "token_saver_prefs"
        private const val GCM_TAG_BITS = 128
    }

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        applicationContext = binding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "saveToken" -> {
                    val key = call.argument<String>("key") ?: ""
                    val value = call.argument<String>("value") ?: ""
                    val ok = saveTokenNative(key, value)
                    result.success(ok)
                }
                "getToken" -> {
                    val key = call.argument<String>("key") ?: ""
                    val value = getTokenNative(key)
                    result.success(value)
                }
                "deleteToken" -> {
                    val key = call.argument<String>("key") ?: ""
                    deleteTokenNative(key)
                    result.success(true)
                }
                "rotateKey" -> {
                    val key = call.argument<String>("key") ?: ""
                    val ok = rotateKeyNative(key)
                    result.success(ok)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in methodCall", e)
            result.error("ERR_NATIVE", e.localizedMessage, null)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // ---------------------- Helpers ----------------------

    private fun aliasFor(key: String): String = KEY_ALIAS_PREFIX + key

    // Ensure AES key exists for alias in AndroidKeyStore (non-exportable). Prefer StrongBox when available.
    private fun ensureHardwareKey(alias: String) {
        val ks = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        if (ks.containsAlias(alias)) return

        val keyGen = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        val builder = KeyGenParameterSpec.Builder(
            alias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
        // optional: require user authentication for key usage
        // .setUserAuthenticationRequired(true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                builder.setIsStrongBoxBacked(true)
            } catch (e: Exception) {
                Log.w(TAG, "StrongBox not available for this device: ${e.message}")
            }
        }
        keyGen.init(builder.build())
        keyGen.generateKey()
    }

    // Save token: encrypt using hardware key for this name and store iv|ciphertext|tag in prefs
    private fun saveTokenNative(tokenKey: String, plaintext: String): Boolean {
        val alias = aliasFor(tokenKey)
        ensureHardwareKey(alias)
        val ks = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val secretKey = ks.getKey(alias, null) as SecretKey
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, secretKey)
        val iv = cipher.iv // typically 12 bytes
        val ctWithTag = cipher.doFinal(plaintext.toByteArray(Charsets.UTF_8))

        // split tag (last 16 bytes) from ciphertext
        val tagLen = GCM_TAG_BITS / 8
        if (ctWithTag.size < tagLen) throw IllegalStateException("Ciphertext too small")
        val cipherOnly = ctWithTag.sliceArray(0 until (ctWithTag.size - tagLen))
        val tag = ctWithTag.sliceArray((ctWithTag.size - tagLen) until ctWithTag.size)

        val ivB64 = Base64.encodeToString(iv, Base64.NO_WRAP)
        val ctB64 = Base64.encodeToString(cipherOnly, Base64.NO_WRAP)
        val tagB64 = Base64.encodeToString(tag, Base64.NO_WRAP)
        val stored = "$ivB64|$ctB64|$tagB64"

        val prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(tokenKey, stored).apply()
        return true
    }

    // Get token: read stored string and decrypt using the hardware key for this tokenKey
    private fun getTokenNative(tokenKey: String): String? {
        val prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val stored = prefs.getString(tokenKey, null) ?: return null

        val parts = stored.split("|")
        if (parts.size != 3) throw IllegalArgumentException("Malformed stored ciphertext")

        val iv = Base64.decode(parts[0], Base64.NO_WRAP)
        val cipherOnly = Base64.decode(parts[1], Base64.NO_WRAP)
        val tag = Base64.decode(parts[2], Base64.NO_WRAP)

        // rebuild ct = cipherOnly || tag
        val ct = ByteArray(cipherOnly.size + tag.size)
        System.arraycopy(cipherOnly, 0, ct, 0, cipherOnly.size)
        System.arraycopy(tag, 0, ct, cipherOnly.size, tag.size)

        val alias = aliasFor(tokenKey)
        val ks = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val secretKey = ks.getKey(alias, null) as? SecretKey ?: throw IllegalStateException("Key not found for alias $alias")
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val spec = GCMParameterSpec(GCM_TAG_BITS, iv)
        cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)
        val plain = cipher.doFinal(ct)
        return String(plain, Charsets.UTF_8)
    }

    // Delete token ciphertext and key (both)
    private fun deleteTokenNative(tokenKey: String) {
        val prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove(tokenKey).apply()
        val alias = aliasFor(tokenKey)
        val ks = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        if (ks.containsAlias(alias)) ks.deleteEntry(alias)
    }

    // Rotate key: decrypt existing token (if any), delete old key, generate new key, re-encrypt and store
    private fun rotateKeyNative(tokenKey: String): Boolean {
        val prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val existing = prefs.getString(tokenKey, null)
        val plaintext: String? = if (existing != null) {
            try {
                getTokenNative(tokenKey)
            } catch (e: Exception) {
                throw RuntimeException("Failed to decrypt existing token during rotate: ${e.localizedMessage}")
            }
        } else null

        val alias = aliasFor(tokenKey)
        val ks = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        if (ks.containsAlias(alias)) ks.deleteEntry(alias)

        // generate new hardware-backed key
        ensureHardwareKey(alias)

        // re-encrypt if plaintext existed
        if (plaintext != null) {
            saveTokenNative(tokenKey, plaintext)
        }
        return true
    }
}
