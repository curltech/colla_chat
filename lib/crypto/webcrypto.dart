import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';

import '../tool/util.dart';

import 'package:webcrypto/webcrypto.dart';

class WebCrypto {
  WebCrypto() {}

  /// 对消息进行hash处理，输入消息可以为字符串或者uintarray，
  Future<Uint8List> hash(List<int> data) async {
    final digest = await Hash.sha512.digestBytes(data);
    return digest;
  }

  /// 随机base64位字符串
  Future<String> getRandomAsciiString({int length = 32}) async {
    var randomBytes = CryptoUtil.getRandomBytes(length: length);
    var hash = await this.hash(randomBytes);
    var randomAscii = CryptoUtil.encodeBase64(hash);

    return randomAscii;
  }

  /// 产生密钥对，返回对象为密钥对象（公钥和私钥对象）
  Future<KeyPair<EcdsaPrivateKey, EcdsaPublicKey>> generateKey(
      String passphrase,
      {String keyPairType = 'ed25519'}) async {
    var keyPair = await EcdsaPrivateKey.generateKey(EllipticCurve.p521);

    return keyPair;
  }

  /// 类名
  ///AesCbcSecretKey
  // AesCtrSecretKey
  // AesGcmSecretKey
  // EcdhPrivateKey
  // EcdhPublicKey
  // EcdsaPrivateKey
  // EcdsaPublicKey
  // Hash
  // HkdfSecretKey
  // HmacSecretKey
  // KeyPair
  // Pbkdf2SecretKey
  // RsaOaepPrivateKey
  // RsaOaepPublicKey
  // RsaPssPrivateKey
  // RsaPssPublicKey
  // RsassaPkcs1V15PrivateKey
  // RsassaPkcs1V15PublicK
  Future<AesGcmSecretKey> getSecretKey(int length) async {
    // Choose the cipher
    return AesGcmSecretKey.generateKey(length);
  }
}
