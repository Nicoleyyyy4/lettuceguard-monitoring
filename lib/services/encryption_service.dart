import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  // TANDAAN: Ang key ay dapat exactly 32 characters para sa AES-256
  static final _iv = encrypt.IV.fromLength(16);
  static final _key = encrypt.Key.fromUtf8('lettuceguardsecurekey32byteslong!!'); // 32 chars

  // Pangkontra o pang-encrypt ng data bago i-save sa Firebase
  static String encryptData(String plainText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  // Pang-decrypt ng data pag binasa mula sa Firebase
  static String decryptData(String encryptedText) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_key));
      final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
      return decrypted;
    } catch (e) {
      return 'Decryption Failed';
    }
  }
}