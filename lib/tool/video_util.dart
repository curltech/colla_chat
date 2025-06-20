import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:easy_video_editor/easy_video_editor.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoUtil {
  static String prefixBase64 = 'data:video/*;base64,';

  static String base64Video(String img, {ChatMessageMimeType? type}) {
    if (type != null) {
      return prefixBase64.replaceFirst('*', type.name) + img;
    } else {
      return prefixBase64 + img;
    }
  }

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
    String? videoFile,
    List<int>? data,
    int width = 1024,
    int height = 768,
    String? format,
    int quality = 10,
  }) async {
    String thumbnailPath = await FileUtil.getTempFilename();
    await videoThumbnailFile(
        videoFile: videoFile,
        data: data,
        thumbnailPath: thumbnailPath,
        width: width,
        height: height,
        format: format,
        quality: quality);
    Uint8List? bytes = await FileUtil.readFileAsBytes(thumbnailPath);

    return bytes;
  }

  /// 使用原生的实现产生视频的缩略图
  /// FcNativeVideoThumbnail实现
  /// 支持ANDROID，IOS，MACOS，WINDOWS
  static Future<void> videoThumbnailFile({
    required String thumbnailPath,
    String? videoFile,
    List<int>? data,
    int width = 1024,
    int height = 768,
    String? format,
    int quality = 10,
  }) async {
    if (videoFile == null && data == null) {
      throw 'videoFile and data can not be empty in same time';
    }
    if (videoFile == null && data != null) {
      videoFile = await FileUtil.writeTempFileAsBytes(data);
    }
    final plugin = FcNativeVideoThumbnail();
    await plugin.getVideoThumbnail(
        srcFile: videoFile!,
        destFile: thumbnailPath,
        width: width,
        height: height,
        format: format,
        quality: quality);
  }

  ///ANDROID,IOS,MACOS
  static Future<MediaInfo?> compressVideo({
    required String videoFile,
    VideoQuality quality = VideoQuality.DefaultQuality,
    bool deleteOrigin = false,
    int? startTime,
    int? duration,
    bool? includeAudio,
    int frameRate = 30,
  }) async {
    MediaInfo? mediaInfo = await VideoCompress.compressVideo(
      videoFile,
      quality: quality,
      deleteOrigin: deleteOrigin,
      startTime: startTime,
      duration: duration,
      includeAudio: includeAudio,
      frameRate: frameRate,
    );

    return mediaInfo;
  }

  /// windows使用原生的实现FcNativeVideoThumbnail实现产生视频的缩略图
  /// mobile使用VideoCompress
  /// ANDROID,IOS,MACOS,WINDOWS
  static Future<Uint8List?> getByteThumbnail({
    String? videoFile,
    List<int>? data,
    int quality = 10,
    int position = 30,
  }) async {
    if (platformParams.windows) {
      final thumbnail =
          await videoThumbnailData(videoFile: videoFile, quality: quality);

      return thumbnail;
    }
    if (platformParams.mobile || platformParams.macos) {
      if (videoFile == null && data == null) {
        throw 'videoFile and data can not be empty in same time';
      }
      if (videoFile == null && data != null) {
        videoFile = await FileUtil.writeTempFileAsBytes(data);
      }
      final thumbnail = await VideoCompress.getByteThumbnail(videoFile!,
          quality: quality, // default(100)
          position: position // default(-1)
          );

      return thumbnail;
    }
    return null;
  }

  /// 获取视频缩略图的临时文件
  /// ANDROID,IOS,MACOS,WINDOWS
  static Future<File?> getFileThumbnail({
    String? videoFile,
    List<int>? data,
    int quality = 10,
    int position = -1,
  }) async {
    if (platformParams.windows) {
      String thumbnailPath = await FileUtil.getTempFilename();
      await videoThumbnailFile(
          thumbnailPath: thumbnailPath, videoFile: videoFile, quality: quality);

      return File(thumbnailPath);
    }
    if (platformParams.mobile || platformParams.macos) {
      if (videoFile == null && data == null) {
        throw 'videoFile and data can not be empty in same time';
      }
      if (videoFile == null && data != null) {
        videoFile = await FileUtil.writeTempFileAsBytes(data);
      }
      final File thumbnailFile =
          await VideoCompress.getFileThumbnail(videoFile!,
              quality: quality, // default(100)
              position: position // default(-1)
              );

      return thumbnailFile;
    }
    return null;
  }

  ///ANDROID,IOS,MACOS
  static Future<MediaInfo> getMediaInfo(String videoFile) async {
    final info = await VideoCompress.getMediaInfo(videoFile);

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

/// mobile device video editor
class VideoEditor {
  final String videoInputPath;
  late final VideoEditorBuilder editor =
      VideoEditorBuilder(videoPath: videoInputPath);

  VideoEditor(this.videoInputPath);

  edit(String outputVideoPath,
      {int? startTimeMs,
      int? endTimeMs,
      List<String>? mergeVideoPaths,
      double? speed,
      VideoResolution? resolution,
      VideoAspectRatio? aspectRatio,
      RotationDegree? degree,
      FlipDirection? flipDirection,
      bool removeAudio = false,
      Function(double)? onProgress}) async {
    if (startTimeMs != null && endTimeMs != null) {
      editor.trim(
          startTimeMs: startTimeMs,
          endTimeMs: endTimeMs); // Trim first 5 seconds
    }
    if (mergeVideoPaths != null) {
      editor.merge(otherVideoPaths: mergeVideoPaths);
    }
    if (speed != null) {
      editor.speed(speed: speed); // Speed up by 1.5x
    }
    if (resolution != null) {
      // resolution = VideoResolution.p720;
      editor.compress(resolution: resolution);
    }
    if (aspectRatio != null) {
      // aspectRatio = VideoAspectRatio.ratio16x9;
      editor.crop(aspectRatio: aspectRatio);
    }
    if (degree != null) {
      // degree = RotationDegree.degree90;
      editor.rotate(degree: degree);
    }
    if (flipDirection != null) {
      // flipDirection= FlipDirection.horizontal;
      editor.flip(flipDirection: flipDirection);
    }
    if (removeAudio) {
      editor.removeAudio();
    }

    final String? outputPath = await editor.export(
        outputPath: outputVideoPath, // Optional output path
        onProgress: onProgress);

    return outputPath;
  }

  Future<String?> extractAudio(String extractAudioPath) async {
    final audioPath = await editor.extractAudio(
        outputPath:
            extractAudioPath // Optional output path, iOS outputs M4A format
        );

    return audioPath;
  }

  generateThumbnail({
    required int positionMs,
    required int quality,
    int? height,
    int? width,
    String? outputPath,
  }) async {
    final thumbnailPath = await editor.generateThumbnail(
        positionMs: positionMs,
        quality: quality,
        width: width,
        // optional
        height: height,
        // optional
        outputPath: outputPath // Optional output path
        );
    return thumbnailPath;
  }

  Future<VideoMetadata> getVideoMetadata() async {
    final metadata = await editor.getVideoMetadata();
    // print('Duration: ${metadata.duration} ms');
    // print('Dimensions: ${metadata.width}x${metadata.height}');
    // print('Orientation: ${metadata.rotation}°');
    // print('File size: ${metadata.fileSize} bytes');
    // print('Creation date: ${metadata.date}');

    return metadata;
  }

  Future<bool> cancel() async {
    return await VideoEditorBuilder.cancel();
  }
}
