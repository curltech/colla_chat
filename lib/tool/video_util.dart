import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/tool/file_util.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:video_compress/video_compress.dart';
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

  ///支持ANDROID，IOS，MACOS，WINDOWS
  static Future<Uint8List?> videoThumbnailData({
    required String videoFile,
    int width = 1024,
    int height = 768,
    bool keepAspectRatio = true,
    String? format,
    int quality = 10,
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
    int quality = 10,
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

  ///ANDROID,IOS,MACOS
  static Future<MediaInfo?> compressVideo(
    String path, {
    VideoQuality quality = VideoQuality.DefaultQuality,
    bool deleteOrigin = false,
    int? startTime,
    int? duration,
    bool? includeAudio,
    int frameRate = 30,
  }) async {
    MediaInfo? mediaInfo = await VideoCompress.compressVideo(
      path,
      quality: quality,
      deleteOrigin: deleteOrigin,
      startTime: startTime,
      duration: duration,
      includeAudio: includeAudio,
      frameRate: frameRate,
    );

    return mediaInfo;
  }

  ///ANDROID,IOS,MACOS
  static Future<Uint8List?> getByteThumbnail(
    String path, {
    int quality = 10,
    int position = -1,
  }) async {
    final thumbnail = await VideoCompress.getByteThumbnail(path,
        quality: quality, // default(100)
        position: position // default(-1)
        );

    return thumbnail;
  }

  ///ANDROID,IOS,MACOS
  static Future<File> getFileThumbnail(
    String path, {
    int quality = 10,
    int position = -1,
  }) async {
    final thumbnailFile = await VideoCompress.getFileThumbnail(path,
        quality: quality, // default(100)
        position: position // default(-1)
        );

    return thumbnailFile;
  }

  ///ANDROID,IOS,MACOS
  static Future<MediaInfo> getMediaInfo(String path) async {
    final info = await VideoCompress.getMediaInfo(path);

    return info;
  }

  ///ANDROID,IOS,MACOS
  static Future<bool?> deleteAllCache() async {
    return await VideoCompress.deleteAllCache();
  }

  ///ANDROID,IOS,MACOS
  static Subscription compressProgress(Function(double progress) fn) {
    Subscription subscription =
        VideoCompress.compressProgress$.subscribe((double progress) {
      fn(progress);
    });

    return subscription;
  }
}
