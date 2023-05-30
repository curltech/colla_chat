import 'dart:typed_data';

import 'package:colla_chat/tool/file_util.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoUtil {
  ///支持ANDROID，IOS
  static Future<Uint8List?> thumbnailData({
    required String videoFile,
    Map<String, String>? headers,
    ImageFormat imageFormat = ImageFormat.WEBP,
    int width = 1024,
    int height = 768,
    int timeMs = 0,
    int quality = 10,
  }) async {
    final data = await VideoThumbnail.thumbnailData(
      video: videoFile,
      headers: headers,
      imageFormat: imageFormat,
      maxHeight: height,
      maxWidth: width,
      timeMs: timeMs,
      // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
      quality: quality,
    );

    return data;
  }

  ///支持ANDROID，IOS
  static Future<String?> thumbnailFile({
    required String videoFile,
    Map<String, String>? headers,
    String? thumbnailPath,
    ImageFormat imageFormat = ImageFormat.WEBP,
    int width = 1024,
    int height = 768,
    int timeMs = 0,
    int quality = 10,
  }) async {
    final file = await VideoThumbnail.thumbnailFile(
      video: videoFile,
      headers: headers,
      thumbnailPath: thumbnailPath,
      imageFormat: imageFormat,
      maxHeight: height,
      maxWidth: width,
      timeMs: timeMs,
      // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
      quality: quality,
    );

    return file;
  }

  static Future<Uint8List?> videoThumbnailData({
    required String videoFile,
    int width = 1024,
    int height = 768,
    bool keepAspectRatio = true,
    String? format,
    int quality = 30,
  }) async {
    String thumbnailPath = await FileUtil.getTempFilename();
    await videoThumbnailFile(
        videoFile: videoFile,
        thumbnailPath: thumbnailPath,
        width: width,
        height: height,
        keepAspectRatio: keepAspectRatio,
        format: format,
        quality: quality);
    Uint8List? data = await FileUtil.readFile(thumbnailPath);

    return data;
  }

  ///支持ANDROID，IOS，MACOS，WINDOWS
  static Future<void> videoThumbnailFile({
    required String videoFile,
    required String thumbnailPath,
    int width = 1024,
    int height = 768,
    bool keepAspectRatio = true,
    String? format,
    int quality = 30,
  }) async {
    final plugin = FcNativeVideoThumbnail();
    await plugin.getVideoThumbnail(
        srcFile: videoFile,
        destFile: thumbnailPath,
        width: width,
        height: height,
        keepAspectRatio: keepAspectRatio,
        format: format,
        quality: quality);
  }
}
