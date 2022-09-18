import 'package:camera/camera.dart';
import 'package:colla_chat/crypto/util.dart';

class XFileUtil {
  static XFile open(String filename) {
    final file = XFile(filename);

    return file;
  }

  static XFile? fromJson(Map json) {
    var data = json['data'];
    var originBytes = CryptoUtil.decodeBase64(data);
    var mimeType = json['mimeType'];
    var name = json['name'];
    var length = json['length'];
    var lastModified = json['lastModified'];
    var path = json['path'];
    XFile? xfile = XFile.fromData(originBytes,
        mimeType: mimeType,
        name: name,
        length: length,
        lastModified: lastModified,
        path: path);

    return xfile;
  }

  static Future<List<XFile>> fromJsons(List<Map> jsons) async {
    List<XFile> entries = [];
    for (var json in jsons) {
      var entry = fromJson(json);
      entries.add(entry!);
    }

    return entries;
  }

  static Future<Map<String, dynamic>> toJson(
    XFile entry,
  ) async {
    Map<String, dynamic> map = {};
    var originBytes = await entry.readAsBytes();
    map['data'] = CryptoUtil.encodeBase64(originBytes!);
    map['mimeType'] = entry.mimeType;
    map['name'] = entry.name;
    map['length'] = entry.length();
    map['lastModified'] = entry.lastModified;
    map['path'] = entry.path;

    return map;
  }

  static Future<List<Map<String, dynamic>>> toJsons(
    List<XFile> entries,
  ) async {
    List<Map<String, dynamic>> maps = [];
    for (var entry in entries) {
      var map = await toJson(entry);
      maps.add(map);
    }

    return maps;
  }
}
