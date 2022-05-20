import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

class CryptoUtil {
  /// 把输入的Uint8Array转换成base64的string
  static String encodeBase64(Uint8List data) {
    return base64Encode(data);
  }

  /// 把输入的base64格式的string转换成普通的Uint8Array
  static Uint8List decodeBase64(String code) {
    var data = Uint8List.fromList(base64Decode(code));

    return data;
  }

  static String stringToUtf8(String str) {
    List<int> l = utf8.encode(str);
    return String.fromCharCodes(l);
  }

  static String utf8ToString(String str) {
    String data = utf8.decode(Uint8List.fromList(str.codeUnits));
    return data;
  }

  static Uint8List strToUint8List(String message) {
    Uint8List msg = Uint8List.fromList(message.codeUnits);

    return msg;
  }

  static String uint8ListToStr(Uint8List message) {
    String msg = String.fromCharCodes(message);

    return msg;
  }

  /// 随机字节数组
  static Uint8List getRandomBytes({int length = 32}) {
    final bytes = Uint8List(length);

    var random = Random.secure();
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }

    return bytes;
  }

  static Uint8List concat(List<int> src, List<int> target) {
    var n = src.length + target.length;
    final result = Uint8List(n);
    var i = 0;
    result.setAll(i, src);
    i += src.length;
    result.setAll(i, target);

    return result;
  }
}
