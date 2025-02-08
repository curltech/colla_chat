import 'dart:async';
import 'dart:ui' as ui;

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as mobile_scanner;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrcodeUtil {
  ///qr.flutter创建二维码，适用于多个平台
  static QrImageView create(
    String data, {
    double size = 320,
    padding = const EdgeInsets.all(5.0),
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
      size: Size(80, 80),
    );

    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      gapless: false,
      padding: padding,
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
              size: Size.square(64),
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
  // static Future<String> scan(
  //     {List<BarcodeFormat> restrictFormat = const [],
  //     int useCamera = -1,
  //     AndroidOptions android = const AndroidOptions(),
  //     bool autoEnableFlash = false,
  //     Map<String, String> strings = const {
  //       'cancel': 'Cancel',
  //       'flash_on': 'Flash on',
  //       'flash_off': 'Flash off',
  //     }}) async {
  //   var options = ScanOptions(
  //     restrictFormat: restrictFormat,
  //     useCamera: useCamera,
  //     android: android,
  //     autoEnableFlash: autoEnableFlash,
  //     strings: strings,
  //   );
  //
  //   ScanResult result = await BarcodeScanner.scan(options: options);
  //
  //   return result.rawContent;
  // }

  static Future<String?> mobileScan(BuildContext context) async {
    String? result;
    mobile_scanner.MobileScannerController mobileScannerController =
        mobile_scanner.MobileScannerController(
      torchEnabled: true,
      formats: [BarcodeFormat.qrCode],
      facing: CameraFacing.front,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 1000,
      returnImage: false,
    );
    StreamSubscription<Object?>? subscription = mobileScannerController.barcodes
        .listen((mobile_scanner.BarcodeCapture capture) {
      final List<mobile_scanner.Barcode> barcodes = capture.barcodes;
      for (final barcode in barcodes) {
        result = barcode.rawValue;
        if (result != null) {
          break;
        }
      }
      Navigator.of(context).pop();
    });
    unawaited(mobileScannerController.start());
    ValueNotifier<bool> isStarted = ValueNotifier<bool>(true);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return Stack(children: [
            mobile_scanner.MobileScanner(
                fit: BoxFit.contain, controller: mobileScannerController),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                alignment: Alignment.bottomCenter,
                height: 100,
                color: Colors.black.withOpacity(0.4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                        onPressed: () {
                          unawaited(subscription.cancel());
                          Navigator.of(context).pop();
                          mobileScannerController.dispose();
                        },
                        icon: const Icon(Icons.arrow_back_ios_new)),
                    ValueListenableBuilder(
                      valueListenable: mobileScannerController,
                      builder: (context, state, child) {
                        if (!state.isInitialized || !state.isRunning) {
                          return const SizedBox.shrink();
                        }
                        return IconButton(
                          color: Colors.white,
                          icon: state.torchState == TorchState.off
                              ? const Icon(
                                  Icons.flash_off,
                                  color: Colors.grey,
                                )
                              : const Icon(
                                  Icons.flash_on,
                                  color: Colors.yellow,
                                ),
                          iconSize: 32.0,
                          onPressed: () =>
                              mobileScannerController.toggleTorch(),
                        );
                      },
                    ),
                    ValueListenableBuilder(
                        valueListenable: isStarted,
                        builder: (context, started, child) {
                          return IconButton(
                            color: Colors.white,
                            icon: started
                                ? const Icon(Icons.stop)
                                : const Icon(Icons.play_arrow),
                            iconSize: 32.0,
                            onPressed: () {
                              if (started) {
                                mobileScannerController.stop();
                                isStarted.value = false;
                              } else {
                                mobileScannerController.start();
                                isStarted.value = true;
                              }
                            },
                          );
                        }),
                    const Center(),
                    IconButton(
                      color: Colors.white,
                      icon: ValueListenableBuilder(
                        valueListenable: mobileScannerController,
                        builder: (context, state, child) {
                          if (!state.isInitialized || !state.isRunning) {
                            return const SizedBox.shrink();
                          }
                          switch (state.cameraDirection) {
                            case CameraFacing.front:
                              return const Icon(Icons.camera_front);
                            case CameraFacing.back:
                              return const Icon(Icons.camera_rear);
                          }
                        },
                      ),
                      iconSize: 32.0,
                      onPressed: () => mobileScannerController.switchCamera(),
                    ),
                  ],
                ),
              ),
            ),
          ]);
        },
      ),
    );

    return result;
  }
}
