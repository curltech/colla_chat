import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:bs58/bs58.dart';
import 'package:archive/archive.dart';

class CryptoUtil {
  /// 把输入的Uint8Array转换成base64的string
  static String encodeBase64(List<int> data) {
    return base64Encode(data);
  }

  /// 把输入的base64格式的string转换成普通的Uint8Array
  static Uint8List decodeBase64(String code) {
    return base64Decode(code);
  }

  /// 把输入的Uint8Array转换成base58的string
  static String encodeBase58(List<int> data) {
    return base58.encode(Uint8List.fromList(data));
  }

  /// 把输入的base58格式的string转换成普通的Uint8Array
  static Uint8List decodeBase58(String code) {
    return base58.decode(code);
  }

  /// 把输入的Uint8Array转换成base58的string
  static String encodeBase64Url(List<int> data) {
    return base64Url.encode(data);
  }

  /// 把输入的base58格式的string转换成普通的Uint8Array
  static Uint8List decodeBase64Url(String code) {
    return base64Url.decode(code);
  }

  static String stringToUtf8(String str) {
    List<int> l = utf8.encode(str);

    return String.fromCharCodes(l);
  }

  static String utf8ToString(String str) {
    String data = utf8.decode(str.codeUnits);

    return data;
  }

  static Uint8List strToUint8List(String message) {
    Uint8List msg = Uint8List.fromList(message.codeUnits);

    return msg;
  }

  static String uint8ListToStr(List<int> message) {
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

  ///GZIP 压缩
  static List<int> compress(List<int> data) {
    //gzip 压缩
    List<int>? gzipBytes = GZipEncoder().encode(data);
    if (gzipBytes == null) {
      throw 'CompressFail';
    }
    return gzipBytes;
  }

  ///GZIP 解压缩
  static List<int> uncompress(List<int> data) {
    //使用 gzip 压缩
    List<int> gzipBytes = GZipDecoder().decodeBytes(data);

    return gzipBytes;
  }

  ///GZIP 压缩
  static String gzipEncode(String str) {
    //先来转换一下
    List<int> stringBytes = utf8.encode(str);
    //然后使用 gzip 压缩
    List<int>? gzipBytes = compress(stringBytes);
    //然后再编码一下进行网络传输
    String compressedString = encodeBase64Url(gzipBytes!);
    return compressedString;
  }

  ///GZIP 解压缩
  static String gzipDencode(String str) {
    //先来解码一下
    List<int> stringBytes = decodeBase64Url(str);
    //然后使用 gzip 压缩
    List<int> gzipBytes = uncompress(stringBytes);
    //然后再编码一下
    String compressedString = utf8.decode(gzipBytes);
    return compressedString;
  }
}
