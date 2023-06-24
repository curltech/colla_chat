import 'dart:io' as io;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/asset_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/path_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_luban/flutter_luban.dart';
import 'package:image/image.dart' as platform_image;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

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

  static String base64Img(String img, {ChatMessageMimeType? type}) {
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

  static Widget buildMemoryImageWidget(Uint8List image,
      {double? width,
      double? height,
      BoxFit? fit = BoxFit.contain,
      bool isRadius = false,
      double radius = 8.0}) {
    Widget imageWidget =
        Image.memory(image, width: width, height: height, fit: fit);
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

  static Future<Uint8List> loadUrlImage(String url) async {
    final Dio dio = Dio();
    Response response = await dio.get(
      url,
      //Received data with List<int>
      options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          }),
    );
    Uint8List raw = response.data;

    return raw;
    var buffer = raw.buffer;
    ByteData byteData = ByteData.view(buffer);
  }

  static Widget buildImageWidget(
      {String? image,
      double? width,
      double? height,
      BoxFit? fit = BoxFit.contain,
      bool isRadius = false,
      double radius = 8.0}) {
    Widget imageWidget = Image.asset(
      key: UniqueKey(),
      AppImageFile.mdAppIconFile,
      width: width,
      height: height,
      fit: fit,
    );
    if (image == null) {
    } else if (ImageUtil.isBase64Img(image)) {
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
    } else if (ImageUtil.isNetWorkImg(image)) {
      imageWidget = Image.network(
        image,
        key: UniqueKey(),
        width: width,
        height: height,
        fit: fit,
      );
    } else {
      File file = File(image);
      bool exist = file.existsSync();
      if (exist) {
        imageWidget = Image.file(
          file,
          key: UniqueKey(),
          width: width,
          height: height,
          fit: fit,
        );
      }
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

  static platform_image.Image? decodeImage(Uint8List data) {
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

  /// compress file and get Uint8List
  static Future<Uint8List?> compressWithFile(
    File file, {
    int minWidth = 1920,
    int minHeight = 1080,
    int inSampleSize = 1,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) async {
    var result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: minWidth,
      minHeight: minHeight,
      inSampleSize: inSampleSize,
      quality: quality,
      rotate: rotate,
      autoCorrectionAngle: autoCorrectionAngle,
      format: format,
      keepExif: keepExif,
      numberOfRetries: numberOfRetries,
    );

    return result;
  }

  /// compress file and get file.
  static Future<File?> compressAndGetFile(
    File file,
    String targetPath, {
    int minWidth = 1920,
    int minHeight = 1080,
    int inSampleSize = 1,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) async {
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minWidth: minWidth,
      minHeight: minHeight,
      inSampleSize: inSampleSize,
      quality: quality,
      rotate: rotate,
      autoCorrectionAngle: autoCorrectionAngle,
      format: format,
      keepExif: keepExif,
      numberOfRetries: numberOfRetries,
    );

    return result;
  }

  /// compress asset and get Uint8List.
  static Future<Uint8List?> compressAssetImage(
    String assetName, {
    int minWidth = 1920,
    int minHeight = 1080,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
  }) async {
    var list = await FlutterImageCompress.compressAssetImage(
      assetName,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
      rotate: rotate,
      autoCorrectionAngle: autoCorrectionAngle,
      format: format,
      keepExif: keepExif,
    );

    return list;
  }

  /// compress Uint8List and get another Uint8List.
  static Future<Uint8List> compressWithList(
    Uint8List list, {
    int minWidth = 1920,
    int minHeight = 1080,
    int quality = 95,
    int rotate = 0,
    int inSampleSize = 1,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
  }) async {
    var result = await FlutterImageCompress.compressWithList(
      list,
      minWidth: minWidth,
      minHeight: minHeight,
      inSampleSize: inSampleSize,
      quality: quality,
      rotate: rotate,
      autoCorrectionAngle: autoCorrectionAngle,
      format: format,
      keepExif: keepExif,
    );
    return result;
  }

  static Future<Uint8List?> compressThumbnail(
      {XFile? xfile,
      AssetEntity? assetEntity,
      Uint8List? image,
      String extension = 'jpeg'}) async {
    Uint8List? avatar;
    Directory dir = await PathUtil.getTemporaryDirectory();
    if (image != null) {
      var path = await FileUtil.writeTempFile(image, extension: extension);
      xfile = XFile(path!);
    }
    if (xfile != null) {
      int length = await xfile.length();
      if (length > 10240) {
        double quality = 10240 * 100 / length;
        String? filename = await compress(
            filename: xfile.path, path: dir.path, quality: quality.toInt());
        avatar = await FileUtil.readFile(filename!);
      } else {
        avatar = await xfile.readAsBytes();
      }
      return avatar;
    } else if (assetEntity != null) {
      String? mimeType = await assetEntity.mimeTypeAsync;
      Uint8List? avatar = await assetEntity.originBytes;
      if (avatar != null && avatar.length > 10240) {
        double quality = 10240 * 100 / avatar.length;
        mimeType = FileUtil.subMimeType(mimeType!);
        mimeType = mimeType ?? 'jpeg';
        CompressFormat? format =
            StringUtil.enumFromString(CompressFormat.values, mimeType);
        format = format ?? CompressFormat.jpeg;
        avatar = await compressWithList(avatar,
            quality: quality.toInt(), format: format);

        return avatar;
      }
    }

    return avatar;
  }

  ///所有平台，选择图像或者媒体，对桌面平台，也可选择文件
  static Future<List<dynamic>> pickImage({
    BuildContext? context,
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.image,
    List<String>? allowedExtensions,
    dynamic Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    AssetPickerConfig pickerConfig = const AssetPickerConfig(),
  }) async {
    if (platformParams.desktop) {
      List<XFile> xfiles = await FileUtil.pickFiles(
          dialogTitle: dialogTitle,
          initialDirectory: initialDirectory,
          allowedExtensions: allowedExtensions,
          allowCompression: allowCompression,
          allowMultiple: allowMultiple,
          withData: withData,
          withReadStream: withReadStream,
          lockParentWindow: lockParentWindow,
          type: FileType.image);
      return xfiles;
    } else if (platformParams.mobile && context != null) {
      List<AssetEntity>? assets =
          await AssetUtil.pickAssets(context, pickerConfig: pickerConfig);
      assets = assets ?? [];

      return assets;
    }

    return [];
  }

  ///所有平台，选择图像，并进行压缩，用于头像
  static Future<Uint8List?> pickAvatar(
    BuildContext? context,
  ) async {
    Uint8List? avatar;
    if (platformParams.desktop) {
      List<XFile> xfiles = await FileUtil.pickFiles(type: FileType.image);
      if (xfiles.isNotEmpty) {
        avatar = await compressThumbnail(xfile: xfiles[0]);
      }
    } else if (platformParams.mobile && context != null) {
      List<AssetEntity>? assets = await AssetUtil.pickAssets(context);
      if (assets != null && assets.isNotEmpty) {
        avatar = await compressThumbnail(assetEntity: assets[0]);
      }
    }

    return avatar;
  }
}
