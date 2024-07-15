import 'package:archive/archive_io.dart';

class DownloadProgress {
  DownloadProgressPhase phase;
  int fileSize;
  int downloaded;

  DownloadProgress({
    required this.phase,
    required this.fileSize,
    required this.downloaded,
  });
}

enum DownloadProgressPhase {
  downloading,
  decompressing,
  inactive,
}

class DownloadFileUtil {
  /// 解压缩安装文件
  static Future<void> extractZipFileIsolate(Map data) async {
    try {
      String? zipFilePath = data['zipFile'];
      String? targetPath = data['targetPath'];
      if ((zipFilePath != null) && (targetPath != null)) {
        await extractFileToDisk(zipFilePath, targetPath);
      }
    } catch (e) {
      return;
    }
  }
}
