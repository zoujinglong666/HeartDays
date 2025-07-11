import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class AesUtils {
  static final _algorithm = encrypt.AESMode.cbc;

  /// 生成 32 字节的密钥（使用 SHA256 派生）
  static encrypt.Key deriveKey(String secret) {
    final hash = sha256.convert(utf8.encode(secret)).bytes;
    return encrypt.Key(Uint8List.fromList(hash));
  }

  /// 生成随机 IV（16 字节）
  static encrypt.IV generateIV() {
    return encrypt.IV.fromSecureRandom(16);
  }

  /// 加密文本
  static Map<String, String> encryptText(String plainText, String secret) {
    final key = deriveKey(secret);
    final iv = generateIV();
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: _algorithm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return {
      'iv': iv.base16,
      'encrypted': encrypted.base16,
    };
  }

  /// 解密文本
  static String decryptText(String encryptedHex, String ivHex, String secret) {
    final key = deriveKey(secret);
    final iv = encrypt.IV.fromBase16(ivHex);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: _algorithm));
    final encrypted = encrypt.Encrypted.fromBase16(encryptedHex);
    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return decrypted;
  }
}
