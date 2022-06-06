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
class WebrtcRenderer {
  MediaStream? mediaStream;
  RTCVideoRenderer? renderer;

  ///获取本机视频流
  Future<MediaStream> getUserMedia(
      Map<String, dynamic> mediaConstraints) async {
    mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth':
              '640', // Provide your own width, height and frame rate here
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [
          {'DtlsSrtpKeyAgreement': true}
        ],
      }
    };
    var mediaStream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);
    this.mediaStream = mediaStream;

    return mediaStream;
  }

  ///获取本机屏幕流
  Future<MediaStream> getDisplayMedia(
      Map<String, dynamic> mediaConstraints) async {
    mediaConstraints = <String, dynamic>{'audio': false, 'video': true};
    var mediaStream =
        await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
    this.mediaStream = mediaStream;

    return mediaStream;
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
    var renderer = RTCVideoRenderer();
    renderer.initialize();
    this.renderer = renderer;
    renderer.srcObject = stream;

    return renderer;
  }

  close() async {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      await mediaStream.dispose();
      this.mediaStream = null;
    }
    var renderer = this.renderer;
    if (renderer != null) {
      renderer.srcObject = null;
      this.renderer = null;
    }
  }

  RTCVideoView? createView() {
    var renderer = this.renderer;
    if (renderer != null) {
      return RTCVideoView(renderer);
    }
    return null;
  }

  Future<bool> switchCamera() async {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      var tracks = mediaStream.getVideoTracks();
      if (tracks.isNotEmpty) {
        return await Helper.switchCamera(tracks[0]);
      }
    }
    return false;
  }

  void switchSpeaker(bool enable) async {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      var tracks = mediaStream.getAudioTracks();
      if (tracks.isNotEmpty) {
        tracks[0].enableSpeakerphone(enable);
      }
    }
  }

  void setMute(bool mute) {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      var tracks = mediaStream.getAudioTracks();
      if (tracks.isNotEmpty) {
        Helper.setMicrophoneMute(mute, tracks[0]);
      }
    }
  }

  void turnCamera(bool mute) {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      var tracks = mediaStream.getVideoTracks();
      if (tracks.isNotEmpty) {
        tracks[0].enabled = mute;
      }
    }
  }

  void setVolume(double volume) {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      var tracks = mediaStream.getAudioTracks();
      if (tracks.isNotEmpty) {
        Helper.setVolume(volume, tracks[0]);
      }
    }
  }
}
