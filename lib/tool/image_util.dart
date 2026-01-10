import 'dart:io' as io;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/asset_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/path_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_luban/flutter_luban.dart';
import 'package:image/image.dart' as img;
import 'package:saver_gallery/saver_gallery.dart';
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
    bool base64 = isBase64Img(img);
    if (base64) {
      return img;
    }
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
  }

  static Future<String?> toBase64String(ui.Image image) async {
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      String data = CryptoUtil.encodeBase64(byteData.buffer.asUint8List());
      data = ImageUtil.base64Img(data);

      return data;
    }

    return null;
  }

  static Image buildImage({
    String? imageContent,
    double? width,
    double? height,
    BoxFit? fit = BoxFit.contain,
  }) {
    Image image = Image.asset(
      key: UniqueKey(),
      AppImageFile.mdAppIconFile,
      width: width,
      height: height,
      fit: fit,
    );
    if (imageContent == null) {
      return image;
    }
    if (ImageUtil.isBase64Img(imageContent)) {
      Uint8List bytes = ImageUtil.decodeBase64Img(imageContent);
      image = Image.memory(bytes, width: width, height: height, fit: fit);
    } else if (ImageUtil.isAssetsImg(imageContent)) {
      image = Image.asset(
        imageContent,
        key: UniqueKey(),
        width: width,
        height: height,
        fit: fit,
      );
    } else if (ImageUtil.isNetWorkImg(imageContent)) {
      image = Image.network(
        imageContent,
        key: UniqueKey(),
        width: width,
        height: height,
        fit: fit,
      );
    } else {
      File file = File(imageContent);
      bool exist = file.existsSync();
      if (exist) {
        image = Image.file(
          file,
          key: UniqueKey(),
          width: width,
          height: height,
          fit: fit,
        );
      }
    }
    return image;
  }

  static Widget buildImageWidget(
      {String? imageContent,
      double? width,
      double? height,
      BoxFit? fit = BoxFit.contain,
      bool isRadius = false,
      double radius = 8.0}) {
    Widget imageWidget = buildImage(
        imageContent: imageContent, width: width, height: height, fit: fit);
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

  /// 捕获的Widget必须用RepaintBoundary包裹，且设置GlobalKey
  static Future<ui.Image> capturePng(GlobalKey key,
      {double pixelRatio = 1.0}) async {
    RenderRepaintBoundary boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

    return image;
  }

  ///保存图片到图片廊
  static Future<dynamic> saveImageGallery(
    Uint8List imageBytes, {
    int quality = 100,
    String? fileExtension,
    required String fileName,
    String androidRelativePath = "Pictures",
    required bool skipIfExists,
  }) async {
    final result = await SaverGallery.saveImage(imageBytes,
        quality: quality,
        fileName: fileName,
        androidRelativePath: androidRelativePath,
        skipIfExists: skipIfExists);
    return result;
  }

  ///保存其他数据到图片廊，数据在文件中
  static Future<dynamic> saveFileGallery({
    required String filePath,
    required String fileName,
    String androidRelativePath = "Download",
    required bool skipIfExists,
  }) async {
    final result = await SaverGallery.saveFile(
        filePath: filePath,
        fileName: fileName,
        androidRelativePath: androidRelativePath,
        skipIfExists: skipIfExists);
    return result;
  }

  ///以下时extendedImage的功能
  GestureConfig buildGestureConfig({
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

  EditorConfig buildEditorConfig({
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

  static img.Image? read(String filename) {
    var imageBytes = io.File(filename).readAsBytesSync();
    img.Image? image = img.decodeImage(imageBytes);

    return image;
  }

  static img.Image thumbnail(
    img.Image image, {
    int? width,
    int? height,
  }) {
    img.Image thumbnail = img.copyResize(image, width: width, height: height);
    img.encodePng(thumbnail);

    return thumbnail;
  }

  static List<int> encodePng(img.Image image, {int level = 6}) {
    return img.encodePng(image, level: level);
  }

  static List<int> encodeJpg(img.Image image, {int quality = 100}) {
    return img.encodeJpg(image, quality: quality);
  }

  static img.Image? decodeImage(Uint8List data) {
    return img.decodeImage(data);
  }

  ///压缩图片，适用于多个平台
  static Future<String?>? compress({
    required String filename,
    required String path,
    CompressMode mode = CompressMode.LARGE2SMALL,
    int quality = 80,
    int step = 1,
    bool autoRatio = true,
  }) async {
    File? imageFile = File(filename);
    CompressObject compressObject = CompressObject(
        imageFile: imageFile,
        //image
        targetPath: path,
        //compress to path
        quality: quality,
        //first compress quality, default 80
        step: step,
        //compress quality step, The bigger the fast, Smaller is more accurate, default 6
        mode: mode,
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
  static Future<XFile?> compressAndGetFile(
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

  /// 压缩图片，移动平台，compress Uint8List and get another Uint8List.
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
    Directory? dir = await PathUtil.getTemporaryDirectory();
    if (dir == null) {
      return null;
    }
    if (image != null) {
      var path =
          await FileUtil.writeTempFileAsBytes(image, extension: extension);
      xfile = XFile(path!);
    }
    if (xfile != null) {
      int length = await xfile.length();
      if (length > 10240) {
        // double quality = 10240 * 100 / length;
        String? filename = await compress(filename: xfile.path, path: dir.path);
        avatar = await FileUtil.readFileAsBytes(filename!);
      } else {
        avatar = await xfile.readAsBytes();
      }
      return avatar;
    } else if (assetEntity != null) {
      String? mimeType = await assetEntity.mimeTypeAsync;
      Uint8List? avatar = await assetEntity.originBytes;
      if (avatar != null && avatar.length > 10240) {
        // double quality = 10240 * 100 / avatar.length;
        mimeType = FileUtil.subMimeType(mimeType!);
        mimeType = mimeType ?? 'jpeg';
        CompressFormat? format =
            StringUtil.enumFromString(CompressFormat.values, mimeType);
        format = format ?? CompressFormat.jpeg;
        avatar = await compressWithList(avatar, format: format);

        return avatar;
      }
    }

    return avatar;
  }

  ///所有平台，选择图像，并进行压缩，用于头像
  static Future<Uint8List?> pickAvatar({
    BuildContext? context,
  }) async {
    context = context ?? appDataProvider.context!;
    Uint8List? avatar;
    if (platformParams.desktop) {
      List<XFile>? xfiles = await FileUtil.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif']);
      if (xfiles!=null && xfiles.isNotEmpty) {
        avatar = await compressThumbnail(xfile: xfiles[0]);
      }
    } else if (platformParams.mobile) {
      List<AssetEntity>? assets = await AssetUtil.pickAssets(context: context);
      if (assets != null && assets.isNotEmpty) {
        avatar = await compressThumbnail(assetEntity: assets[0]);
      }
    }

    return avatar;
  }

  static Future<Uint8List?> convert(
      {Uint8List? indata,
      String? infile,
      String? format,
      int? width,
      String? outfile}) async {
    if (infile != null) {
      indata = File(infile).readAsBytesSync();
    }
    img.Image? image = img.decodeImage(indata!);
    if (image == null) {
      return null;
    }
    if (width != null) {
      image = img.copyResize(image, width: width);
    }
    if (outfile != null) {
      await img.encodeImageFile(outfile, image);
    } else if (format != null) {
      format = '.$format';
      return img.encodeNamedImage(format, image);
    }
    return null;
  }
}
