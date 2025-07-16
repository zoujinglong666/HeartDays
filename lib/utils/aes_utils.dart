import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class AesUtils {
  static final _algorithm = encrypt.AESMode.cbc;
  
  // 使用固定的密钥，实际项目中应该从环境变量或安全存储中获取
  static const String _secretKey = "your-secret-key-32-chars-long!!";

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
  static Map<String, String> encryptText(String plainText, {String? secret}) {
    final key = deriveKey(secret ?? _secretKey);
    final iv = generateIV();
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: _algorithm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return {
      'iv': iv.base16,
      'encrypted': encrypted.base16,
    };
  }

  /// 解密文本
  static String decryptText(String encryptedHex, String ivHex, {String? secret}) {
    final key = deriveKey(secret ?? _secretKey);
    final iv = encrypt.IV.fromBase16(ivHex);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: _algorithm));
    final encrypted = encrypt.Encrypted.fromBase16(encryptedHex);
    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return decrypted;
  }

  /// 加密密码（返回加密后的字符串，包含IV和加密数据）
  static String encryptPassword(String password) {
    final result = encryptText(password);
    // 将IV和加密数据组合成一个字符串，用分隔符分开
    return "${result['iv']}:${result['encrypted']}";
  }

  /// 解密密码
  static String decryptPassword(String encryptedPassword) {
    final parts = encryptedPassword.split(':');
    if (parts.length != 2) {
      throw Exception('Invalid encrypted password format');
    }
    return decryptText(parts[1], parts[0]);
  }
} 