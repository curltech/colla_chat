import 'dart:math';
import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';

class CryptoGraphy {
  CryptoGraphy() {
    ///目前在macos上不能使用，其功能是加速快加密的速度
    FlutterCryptography.enable();
  }

  /// 对消息进行hash处理，输入消息可以为字符串或者uintarray，
  Future<List<int>> hash(List<int> data) async {
    final sink = Sha256().newHashSink();

    // Add all parts of the authenticated message
    sink.add(data);

    // Calculate hash
    sink.close();
    final hash = await sink.hash();

    return hash.bytes;
  }

  static const int randomBytesLength = 32;

  /// 随机字节数组
  Future<List<int>> getRandomBytes({int length = randomBytesLength}) async {
    final randomBytes = Uint8List(length);

    var random = Random.secure();
    for (var i = 0; i < randomBytes.length; i++) {
      randomBytes[i] = random.nextInt(256);
    }
    var hash = await this.hash(randomBytes);

    return hash;
  }

  /// 随机base64位字符串
  Future<String> getRandomAsciiString({int length = randomBytesLength}) async {
    var randomBytes = await getRandomBytes(length: length);
    var randomAscii = CryptoUtil.encodeBase64Url(randomBytes);

    return randomAscii;
  }

  static const publicKeyLength = 32;

  /// 产生密钥对，返回对象为密钥对象（公钥和私钥对象）
  Future<SimpleKeyPair> generateKeyPair(
      {KeyPairType keyPairType = KeyPairType.ed25519}) async {
    // Generate a keypair.
    if (keyPairType == KeyPairType.ed25519) {
      final algorithm = Ed25519(); //X25519();
      final keyPair = await algorithm.newKeyPair();

      return keyPair;
    } else if (keyPairType == KeyPairType.x25519) {
      final algorithm = X25519();
      final keyPair = await algorithm.newKeyPair();

      return keyPair;
    }
    throw 'NotSupportKeyPairType';
  }

  static const secretKeyLength = 32;

  Future<List<int>> getSecretKey(int length) async {
    // Choose the cipher
    final algorithm = AesGcm.with256bits();

    // Generate a random secret key.
    SecretKey secretKey = await algorithm.newSecretKey();
    final secretKeyBytes = await secretKey.extractBytes();

    return Uint8List.fromList(secretKeyBytes);
  }

  /// 将密钥对象转换成base64字符串，可以保存
  /// 如果passphrase有值，则到处密钥对并加密，否则，输出公钥，不加密
  Future<String> export(SimpleKeyPair keyPair, List<int> passphrase) async {
    SimpleKeyPairData simpleKeyPairData = await keyPair.extract();
    List<int> keyPairBytes = simpleKeyPairData.bytes;
    List<int> encryptText = await aesEncrypt(keyPairBytes, passphrase);
    String baseStr = CryptoUtil.encodeBase64(encryptText);

    return baseStr;
  }

  /// 将base64的密钥字符串导入转换成密钥对象，passphrase必须有值用于解密私钥
  Future<SimpleKeyPair> import(
      String base64KeyPair, List<int> passphrase, SimplePublicKey publicKey,
      {KeyPairType type = KeyPairType.ed25519}) async {
    if (passphrase.isNotEmpty) {
      Uint8List rawText = CryptoUtil.decodeBase64(base64KeyPair);
      var clearText = await aesDecrypt(rawText, passphrase);
      SimpleKeyPair simpleKeyPair =
          SimpleKeyPairData(clearText, publicKey: publicKey, type: type);

      return simpleKeyPair;
    }
    throw '';
  }

  /// 将密钥对象转换成base58字符串，可以保存
  /// 如果passphrase有值，则到处密钥对并加密，否则，到处公钥，不加密
  Future<String> exportPublicKey(SimpleKeyPair keyPair) async {
    SimplePublicKey publicKey = await keyPair.extractPublicKey();
    String baseStr = CryptoUtil.encodeBase58(publicKey.bytes);

    return baseStr;
  }

  /// 将base64的密钥字符串导入转换成私钥，passphrase必须有值用于解密私钥
  Future<SimplePublicKey> importPublicKey(String base58PublicKey,
      {KeyPairType type = KeyPairType.ed25519}) async {
    Uint8List rawText = CryptoUtil.decodeBase58(base58PublicKey);
    SimplePublicKey publicKey = SimplePublicKey(rawText, type: type);

    return publicKey;
  }

  static const signatureLength = 64;

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
    List<int> signatureBytes = signature.sublist(0, signatureLength);
    if (publicKey == null) {
      if (base64PublicKey != null) {
        publicKey = importPublicKey(base64PublicKey) as PublicKey;
      } else {
        List<int> publicKeyBytes = signature.sublist(signatureLength);
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
  /// 产生的会话密钥64位，前32位时生成的本地公钥，后32位是临时会话密钥
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
  /// ecc加密是采用公钥加密，私钥解密，
  /// 加密后结果的前32位是本地公钥，后面是密文
  Future<List<int>> eccEncrypt(List<int> message,
      {String? base64PublicKey, PublicKey? remotePublicKey}) async {
    if (remotePublicKey == null) {
      if (base64PublicKey != null) {
        remotePublicKey = importPublicKey(base64PublicKey) as PublicKey;
      }
    }
    if (remotePublicKey != null) {
      var passphrase =
          await generateSessionKey(remotePublicKey: remotePublicKey);
      var localPublicKeyBytes = passphrase.sublist(0, publicKeyLength);
      var sharedSecretBytes = passphrase.sublist(publicKeyLength);
      var result = await aesEncrypt(message, sharedSecretBytes);

      return CryptoUtil.concat(localPublicKeyBytes, result);
    }
    throw 'EccEncryptFail';
  }

  /// 结合x25519密钥交换和aes进行ecc加解密,里面涉及的密钥对是x25519协议
  /// ecc加密是采用公钥加密，私钥解密，
  Future<List<int>> eccDecrypt(List<int> message,
      {required SimpleKeyPair localKeyPair}) async {
    var remotePublicKeyBytes = message.sublist(0, publicKeyLength);
    var msg = message.sublist(publicKeyLength);
    SimplePublicKey remotePublicKey =
        SimplePublicKey(remotePublicKeyBytes, type: KeyPairType.x25519);
    var passphrase = await generateSessionKey(
        localKeyPair: localKeyPair, remotePublicKey: remotePublicKey);
    var localPublicKeyBytes = passphrase.sublist(0, publicKeyLength);
    var sharedSecretBytes = passphrase.sublist(publicKeyLength);
    var result = await aesDecrypt(msg, sharedSecretBytes);

    return result;
  }

  Future<List<int>> aesEncrypt(List<int> message, List<int> passphrase,
      {String type = 'gcm'}) async {
    // Choose the cipher
    var hashPassphrase = await hash(passphrase);
    Cipher algorithm;
    switch (type) {
      case 'gcm':
        algorithm = AesGcm.with256bits();
        break;
      case 'ctr':
        algorithm = AesCtr.with256bits(macAlgorithm: Hmac.sha256());
        break;
      case 'cbc':
        algorithm = AesCbc.with256bits(macAlgorithm: Hmac.sha256());
        break;
      case 'chacha20':
        algorithm = Chacha20.poly1305Aead();
        break;
      case 'xchacha20':
        algorithm = Xchacha20.poly1305Aead();
        break;
      default:
        algorithm = AesGcm.with256bits();
        break;
    }
    final secretKey = SecretKey(hashPassphrase);
    // Encrypt
    final secretBox = await algorithm.encrypt(
      message,
      secretKey: secretKey,
    );
    return secretBox.concatenation();
  }

  static const macLength = 16;
  static const nonceLength = 12;

  Future<List<int>> aesDecrypt(List<int> message, List<int> passphrase,
      {String type = 'gcm'}) async {
    var hashPassphrase = await hash(passphrase);
    Cipher algorithm;
    switch (type) {
      case 'gcm':
        algorithm = AesGcm.with256bits();
        break;
      case 'ctr':
        algorithm = AesCtr.with256bits(macAlgorithm: Hmac.sha256());
        break;
      case 'cbc':
        algorithm = AesCbc.with256bits(macAlgorithm: Hmac.sha256());
        break;
      case 'chacha20':
        algorithm = Chacha20.poly1305Aead();
        break;
      case 'xchacha20':
        algorithm = Xchacha20.poly1305Aead();
        break;
      default:
        algorithm = AesGcm.with256bits();
        break;
    }
    final secretKey = SecretKey(hashPassphrase);

    SecretBox secretBox = SecretBox.fromConcatenation(message,
        macLength: macLength, nonceLength: nonceLength);
    // Decrypt
    final clearText = await algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return clearText;
  }

  /// 对消息先进行AES加密，密钥是随机数，对密钥用ecc加密，用自己的私钥和对方的公钥，对方是一个数组
  /// 返回加密后的消息和加密后的密钥数组
  /// 这种方案的最大优势是有多个接收者的时候，对消息只加密一次，节省了运算量，劣势是传递了加密密钥，安全性差一些
  /// @param {*} msg
  /// @param {*} receivers
  /// @param {*} options privateKey私钥
  Future<Map<String, Object>> encrypt(List<int> msg, SimpleKeyPair privateKey,
      List<SimplePublicKey> receivers) async {
    List<int> key = await getRandomBytes();
    List<int> encrypted = await aesEncrypt(msg, key);
    List<List<int>> encryptedKeys = [];
    for (var receiver in receivers) {
      var encryptedKey = await eccEncrypt(key, remotePublicKey: receiver);
      encryptedKeys.add(encryptedKey);
    }

    return {'encrypted': encrypted, 'encryptedKeys': encryptedKeys};
  }

  ///
  /// @param {*} msg
  /// @param {*} privateKey
  /// @param {*} receiver
  /// @param {*} options
  Future<List<int>> decrypt(List<int> msg, List<int> encryptedKey,
      SimpleKeyPair privateKey, SimplePublicKey senderPublicKey) async {
    var key = await eccDecrypt(encryptedKey, localKeyPair: privateKey);
    var decrypted = aesDecrypt(msg, key);

    return decrypted;
  }
}

final cryptoGraphy = CryptoGraphy();
