import 'dart:typed_data';

import 'package:colla_chat/tool/file_util.dart';
import 'package:flutter/material.dart';
import 'package:pro_video_editor/pro_video_editor.dart' as pro;

/// ProVideoEditor实现的适用于移动和mac平台的视频编辑类
/// 输入的视频可以是文件格式或者是数据
class ProVideoRender {
  final String? videoInputPath;
  final Uint8List? videoBytes;
  late final pro.ProVideoEditor editor = pro.ProVideoEditor.instance;
  late pro.EditorVideo editorVideo;

  ProVideoRender({this.videoInputPath, this.videoBytes}) {
    if (videoInputPath != null) {
      editorVideo = pro.EditorVideo.file(videoInputPath);
    }
    if (videoBytes != null) {
      editorVideo = pro.EditorVideo.memory(videoBytes!);
    }
  }

  /// 对视频进行各种渲染操作
  Future<String?> render(
      {int? startTimeMs,
      int? endTimeMs,
      double? blur,
      Uint8List? overlayImageBytes,
      double? playbackSpeed,
      int? bitrate,
      List<List<double>> colorMatrixList = const [],
      int? cropWidth,
      int? cropHeight,
      int? cropX,
      int? cropY,
      bool flipX = false,
      bool flipY = false,
      double? scaleX,
      double? scaleY,
      int rotateTurns = 0,
      bool enableAudio = true,
      Size? resolution,
      pro.VideoQualityPreset? preset,
      Function(StreamBuilder)? onCreatedProgressStreamBuilder,
      Function(double)? onProgress}) async {
    String taskId = DateTime.now().microsecondsSinceEpoch.toString();
    pro.VideoQualityConfig? qualityConfig;
    if (bitrate != null && resolution != null && preset != null) {
      qualityConfig = pro.VideoQualityConfig(
          bitrate: bitrate, resolution: resolution, preset: preset);
    }
    var data = pro.VideoRenderData(
        id: taskId,
        video: editorVideo,
        outputFormat: pro.VideoOutputFormat.mp4,
        // 输出是否包含音频
        enableAudio: enableAudio,
        // 放置图像
        imageBytes: overlayImageBytes,
        // 视频播放速度
        playbackSpeed: playbackSpeed,
        // 视频字节率
        bitrate: bitrate,
        // 视频模糊
        blur: blur,
        // 视频过滤
        colorMatrixList: colorMatrixList,
        // 视频截取功能
        startTime:
            startTimeMs != null ? Duration(milliseconds: startTimeMs) : null,
        endTime: endTimeMs != null ? Duration(milliseconds: endTimeMs) : null,
        // 视频转换功能，包括裁剪，旋转，缩放
        transform: pro.ExportTransform(
            width: cropWidth,
            height: cropHeight,
            rotateTurns: rotateTurns,
            x: cropX,
            y: cropY,
            flipX: flipX,
            flipY: flipY,
            scaleX: scaleX,
            scaleY: scaleY),
        qualityConfig: qualityConfig);
    final Uint8List exportedVideo =
        await pro.ProVideoEditor.instance.renderVideo(data);
    StreamBuilder streamBuilder =
        getProgressStreamBuilder(taskId, onProgress: onProgress);
    if (onCreatedProgressStreamBuilder != null) {
      onCreatedProgressStreamBuilder(streamBuilder);
    }
    final filename = await FileUtil.writeTempFileAsBytes(exportedVideo);

    return filename;
  }

  /// 渲染任务的流
  StreamBuilder getProgressStreamBuilder(String taskId,
      {Function(double)? onProgress}) {
    return StreamBuilder<pro.ProgressModel>(
      stream: editor.progressStreamById(taskId),
      builder: (context, snapshot) {
        double progress = snapshot.data?.progress ?? 0;
        if (onProgress != null) {
          onProgress(progress);
        }
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: const Duration(milliseconds: 300),
          builder: (context, animatedValue, _) {
            return Column(
              spacing: 7,
              children: [
                CircularProgressIndicator(
                  value: animatedValue,
                ),
                Text('${(animatedValue * 100).toStringAsFixed(1)} / 100'),
              ],
            );
          },
        );
      },
    );
  }

  /// 生成缩略图
  Future<List<ImageProvider<Object>>> getThumbnails(
      {required int thumbnailCount,
      required double height,
      required double width,
      pro.ThumbnailFormat outputFormat = pro.ThumbnailFormat.jpeg}) async {
    final pro.VideoMetadata videoMetadata =
        await editor.getMetadata(editorVideo);
    final duration = videoMetadata.duration;
    final segmentDuration = duration.inMilliseconds / thumbnailCount;
    final pro.ThumbnailConfigs thumbnailConfigs = pro.ThumbnailConfigs(
      video: editorVideo,
      outputSize: Size(width, height),
      boxFit: pro.ThumbnailBoxFit.cover,
      timestamps: List.generate(thumbnailCount, (i) {
        final midpointMs = (i + 0.5) * segmentDuration;
        return Duration(milliseconds: midpointMs.round());
      }),
      outputFormat: outputFormat,
    );
    final List<Uint8List> thumbnailList =
        await editor.getThumbnails(thumbnailConfigs);
    List<ImageProvider>? thumbnails =
        thumbnailList.map(MemoryImage.new).toList();

    return thumbnails;
  }

  /// 获取关键帧
  /// On android `getKeyFrames` is a way faster than `getThumbnails` but
  //  the timestamps are more "random". If you want the best results i
  //  recommend you to use only `getThumbnails`.
  Future<List<ImageProvider<Object>>> getKeyFrames({
    required double height,
    required double width,
    pro.ThumbnailFormat outputFormat = pro.ThumbnailFormat.jpeg,
    int? maxOutputFrames,
  }) async {
    List<Uint8List> thumbnailList = await editor.getKeyFrames(
      pro.KeyFramesConfigs(
        video: editorVideo,
        outputFormat: outputFormat,
        maxOutputFrames: maxOutputFrames,
        outputSize: Size(width, height),
        boxFit: pro.ThumbnailBoxFit.cover,
      ),
    );
    List<ImageProvider>? thumbnails =
        thumbnailList.map(MemoryImage.new).toList();

    return thumbnails;
  }

  /// 获取视频的元数据
  Future<pro.VideoMetadata> getMetadata() async {
    final pro.VideoMetadata videoMetadata =
        await editor.getMetadata(editorVideo);

    return videoMetadata;
  }
}
