import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class SimpleEncryptor {
  static final _algorithm = encrypt.AESMode.cbc;

  static encrypt.Key _deriveKey(String secret) {
    final hash = sha256.convert(utf8.encode(secret)).bytes;
    return encrypt.Key(Uint8List.fromList(hash));
  }

  static String encryptText(String plainText, String secret) {
    final key = _deriveKey(secret);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: _algorithm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return iv.base16 + encrypted.base16;
  }

  static String decryptText(String encryptedHex, String secret) {
    final key = _deriveKey(secret);
    final iv = encrypt.IV.fromBase16(encryptedHex.substring(0, 32));
    final cipherHex = encryptedHex.substring(32);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: _algorithm));
    final encrypted = encrypt.Encrypted.fromBase16(cipherHex);
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
