import 'dart:ui';

import 'package:colla_chat/tool/xfile_util.dart';
import 'package:cross_file/cross_file.dart';
import 'package:share_plus/share_plus.dart';

class ShareUtil {
  static Future<ShareResult> share(String text,
      {String? subject, Rect? sharePositionOrigin}) async {
    return await Share.shareWithResult(text,
        subject: subject, sharePositionOrigin: sharePositionOrigin);
  }

  static Future<ShareResult> shareFiles(
    List<String> filenames, {
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    List<XFile> files =[];
    for (var filename in filenames){
      files.add(XFileUtil.open(filename));
    }
    return await Share.shareXFiles(files,
        subject: subject, text: text, sharePositionOrigin: sharePositionOrigin);
  }
}
