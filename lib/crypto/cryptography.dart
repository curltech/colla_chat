import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:cryptography/cryptography.dart';

import '../tool/util.dart';

class CryptoGraphy {
  CryptoGraphy() {
    FlutterCryptography.enable();
  }

  /// 对消息进行hash处理，输入消息可以为字符串或者uintarray，
  Future<Uint8List> hash(List<int> data) async {
    final sink = Sha512().newHashSink();

    // Add all parts of the authenticated message
    sink.add(data);

    // Calculate hash
    sink.close();
    final hash = await sink.hash();

    return Uint8List.fromList(hash.bytes);
  }

  /// 随机base64位字符串
  Future<String> getRandomAsciiString({int length = 32}) async {
    var randomBytes = CryptoUtil.getRandomBytes(length: length);
    var hash = await this.hash(randomBytes);
    var randomAscii = CryptoUtil.encodeBase64(hash);

    return randomAscii;
  }

  /// 产生密钥对，返回对象为密钥对象（公钥和私钥对象）
  Future<SimpleKeyPair> generateKeyPair(
      {String keyPairType = 'ed25519'}) async {
    // Generate a keypair.
    if (keyPairType == 'ed25519') {
      final algorithm = Ed25519(); //X25519();
      final keyPair = await algorithm.newKeyPair();

      return keyPair;
    } else if (keyPairType == 'x25519') {
      final algorithm = X25519();
      final keyPair = await algorithm.newKeyPair();

      return keyPair;
    }
    throw 'NotSupportKeyPairType';
  }

  ///
  Future<List<int>> getSecretKey(int length) async {
    // Choose the cipher
    final algorithm = AesGcm.with256bits();

    // Generate a random secret key.
    SecretKey secretKey = await algorithm.newSecretKey();
    final secretKeyBytes = await secretKey.extractBytes();

    return Uint8List.fromList(secretKeyBytes);
  }

  /// 将base64的密钥字符串导入转换成密钥对象，如果是私钥，passphrase必须有值用于解密私钥
  Future<Object> import(String base64PublicKey,
      {String? type = 'ed25519',
      String? base64KeyPair,
      List<int>? passphrase}) async {
    KeyPairType type = KeyPairType.ed25519;
    if (type == 'x25519') {
      type = KeyPairType.x25519;
    }
    Uint8List rawText = CryptoUtil.decodeBase64(base64PublicKey);
    SimplePublicKey publicKey = SimplePublicKey(rawText, type: type);

    if (base64KeyPair != null && passphrase != null && passphrase.isNotEmpty) {
      rawText = CryptoUtil.decodeBase64(base64KeyPair);
      var clearText = await aesDecrypt(rawText, passphrase);
      SimpleKeyPair simpleKeyPair =
          SimpleKeyPairData(clearText, publicKey: publicKey, type: type);

      return simpleKeyPair;
    } else {
      return publicKey;
    }
  }

  /// 将密钥对象转换成base64字符串，可以保存
  /// 如果passphrase有值，则到处密钥对并加密，否则，到处公钥，不加密
  Future<String> export(SimpleKeyPair keyPair,
      {List<int>? passphrase, String base = '64'}) async {
    String base64;
    if (passphrase != null && passphrase.isNotEmpty) {
      SimpleKeyPairData simpleKeyPairData = await keyPair.extract();
      List<int> keyPairBytes = simpleKeyPairData.bytes;
      List<int> encryptText = await aesEncrypt(keyPairBytes, passphrase);
      base64 = CryptoUtil.encodeBase64(encryptText);
    } else {
      SimplePublicKey publicKey = await keyPair.extractPublicKey();
      if (base == '58') {
        base64 = CryptoUtil.encodeBase58(publicKey.bytes);
      } else {
        base64 = CryptoUtil.encodeBase64(publicKey.bytes);
      }
    }

    return base64;
  }

  Future<List<int>> sign(List<int> message, KeyPair keyPair,
      {bool includePublicKey = false}) async {
    // Generate a keypair.
    final algorithm = Ed25519();
    // Sign
    final Signature signature = await algorithm.sign(message, keyPair: keyPair);
    SimplePublicKey publicKey = signature.publicKey as SimplePublicKey;
    List<int> result;
    if (includePublicKey) {
      result = CryptoUtil.concat(signature.bytes, publicKey.bytes);
    } else {
      result = signature.bytes;
    }
    return result;
  }

  Future<bool> verify(List<int> message, List<int> signature,
      {String? base64PublicKey, PublicKey? publicKey}) async {
    List<int> signatureBytes = signature.sublist(0, 256);
    if (publicKey == null) {
      if (base64PublicKey != null) {
        publicKey = import(base64PublicKey) as PublicKey;
      } else {
        List<int> publicKeyBytes = signature.sublist(256);
        publicKey = SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519);
      }
    }

    // Generate a keypair.
    final algorithm = Ed25519();
    // Verify signature
    final isSignatureCorrect = await algorithm.verify(
      message,
      signature: Signature(signatureBytes, publicKey: publicKey),
    );
    return isSignatureCorrect;
  }

  /// 密钥交换：采用x25519，做法是本地随机生产一个新的X25519密钥对，与对方的公钥计算出一个对称密钥，
  /// 然后本地用这个对称密钥加密，同时将密文和随机密钥对的公钥发给对方，
  /// 对方利用收到的公钥和自己的私钥（密钥对）同样计算出对称密钥，对密文进行解密
  Future<List<int>> generateSessionKey(
      {required PublicKey remotePublicKey, SimpleKeyPair? localKeyPair}) async {
    final X25519 algorithm = X25519();

    localKeyPair ??= await algorithm.newKeyPair();
    final SecretKey sharedSecret = await algorithm.sharedSecretKey(
      keyPair: localKeyPair,
      remotePublicKey: remotePublicKey,
    );
    final sharedSecretBytes = await sharedSecret.extractBytes();
    var localPublicKey = await localKeyPair.extractPublicKey();
    var localPublicKeyBytes = localPublicKey.bytes;

    return CryptoUtil.concat(localPublicKeyBytes, sharedSecretBytes);
  }

  /// 结合x25519密钥交换和aes进行ecc加解密,里面涉及的密钥对是x25519协议
  /// ecc加密是采用公钥加密，私钥解密，这种加密方式信息不要太大，速度较慢，一般用于加密对称密钥
  Future<Uint8List> eccEncrypt(List<int> message,
      {String? base64PublicKey, PublicKey? remotePublicKey}) async {
    if (remotePublicKey == null) {
      if (base64PublicKey != null) {
        remotePublicKey = import(base64PublicKey) as PublicKey;
      }
    }
    if (remotePublicKey != null) {
      var passphrase =
          await generateSessionKey(remotePublicKey: remotePublicKey);
      var localPublicKeyBytes = passphrase.sublist(0, 256);
      var sharedSecretBytes = passphrase.sublist(256);
      var result = await aesEncrypt(message, sharedSecretBytes);

      return CryptoUtil.concat(localPublicKeyBytes, result);
    }
    throw 'EccEncryptFail';
  }

  Future<List<int>> eccDecrypt(List<int> message,
      {required SimpleKeyPair localKeyPair}) async {
    var remotePublicKeyBytes = message.sublist(0, 256);
    var msg = message.sublist(256);
    SimplePublicKey remotePublicKey =
        SimplePublicKey(remotePublicKeyBytes, type: KeyPairType.x25519);
    var passphrase = await generateSessionKey(
        localKeyPair: localKeyPair, remotePublicKey: remotePublicKey);
    var localPublicKeyBytes = passphrase.sublist(0, 256);
    var sharedSecretBytes = passphrase.sublist(256);
    var result = await aesDecrypt(msg, sharedSecretBytes);

    return result;
  }

  Future<List<int>> aesEncrypt(List<int> message, List<int> passphrase) async {
    // Choose the cipher
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(passphrase);
    // Encrypt
    final secretBox = await algorithm.encrypt(
      message,
      secretKey: secretKey,
    );
    return secretBox.concatenation();
  }

  Future<List<int>> aesDecrypt(List<int> message, List<int> passphrase) async {
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(passphrase);

    SecretBox secretBox =
        SecretBox.fromConcatenation(message, macLength: 16, nonceLength: 16);
    // Decrypt
    final clearText = await algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return clearText;
  }
}

final cryptoGraphy = CryptoGraphy();
