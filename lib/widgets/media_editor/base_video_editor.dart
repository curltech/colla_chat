import 'dart:ui';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:video_editor_2/video_editor.dart' as base;

/// VideoEditor2实现的视频编辑功能类，内置视频播放器
class BaseVideoEditor {
  final String videoInputPath;
  base.VideoEditorController? editor;

  BaseVideoEditor(this.videoInputPath);

  void _init(
      {Duration maxDuration = Duration.zero,
      Duration minDuration = Duration.zero,
      base.CoverSelectionStyle coverStyle = const base.CoverSelectionStyle(),
      base.CropGridStyle cropStyle = const base.CropGridStyle(),
      base.TrimSliderStyle? trimStyle,
      int defaultCoverThumbnailQuality = 10,
      double? aspectRatio}) {
    editor = base.VideoEditorController.file(XFile(videoInputPath),
        minDuration: minDuration,
        maxDuration: maxDuration,
        coverStyle: coverStyle,
        cropStyle: cropStyle,
        trimStyle: trimStyle,
        defaultCoverThumbnailQuality: defaultCoverThumbnailQuality);
    editor!.initialize(aspectRatio: aspectRatio);
  }

  void dispose() {
    editor?.dispose();
  }

  Future<void> edit(String outputVideoPath,
      {double? minTrimPos,
      double? maxTrimPos,
      Offset? cropTopLeft,
      Offset? cropBottomRight,
      double? aspectRatio,
      base.RotateDirection? direction}) async {
    if (minTrimPos != null && maxTrimPos != null) {
      editor!.updateTrim(minTrimPos, maxTrimPos); // Trim first 5 seconds
    }
    if (cropTopLeft != null && cropBottomRight != null) {
      editor!.updateCrop(cropTopLeft, cropBottomRight);
    }
    if (aspectRatio != null) {
      editor!.cropAspectRatio(aspectRatio);
    }

    if (direction != null) {
      // direction = base.RotateDirection.right;
      editor!.rotate90Degrees(direction);
    }
  }
}
