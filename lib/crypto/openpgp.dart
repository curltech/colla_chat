import 'dart:typed_data';

import 'package:openpgp/openpgp.dart' as flutter_openpgp;

import '../tool/util.dart';

typedef FlutterOpenPGP = flutter_openpgp.OpenPGP;

class OpenPGP {
  /// 产生密钥对，返回对象为密钥对象（公钥和私钥对象）
  Future<flutter_openpgp.KeyPair> generateKey(String passphrase,
      {String? name, String? email}) async {
    var keyOptions = flutter_openpgp.KeyOptions()..rsaBits = 2048;
    var keyPair = await FlutterOpenPGP.generate(
        options: flutter_openpgp.Options()
          ..name = name
          ..email = email
          ..passphrase = passphrase
          ..keyOptions = keyOptions);

    return keyPair;
  }

  /// 将armored的密钥字符串导入转换成密钥对象，如果是私钥，options.password必须有值用于解密私钥
  flutter_openpgp.KeyPair import(String jsonString) {
    Map pair = JsonUtil.toMap(jsonString);
    flutter_openpgp.KeyPair keyPair =
        flutter_openpgp.KeyPair(pair['publicKey'], pair['privateKey']);

    return keyPair;
  }

  /// 将密钥对象转换成armored的字符串，可以保存
  String export(flutter_openpgp.KeyPair keyPair) {
    Map<String, dynamic> pair = {
      'publicKey': keyPair.publicKey,
      'privateKey': keyPair.privateKey
    };

    return JsonUtil.toJsonString(pair);
  }

  Uint8List _toUint8List(dynamic message) {
    Uint8List msg;
    if (message is String) {
      msg = Uint8List.fromList(message.codeUnits);
    } else if (message is Uint8List) {
      msg = message;
    } else {
      var jsonString = JsonUtil.toJsonString(message);
      msg = Uint8List.fromList(jsonString.codeUnits);
    }

    return msg;
  }

  Future<String> sign(
      dynamic message, String publicKey, String privateKey, String passphrase,
      {flutter_openpgp.KeyOptions? options}) async {
    var msg = _toUint8List(message);

    var result = await FlutterOpenPGP.signBytesToString(
        msg, publicKey, privateKey, passphrase,
        options: options);

    return result;
  }

  Future<bool> verify(
      String signature, dynamic message, String publicKey) async {
    var msg = _toUint8List(message);

    var result = await FlutterOpenPGP.verifyBytes(signature, msg, publicKey);

    return result;
  }

  Future<Uint8List> eccEncrypt(dynamic message, String publicKey,
      {flutter_openpgp.KeyOptions? options,
      flutter_openpgp.Entity? signed,
      flutter_openpgp.FileHints? fileHints}) async {
    var msg = _toUint8List(message);
    var result = await FlutterOpenPGP.encryptBytes(msg, publicKey,
        options: options, signed: signed, fileHints: fileHints);

    return result;
  }

  Future<String> eccDecrypt(
      Uint8List message, String privateKey, String passphrase,
      {flutter_openpgp.KeyOptions? options}) async {
    var result = await FlutterOpenPGP.decryptBytes(
        message, privateKey, passphrase,
        options: options);

    var msg = String.fromCharCodes(result);

    return msg;
  }

  Future<Uint8List> aesEncrypt(Uint8List message, String passphrase,
      {flutter_openpgp.KeyOptions? options,
      flutter_openpgp.FileHints? fileHints}) async {
    var msg = _toUint8List(message);
    var result = await FlutterOpenPGP.encryptSymmetricBytes(msg, passphrase,
        options: options, fileHints: fileHints);

    return result;
  }

  Future<String> aesDecrypt(Uint8List message, String passphrase,
      {flutter_openpgp.KeyOptions? options}) async {
    var result = await FlutterOpenPGP.decryptSymmetricBytes(message, passphrase,
        options: options);
    var msg = String.fromCharCodes(result);

    return msg;
  }
}
