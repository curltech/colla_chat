import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCCore {
  Future<MediaStream> getUserMedia(
      Map<String, dynamic> mediaConstraints) async {
    mediaConstraints = <String, dynamic>{
      'audio': false,
      'video': {
        'mandatory': {
          'minWidth':
              '640', // Provide your own width, height and frame rate here
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };
    var stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    return stream;
  }

  Future<List<MediaDeviceInfo>> enumerateDevices() async {
    var mediaDevicesList = await navigator.mediaDevices.enumerateDevices();

    return mediaDevicesList;
  }

  bind(MediaStream stream) {
    final localRenderer = RTCVideoRenderer();
    localRenderer.srcObject = stream;
  }
}
