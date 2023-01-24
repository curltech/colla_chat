import 'dart:io' as io;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/transport/httpclient.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_luban/flutter_luban.dart';
import 'package:image/image.dart' as platform_image;
import 'package:image_cropping/image_cropping.dart';
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

  static String prefixBase64 = 'data:image/*;base64,';

  static String base64Img(String img, {MimeType? type}) {
    if (type != null) {
      return prefixBase64.replaceFirst('*', type.name) + img;
    } else {
      return prefixBase64 + img;
    }
  }

  static Uint8List decodeBase64Img(String img) {
    int pos = img.indexOf(',');
    Uint8List bytes = CryptoUtil.decodeBase64(img.substring(pos + 1));

    return bytes;
  }

  static Widget buildImageWidget(
      {String? image,
      double? width,
      double? height,
      BoxFit? fit = BoxFit.contain,
      bool isRadius = true,
      double radius = 8.0}) {
    Widget imageWidget = AppImage.mdAppImage;
    if (image == null) {
      return imageWidget;
    }
    if (ImageUtil.isBase64Img(image)) {
      Uint8List bytes = ImageUtil.decodeBase64Img(image);
      imageWidget = Image.memory(bytes, width: width, height: height, fit: fit);
    } else if (ImageUtil.isAssetsImg(image)) {
      imageWidget = Image.asset(
        image,
        key: UniqueKey(),
        width: width,
        height: height,
        fit: fit,
      );
    } else if (File(image).existsSync()) {
      imageWidget = Image.file(
        File(image),
        key: UniqueKey(),
        width: width,
        height: height,
        fit: fit,
      );
    } else if (ImageUtil.isNetWorkImg(image)) {
      imageWidget = CachedNetworkImage(
        imageUrl: image,
        key: UniqueKey(),
        width: width,
        height: height,
        fit: fit,
        cacheManager: defaultCacheManager,
      );
    }
    if (isRadius) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.all(
          Radius.circular(radius),
        ),
        child: imageWidget,
      );
    }
    return imageWidget;
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
        cropRectPadding: const EdgeInsets.all(20.0),
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

  static compress({
    required String filename,
    String? path,
    CompressMode mode = CompressMode.AUTO,
    int quality = 80,
    int step = 6,
    bool autoRatio = true,
  }) async {
    File? imageFile = File(filename);
    CompressObject compressObject = CompressObject(
        imageFile: imageFile,
        //image
        path: path,
        //compress to path
        quality: quality,
        //first compress quality, default 80
        step: step,
        //compress quality step, The bigger the fast, Smaller is more accurate, default 6
        mode: CompressMode.LARGE2SMALL,
        autoRatio: autoRatio //default AUTO
        );
    var name = await Luban.compressImage(compressObject);

    return name;
  }

  static Future<dynamic> cropImage({
    required BuildContext context,
    required Uint8List imageBytes,
    required dynamic Function(dynamic) onImageDoneListener,
    void Function()? onImageStartLoading,
    void Function()? onImageEndLoading,
    CropAspectRatio? selectedImageRatio,
    bool visibleOtherAspectRatios = true,
    double squareBorderWidth = 2,
    List<CropAspectRatio>? customAspectRatios,
    Color squareCircleColor = Colors.orange,
    double squareCircleSize = 30,
    Color defaultTextColor = Colors.black,
    Color selectedTextColor = Colors.orange,
    Color colorForWhiteSpace = Colors.white,
    int encodingQuality = 100,
    String? workerPath,
    bool isConstrain = true,
    bool makeDarkerOutside = true,
    EdgeInsets? imageEdgeInsets = const EdgeInsets.all(10),
    bool rootNavigator = false,
    OutputImageFormat outputImageFormat = OutputImageFormat.jpg,
    Key? key,
  }) async {
    final croppedBytes = await ImageCropping.cropImage(
      context: context,
      imageBytes: imageBytes,
      onImageStartLoading: onImageStartLoading,
      onImageEndLoading: onImageEndLoading,
      onImageDoneListener: onImageDoneListener,
      selectedImageRatio: CropAspectRatio.fromRation(ImageRatio.RATIO_1_1),
      visibleOtherAspectRatios: true,
      squareBorderWidth: 2,
      squareCircleColor: Colors.black,
      defaultTextColor: Colors.orange,
      selectedTextColor: Colors.black,
      colorForWhiteSpace: Colors.grey,
      encodingQuality: 80,
      outputImageFormat: OutputImageFormat.jpg,
      workerPath: 'crop_worker.js',
    );

    return croppedBytes;
  }
}
