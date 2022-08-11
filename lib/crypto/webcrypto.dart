import 'dart:math';
import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:webcrypto/webcrypto.dart';

class WebCrypto {
  WebCrypto() {}

  /// 对消息进行hash处理，输入消息可以为字符串或者uintarray，
  Future<Uint8List> hash(List<int> data) async {
    final digest = await Hash.sha512.digestBytes(data);
    return digest;
  }

  /// 随机字节数组
  Future<Uint8List> getRandomBytes({int length = 32}) async {
    final randomBytes = Uint8List(length);

    var random = Random.secure();
    for (var i = 0; i < randomBytes.length; i++) {
      randomBytes[i] = random.nextInt(256);
    }
    var hash = await this.hash(randomBytes);

    return hash;
  }

  /// 随机base64位字符串
  Future<String> getRandomAsciiString({int length = 32}) async {
    var randomBytes = await getRandomBytes(length: length);
    var hash = await this.hash(randomBytes);
    var randomAscii = CryptoUtil.encodeBase64Url(hash);

    return randomAscii;
  }

  /// 产生密钥对，返回对象为密钥对象（公钥和私钥对象）
  Future<KeyPair<EcdsaPrivateKey, EcdsaPublicKey>> generateEcdsaKeyPair(
      String passphrase) async {
    var keyPair = await EcdsaPrivateKey.generateKey(EllipticCurve.p521);

    return keyPair;
  }

  /// 产生密钥对，返回对象为密钥对象（公钥和私钥对象）
  Future<KeyPair<EcdhPrivateKey, EcdhPublicKey>> generateEcdhKeyPair(
      String passphrase) async {
    var keyPair = await EcdhPrivateKey.generateKey(EllipticCurve.p521);

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
