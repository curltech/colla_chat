import 'dart:io';

import 'package:colla_chat/platform.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:path/path.dart' as p;

import 'package:colla_chat/plugin/talker_logger.dart';

class PathUtil {
  ///获取本应用的数据存放路径
  static Future<Directory?> getApplicationDirectory() async {
    Directory? dir;
    try {
      dir = await path.getApplicationDocumentsDirectory();
    } catch (e) {
      print('getApplicationDocumentsDirectory failure:$e');
    }
    if (dir == null) {
      try {
        dir = await path.getApplicationSupportDirectory();
      } catch (e) {
        print('getApplicationSupportDirectory failure:$e');
      }
    }
    if (dir == null && !platformParams.ios) {
      try {
        dir = await path.getExternalStorageDirectory();
      } catch (e) {
        print('getExternalStorageDirectory failure:$e');
      }
    }
    if (dir == null && !platformParams.android) {
      try {
        dir = await path.getLibraryDirectory();
      } catch (e) {
        print('getLibraryDirectory failure:$e');
      }
    }
    return dir;
  }

  /// 获取文档目录文件
  static Future<Directory?> getApplicationDocumentsDirectory() async {
    try {
      return await path.getApplicationDocumentsDirectory();
    } catch (e) {
      logger.e('getApplicationDocumentsDirectory failure:$e');
    }
    return null;
  }

  /// 获取临时目录文件
  static Future<Directory?> getTemporaryDirectory() async {
    try {
      return await path.getTemporaryDirectory();
    } catch (e) {
      logger.e('getTemporaryDirectory failure:$e');
    }
    return null;
  }

  /// 获取应用程序目录文件
  static Future<Directory?> getApplicationSupportDirectory() async {
    try {
      return await path.getApplicationSupportDirectory();
    } catch (e) {
      logger.e('getApplicationSupportDirectory failure:$e');
    }
    return null;
  }

  static Future<Directory?> getLibraryDirectory() async {
    try {
      return await path.getLibraryDirectory();
    } catch (e) {
      logger.e('getLibraryDirectory failure:$e');
    }
    return null;
  }

  static Future<Directory?> getExternalStorageDirectory() async {
    if (platformParams.android || platformParams.windows) {
      final dir = await path.getExternalStorageDirectory();
      return dir;
    }
    return null;
  }

  static Future<Directory?> getDownloadsDirectory() async {
    try {
      return await path.getDownloadsDirectory();
    } catch (e) {
      logger.e('getLibraryDirectory failure:$e');
    }
    return null;
  }

  static Directory? createDir(String path) {
    var dir = Directory(path);
    bool exist = dir.existsSync();
    if (!exist) {
      dir.createSync(recursive: true);

      return dir;
    }
    return null;
  }

  static List<FileSystemEntity> listFile(String path,
      {String? start, String? end}) {
    var dir = Directory(path);
    List<FileSystemEntity> matches = [];
    bool exist = dir.existsSync();
    if (exist) {
      List<FileSystemEntity> files = dir.listSync();
      for (var file in files) {
        String filename = file.path;
        bool startMatch = true;
        bool endMatch = true;
        if (start != null) {
          startMatch = filename.startsWith(start);
        }
        if (end != null) {
          endMatch = filename.endsWith(end);
        }
        if (startMatch && endMatch) {
          matches.add(file);
        }
      }
    }
    return matches;
  }

  static String basename(String path) {
    return p.basename(path);
  }

  static String extension(String path) {
    return p.extension(path);
  }

  static String dirname(String path) {
    return p.dirname(path);
  }
}
