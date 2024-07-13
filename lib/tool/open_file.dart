import 'package:open_filex/open_filex.dart';

/// 使用系统的应用打开文件
class OpenFileUtil {
  static Future<OpenResult> open(
    String filename, {
    String? type,
    String? uti,
    String linuxDesktopName = "xdg",
    bool linuxByProcess = false,
  }) async {
    final OpenResult result = await OpenFilex.open(filename,
        type: type,
        uti: uti,
        linuxDesktopName: linuxDesktopName,
        linuxByProcess: linuxByProcess);

    return result;
  }
}
