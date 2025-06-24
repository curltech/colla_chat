import 'package:easy_video_editor/easy_video_editor.dart' as easy;

/// mobile device video editor
class EasyVideoEditor {
  final String videoInputPath;
  late final easy.VideoEditorBuilder editor =
      easy.VideoEditorBuilder(videoPath: videoInputPath);

  EasyVideoEditor(this.videoInputPath);

  edit(String outputVideoPath,
      {int? startTimeMs,
      int? endTimeMs,
      List<String>? mergeVideoPaths,
      double? speed,
      easy.VideoResolution? resolution,
      easy.VideoAspectRatio? aspectRatio,
      easy.RotationDegree? degree,
      easy.FlipDirection? flipDirection,
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

  Future<easy.VideoMetadata> getVideoMetadata() async {
    final metadata = await editor.getVideoMetadata();
    // print('Duration: ${metadata.duration} ms');
    // print('Dimensions: ${metadata.width}x${metadata.height}');
    // print('Orientation: ${metadata.rotation}°');
    // print('File size: ${metadata.fileSize} bytes');
    // print('Creation date: ${metadata.date}');

    return metadata;
  }

  Future<bool> cancel() async {
    return await easy.VideoEditorBuilder.cancel();
  }
}
