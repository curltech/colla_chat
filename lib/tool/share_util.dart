import 'dart:ui';

import 'package:share_plus/share_plus.dart';

class ShareUtil {
  /// 共享文本或者文件
  static Future<ShareResult> share({
    String? text,
    String? subject,
    String? title,
    XFile? previewThumbnail,
    Rect? sharePositionOrigin,
    Uri? uri,
    List<XFile>? files,
    List<String>? fileNameOverrides,
    bool downloadFallbackEnabled = true,
    bool mailToFallbackEnabled = true,
  }) async {
    return await SharePlus.instance.share(ShareParams(
        text: text,
        subject: subject,
        title: title,
        previewThumbnail: previewThumbnail,
        sharePositionOrigin: sharePositionOrigin,
        uri: uri,
        files: files,
        fileNameOverrides: fileNameOverrides,
        downloadFallbackEnabled: downloadFallbackEnabled,
        mailToFallbackEnabled: mailToFallbackEnabled));
  }
}
