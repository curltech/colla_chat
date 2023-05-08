import 'dart:typed_data';

import 'package:video_thumbnail/video_thumbnail.dart';

class VideoUtil {
  static Future<Uint8List?> thumbnailData({
    required String videoFile,
    Map<String, String>? headers,
    ImageFormat imageFormat = ImageFormat.WEBP,
    int maxHeight = 0,
    int maxWidth = 0,
    int timeMs = 0,
    int quality = 10,
  }) async {
    final data = await VideoThumbnail.thumbnailData(
      video: videoFile,
      headers: headers,
      imageFormat: imageFormat,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      timeMs: timeMs,
      // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
      quality: quality,
    );

    return data;
  }

  static Future<String?> thumbnailFile({
    required String videoFile,
    Map<String, String>? headers,
    String? thumbnailPath,
    ImageFormat imageFormat = ImageFormat.WEBP,
    int maxHeight = 0,
    int maxWidth = 0,
    int timeMs = 0,
    int quality = 10,
  }) async {
    final file = await VideoThumbnail.thumbnailFile(
      video: videoFile,
      headers: headers,
      thumbnailPath: thumbnailPath,
      imageFormat: imageFormat,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      timeMs: timeMs,
      // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
      quality: quality,
    );

    return file;
  }
}
