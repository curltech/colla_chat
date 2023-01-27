import 'dart:async';
import 'dart:ui' as ui;

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrcodeUtil {
  ///qr.flutter创建二维码，适用于多个平台
  static QrImageView create(
    String data, {
    double size = 320,
    String? embed,
    ImageProvider<Object>? embeddedImage,
    QrEmbeddedImageStyle? embeddedImageStyle,
  }) {
    Uint8List? bytes;
    if (embeddedImage == null &&
        (embed != null && ImageUtil.isBase64Img(embed))) {
      int pos = embed.indexOf(',');
      bytes = CryptoUtil.decodeBase64(embed.substring(pos));
      embeddedImage = MemoryImage(bytes);
    }
    embeddedImageStyle ??= QrEmbeddedImageStyle(
      size: const Size(80, 80),
    );

    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      gapless: false,
      embeddedImage: embeddedImage,
      embeddedImageStyle: embeddedImageStyle,
    );
  }

  static Future<ui.Image> _loadEmbedImage(String? embed) async {
    Uint8List? bytes;
    if (embed != null && ImageUtil.isBase64Img(embed)) {
      int pos = embed.indexOf(',');
      bytes = CryptoUtil.decodeBase64(embed.substring(pos));
    }
    if (bytes == null) {
      final byteData = await rootBundle.load(AppImageFile.defaultAvatarFile);
      bytes = byteData.buffer.asUint8List();
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  static FutureBuilder<ui.Image> qrImageWidget(String data,
      {double width = 300, double height = 300, String? embed}) {
    final qrFutureBuilder = FutureBuilder<ui.Image>(
      future: _loadEmbedImage(embed),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(width: width, height: height);
        }
        return CustomPaint(
          size: Size.square(width),
          painter: QrPainter(
            data: data,
            version: QrVersions.auto,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xff128760),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.circle,
              color: Color(0xff1a5441),
            ),
            // size: 320.0,
            embeddedImage: snapshot.data,
            embeddedImageStyle: QrEmbeddedImageStyle(
              size: const Size.square(64),
            ),
          ),
        );
      },
    );

    return qrFutureBuilder;
  }

  // static Widget barcodeWidget(String data,
  //     {double width = 300, double height = 300, String? embed}) {
  //   Uint8List? bytes;
  //   if (embed != null && ImageUtil.isBase64Img(embed)) {
  //     int pos = embed.indexOf(',');
  //     bytes = CryptoUtil.decodeBase64(embed.substring(pos));
  //   }
  //   Widget imageWidget = defaultImage;
  //   if (bytes != null) {
  //     imageWidget = Image.memory(bytes, fit: BoxFit.contain);
  //   }
  //
  //   Widget widget = Stack(
  //     alignment: Alignment.center,
  //     children: [
  //       BarcodeWidget(
  //         barcode: Barcode.qrCode(),
  //         data: data,
  //         width: width,
  //         height: height,
  //       ),
  //       Container(
  //         color: Colors.white,
  //         width: 60,
  //         height: 60,
  //         child: imageWidget,
  //       ),
  //     ],
  //   );
  //
  //   return widget;
  // }

  ///使用barcode_scan2扫描二维码的功能，仅支持移动设备
  static Future<ScanResult> scan(
      {List<BarcodeFormat> restrictFormat = const [],
      int useCamera = -1,
      AndroidOptions android = const AndroidOptions(),
      bool autoEnableFlash = false,
      Map<String, String> strings = const {
        'cancel': 'Cancel',
        'flash_on': 'Flash on',
        'flash_off': 'Flash off',
      }}) async {
    var options = ScanOptions(
      restrictFormat: restrictFormat,
      useCamera: useCamera,
      android: android,
      autoEnableFlash: autoEnableFlash,
      strings: strings,
    );

    ScanResult result = await BarcodeScanner.scan(options: options);

    return result;
  }

  ///macos有问题
// static Future<String?> mobileScan() async {
//   mobile_scanner.MobileScannerController cameraController =
//       mobile_scanner.MobileScannerController();
//   Future<String?> result = Future(() {
//     mobile_scanner.MobileScanner(
//         allowDuplicates: false,
//         controller: cameraController,
//         onDetect: (barcode, args) {
//           return barcode.rawValue;
//         });
//   });
//
//   return result;
// }
}
