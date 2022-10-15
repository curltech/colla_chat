import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as platform_image;
import 'package:image_gallery_saver/image_gallery_saver.dart';

///image_gallery_saver,extended_image
class ImageUtil {
  /// 判断是否网络
  static bool isNetWorkImg(String img) {
    return img.startsWith('http') || img.startsWith('https');
  }

  /// 判断是否资源图片
  static bool isAssetsImg(String img) {
    return img.startsWith('asset') || img.startsWith('assets');
  }

  /// 判断是否Base64图片
  static bool isBase64Img(String img) {
    return img.startsWith('data:image/') && img.contains(';base64,');
  }

  static Future<Uint8List> clipImageBytes(GlobalKey globalKey,
      {ui.ImageByteFormat format = ui.ImageByteFormat.png}) async {
    RenderRepaintBoundary? boundary =
        globalKey.currentContext?.findRenderObject()! as RenderRepaintBoundary;

    ui.Image uiImage = await boundary.toImage();
    ByteData? byteData = await uiImage.toByteData(format: format);
    Uint8List bytes = byteData!.buffer.asUint8List();

    return bytes;
  }

  static Future<bool> saveImageGallery(Uint8List bytes, String name) async {
    final result = await ImageGallerySaver.saveImage(bytes,
        quality: 100, name: name + DateTime.now().toString());
    if (result['isSuccess'].toString() == 'true') {
      return true;
    } else {
      return false;
    }
  }

  ///以下时extendedImage的功能
  buildGestureConfig({
    double minScale = 0.8,
    double maxScale = 5.0,
    double speed = 1.0,
    bool cacheGesture = false,
    double inertialSpeed = 100.0,
    double initialScale = 1.0,
    bool inPageView = false,
    double? animationMinScale,
    double? animationMaxScale,
    InitialAlignment initialAlignment = InitialAlignment.center,
    void Function(GestureDetails?)? gestureDetailsIsChanged,
    HitTestBehavior hitTestBehavior = HitTestBehavior.deferToChild,
    bool reverseMousePointerScrollDirection = false,
  }) {
    return GestureConfig(
      minScale: 0.9,
      animationMinScale: 0.7,
      maxScale: 3.0,
      animationMaxScale: 3.5,
      speed: 1.0,
      inertialSpeed: 100.0,
      initialScale: 1.0,
      inPageView: false,
      initialAlignment: InitialAlignment.center,
    );
  }

  buildEditorConfig({
    double maxScale = 5.0,
    EdgeInsets cropRectPadding = const EdgeInsets.all(20.0),
    Size cornerSize = const Size(30.0, 5.0),
    Color? cornerColor,
    Color? lineColor,
    double lineHeight = 0.6,
    Color Function(BuildContext, bool)? editorMaskColorHandler,
    double hitTestSize = 20.0,
    Duration animationDuration = const Duration(milliseconds: 200),
    Duration tickerDuration = const Duration(milliseconds: 400),
    double? cropAspectRatio = CropAspectRatios.custom,
    double? initialCropAspectRatio = CropAspectRatios.custom,
    InitCropRectType initCropRectType = InitCropRectType.imageRect,
    EditorCropLayerPainter cropLayerPainter = const EditorCropLayerPainter(),
    double speed = 1.0,
    HitTestBehavior hitTestBehavior = HitTestBehavior.deferToChild,
    void Function(EditActionDetails?)? editActionDetailsIsChanged,
    bool reverseMousePointerScrollDirection = false,
  }) {
    return EditorConfig(
        maxScale: 8.0,
        cropRectPadding: EdgeInsets.all(20.0),
        hitTestSize: 20.0,
        cropAspectRatio: 1);
  }

  static platform_image.Image? read(String filename) {
    var imageBytes = io.File(filename).readAsBytesSync();
    platform_image.Image? image = platform_image.decodeImage(imageBytes);

    return image;
  }

  static platform_image.Image thumbnail(
    platform_image.Image image, {
    int? width,
    int? height,
  }) {
    platform_image.Image thumbnail =
        platform_image.copyResize(image, width: width, height: height);
    platform_image.encodePng(thumbnail);

    return thumbnail;
  }

  static List<int> encodePng(platform_image.Image image, {int level = 6}) {
    return platform_image.encodePng(image, level: level);
  }

  static List<int> encodeJpg(platform_image.Image image, {int quality = 100}) {
    return platform_image.encodeJpg(image, quality: quality);
  }

  static platform_image.Image? decodeImage(List<int> data) {
    return platform_image.decodeImage(data);
  }
}
