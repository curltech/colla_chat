import 'dart:io';

import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:path_provider/path_provider.dart';

class PathUtil {
  ///获取本应用的数据存放路径
  static Future<Directory?> getApplicationDirectory() async {
    Directory? dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (e) {
      logger.e(e.toString());
    }
    if (dir == null) {
      try {
        dir = await getApplicationSupportDirectory();
      } catch (e) {
        logger.e(e.toString());
      }
    }
    if (dir == null && !platformParams.ios) {
      try {
        dir = await getExternalStorageDirectory();
      } catch (e) {
        logger.e(e.toString());
      }
    }
    if (dir == null && !platformParams.android) {
      try {
        dir = await getLibraryDirectory();
      } catch (e) {
        logger.e(e.toString());
      }
    }
    return dir;
  }

  /// 获取文档目录文件
  static Future<Directory> getLocalDocumentFile() async {
    final dir = await getApplicationDocumentsDirectory();

    return dir;
  }

  /// 获取临时目录文件
  static Future<Directory> getLocalTemporaryFile() async {
    final dir = await getTemporaryDirectory();
    return dir;
  }

  /// 获取应用程序目录文件
  static Future<Directory> getLocalSupportFile() async {
    final dir = await getApplicationSupportDirectory();
    return dir;
  }

  static Future<Directory> getLibraryDirectory() async {
    final dir = await getLibraryDirectory();
    return dir;
  }

  static Future<Directory> getExternalStorageDirectory() async {
    final dir = await getLibraryDirectory();
    return dir;
  }

  static Future<Directory> getDownloadsDirectory() async {
    final dir = await getDownloadsDirectory();
    return dir;
  }
}
