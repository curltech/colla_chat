import 'dart:ui';

import 'package:share_plus/share_plus.dart';

class ShareUtil {
  static Future<ShareResult> share(String text,
      {String? subject, Rect? sharePositionOrigin}) async {
    return await Share.shareWithResult(text,
        subject: subject, sharePositionOrigin: sharePositionOrigin);
  }

  static Future<ShareResult> shareFiles(
    List<String> paths, {
    List<String>? mimeTypes,
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    return await Share.shareFilesWithResult(paths,
        mimeTypes: mimeTypes,
        subject: subject,
        text: text,
        sharePositionOrigin: sharePositionOrigin);
  }
}
