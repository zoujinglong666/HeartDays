import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordUtils {
  /// 对密码进行SHA256加密
  static String encryptPassword(String password) {
    // 使用SHA256算法对密码进行哈希
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 验证密码（比较加密后的密码）
  static bool verifyPassword(String inputPassword, String hashedPassword) {
    final inputHash = encryptPassword(inputPassword);
    return inputHash == hashedPassword;
  }

  /// 生成随机盐值（可选，用于增强安全性）
  static String generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // 取前16位作为盐值
  }

  /// 使用盐值加密密码（更安全的方式）
  static String encryptPasswordWithSalt(String password, String salt) {
    final saltedPassword = password + salt;
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
} 