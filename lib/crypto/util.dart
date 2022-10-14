import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:bs58/bs58.dart';

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

  /// 把输入的Uint8List转换成base64url的string,保证网络传输安全
  static String encodeBase64Url(List<int> data) {
    return base64Url.encode(data);
  }

  /// 把输入的base64url格式的string还原成普通的Uint8List
  static Uint8List decodeBase64Url(String code) {
    return base64Url.decode(code);
  }

  /// Dart中的String编码格式是UTF-16，把普通字符串（前端）转换成utf8编码，方便支持中文
  static List<int> stringToUtf8(String data) {
    List<int> result = utf8.encode(data);

    return result;
  }

  /// 把utf8编码的字节还原成普通字符串（前端）
  static String utf8ToString(List<int> raw) {
    String data = utf8.decode(raw);

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

  static List<int> concat(List<int> src, List<int> target) {
    // var n = src.length + target.length;
    // final result = List.filled(n, 0, growable: false);
    // var i = 0;
    // result.setAll(i, src);
    // i += src.length;
    // result.setAll(i, target);

    var builder = BytesBuilder();
    builder.add(src);
    builder.add(target);
    var result = builder.toBytes();

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
    List<int> gzipBytes = compress(stringBytes);
    //然后再编码一下进行网络传输
    String compressedString = encodeBase64Url(gzipBytes);
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
