import 'dart:io';

import 'package:path_provider/path_provider.dart';

class PathUtil {
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
