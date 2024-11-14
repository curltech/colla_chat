import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/tool/image_util.dart';

class ImageRecorder {
  late final ui.PictureRecorder recorder;
  late final ui.Canvas recorderCanvas;

  ImageRecorder() {
    recorder = ui.PictureRecorder();
    recorderCanvas = ui.Canvas(recorder);
  }

  ui.Image toImage(int width, int height) {
    ui.Picture picture = recorder.endRecording();
    ui.Image image = picture.toImageSync(width, height);

    return image;
  }

  Future<String?> toBase64Image(int width, int height) async {
    ui.Image image = toImage(width, height);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      String data = CryptoUtil.encodeBase64(byteData.buffer.asUint8List());
      data = ImageUtil.base64Img(data);

      return data;
    }

    return null;
  }
}
