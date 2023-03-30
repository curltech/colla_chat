import 'dart:ui';

import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/xfile_util.dart';
import 'package:cross_file/cross_file.dart';
// import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:share_plus/share_plus.dart';

class ShareUtil {
  static Future<ShareResult> share(String text,
      {String? subject, Rect? sharePositionOrigin}) async {
    return await Share.shareWithResult(text,
        subject: subject, sharePositionOrigin: sharePositionOrigin);
  }

  @Deprecated("Use shareXFiles instead.")
  static Future<void> shareFiles(
    List<String> filenames, {
    List<String>? mimeTypes,
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    return await Share.shareFiles(filenames,
        mimeTypes: mimeTypes,
        subject: subject,
        text: text,
        sharePositionOrigin: sharePositionOrigin);
  }

  static Future<ShareResult> shareXFiles(
    List<String> filenames, {
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    List<XFile> files = [];
    for (var filename in filenames) {
      files.add(XFileUtil.open(filename));
    }
    return await Share.shareXFiles(files,
        subject: subject, text: text, sharePositionOrigin: sharePositionOrigin);
  }

  /// https://github.com/KasemJaffer/receive_sharing_intent
  /// 设置app可以分享其他应用的文件和文本
  // static void sharedMediaStream(
  //     Function(List<SharedMediaFile> files) receiver) {
  //   // For sharing images coming from outside the app while the app is in the memory
  //   ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> files) {
  //     receiver(files);
  //   }, onError: (err) {
  //     logger.i("getIntentDataStream error: $err");
  //   });
  // }
  //
  // static void sharedMediaFile(Function(List<SharedMediaFile> files) receiver) {
  //   // For sharing images coming from outside the app while the app is closed
  //   ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> files) {
  //     receiver(files);
  //   });
  // }
  //
  // static void sharedTextStream(Function(String value) receiver) {
  //   // For sharing or opening urls/text coming from outside the app while the app is in the memory
  //   ReceiveSharingIntent.getTextStream().listen((String value) {
  //     receiver(value);
  //   }, onError: (err) {
  //     logger.i("getLinkStream error: $err");
  //   });
  // }
  //
  // static void sharedText(Function(String? value) receiver) {
  //   // For sharing or opening urls/text coming from outside the app while the app is closed
  //   ReceiveSharingIntent.getInitialText().then((String? value) {
  //     receiver(value);
  //   });
  // }
}
