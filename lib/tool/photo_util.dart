import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

///photo_view,photo_view_gallery
class PhotoUtil {
  static requestPermissionExtend() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      // Granted.
    } else {
      // Limited(iOS) or Rejected, use `==` for more precise judgements.
      // You can call `PhotoManager.openSetting()` to open settings for further steps.
      PhotoManager.openSetting();
    }
  }

  buildPhotoView({
    Key? key,
    required ImageProvider<Object>? imageProvider,
    Widget Function(BuildContext, ImageChunkEvent?)? loadingBuilder,
    BoxDecoration? backgroundDecoration,
    bool wantKeepAlive = false,
    bool gaplessPlayback = false,
    PhotoViewHeroAttributes? heroAttributes,
    void Function(PhotoViewScaleState)? scaleStateChangedCallback,
    bool enableRotation = false,
    PhotoViewControllerBase<PhotoViewControllerValue>? controller,
    PhotoViewScaleStateController? scaleStateController,
    dynamic maxScale,
    dynamic minScale,
    dynamic initialScale,
    Alignment? basePosition,
    PhotoViewScaleState Function(PhotoViewScaleState)? scaleStateCycle,
    dynamic Function(BuildContext, TapUpDetails, PhotoViewControllerValue)?
        onTapUp,
    dynamic Function(BuildContext, TapDownDetails, PhotoViewControllerValue)?
        onTapDown,
    dynamic Function(BuildContext, ScaleEndDetails, PhotoViewControllerValue)?
        onScaleEnd,
    Size? customSize,
    HitTestBehavior? gestureDetectorBehavior,
    bool? tightMode,
    FilterQuality? filterQuality,
    bool? disableGestures,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
    bool? enablePanAlways,
  }) {
    return PhotoView(
      imageProvider: null,
    );
  }

  buildPhotoViewGallery(List<String> assetNames) {
    return PhotoViewGallery.builder(
      itemCount: null,
      builder: (BuildContext context, int index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: AssetImage(assetNames[index]),
          initialScale: PhotoViewComputedScale.contained * 0.8,
          heroAttributes: const PhotoViewHeroAttributes(tag: ''),
        );
      },
    );
  }

  static Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    final ImagePicker picker = ImagePicker();
    // Pick an image
    final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice);

    return image;
  }

  static Future<XFile?> pickVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async {
    final ImagePicker picker = ImagePicker();
    // Pick a video
    final XFile? video = await picker.pickVideo(
        source: source,
        preferredCameraDevice: preferredCameraDevice,
        maxDuration: maxDuration);

    return video;
  }

  static Future<List<XFile>?> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final ImagePicker picker = ImagePicker();
    // Pick multiple images
    final List<XFile>? images = await picker.pickMultiImage(
        maxWidth: maxWidth, maxHeight: maxHeight, imageQuality: imageQuality);

    return images;
  }
}
