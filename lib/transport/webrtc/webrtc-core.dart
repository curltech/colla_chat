import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebrtcSignal {
  String signalType = '';
  bool? renegotiate; //是否需要重新协商
  Map<String, dynamic>? transceiverRequest; //收发器请求
  //ice candidate信息，ice服务器的地址
  dynamic candidate;
  // sdp信息，peer的信息
  String? sdp;
}

/// 简单包装webrtc的基本方法
class WebrtcCore {
  ///获取本机视频流
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

  ///获取本机屏幕流
  Future<MediaStream> getDisplayMedia(
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
    var stream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);

    return stream;
  }

  //获取本机的设备清单
  Future<List<MediaDeviceInfo>> enumerateDevices() async {
    var mediaDevicesList = await navigator.mediaDevices.enumerateDevices();

    return mediaDevicesList;
  }

  //获取媒体轨道支持的参数
  MediaTrackSupportedConstraints getSupportedConstraints() {
    var mediaTrackSupportedConstraints =
        navigator.mediaDevices.getSupportedConstraints();

    return mediaTrackSupportedConstraints;
  }

  //绑定视频流到渲染器
  RTCVideoRenderer bindRTCVideoRenderer(MediaStream stream) {
    final localRenderer = RTCVideoRenderer();
    localRenderer.initialize();
    localRenderer.srcObject = stream;

    return localRenderer;
  }
}
