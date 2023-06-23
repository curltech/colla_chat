import 'package:image_picker/image_picker.dart';

///所有平台，选取图库,移动从图像廊或者相机选，桌面实现采用file_selector，从文件系统选
class MediaUtil {
  static ImagePicker picker = ImagePicker();

  /// Pick an image.
  static Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    final XFile? image = await picker.pickImage(
        source: source,
        maxHeight: maxHeight,
        maxWidth: maxWidth,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
        requestFullMetadata: requestFullMetadata);
    return image;
  }

  /// Pick a video.
  static Future<XFile?> pickVideo({
    ImageSource source = ImageSource.gallery,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async {
    final XFile? video = await picker.pickVideo(
        source: source,
        preferredCameraDevice: preferredCameraDevice,
        maxDuration: maxDuration);

    return video;
  }

  /// Pick multiple images.
  static Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    bool requestFullMetadata = true,
  }) async {
    final List<XFile> images = await picker.pickMultiImage(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        requestFullMetadata: requestFullMetadata);

    return images;
  }

  /// Pick singe image or video.
  static Future<XFile?> pickMedia({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    bool requestFullMetadata = true,
  }) async {
    final XFile? media = await picker.pickMedia(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        requestFullMetadata: requestFullMetadata);

    return media;
  }

  /// Pick multiple images and videos.
  static Future<List<XFile>> pickMultipleMedia({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    bool requestFullMetadata = true,
  }) async {
    final List<XFile> medias = await picker.pickMultipleMedia(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        requestFullMetadata: requestFullMetadata);

    return medias;
  }
}
