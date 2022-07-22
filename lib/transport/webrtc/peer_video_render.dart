import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';

import '../../platform.dart';
import '../../provider/app_data_provider.dart';

/// 简单包装webrtc的基本方法
class PeerVideoRenderer {
  String? id;
  MediaStream? mediaStream;
  RTCVideoRenderer? renderer;
  MediaRecorder? mediaRecorder;
  List<MediaDeviceInfo>? mediaDevicesList;

  PeerVideoRenderer({this.mediaStream});

  ///获取本机视频流
  Future<void> getUserMedia(
      {bool audio = true,
      int minWidth = 640,
      int minHeight = 480,
      int minFrameRate = 30}) async {
    Map<String, dynamic> mediaConstraints = <String, dynamic>{
      'audio': audio,
      'video': {
        'mandatory': {
          'minWidth': minWidth.toString(),
          'minHeight': minHeight.toString(),
          'minFrameRate': minFrameRate.toString(),
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
  }

  ///获取本机屏幕流
  Future<void> getDisplayMedia(
      {DesktopCapturerSource? selectedSource, bool audio = false}) async {
    dynamic video = selectedSource == null
        ? true
        : {
            'deviceId': {'exact': selectedSource!.id},
            'mandatory': {'frameRate': 30.0}
          };
    Map<String, dynamic> mediaConstraints = <String, dynamic>{
      'audio': audio,
      'video': video
    };
    var mediaStream =
        await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
    this.mediaStream = mediaStream;
  }

  //获取本机的设备清单
  Future<List<MediaDeviceInfo>?> enumerateDevices() async {
    mediaDevicesList ??= await navigator.mediaDevices.enumerateDevices();
    return mediaDevicesList;
  }

  //获取媒体轨道支持的参数
  MediaTrackSupportedConstraints getSupportedConstraints() {
    var mediaTrackSupportedConstraints =
        navigator.mediaDevices.getSupportedConstraints();

    return mediaTrackSupportedConstraints;
  }

  //绑定视频流到渲染器
  Future<void> bindRTCVideoRenderer() async {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      RTCVideoRenderer renderer = RTCVideoRenderer();
      await renderer.initialize();
      renderer.srcObject = mediaStream;
      this.renderer = renderer;
    }
  }

  dispose() async {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      await mediaStream.dispose();
      this.mediaStream = null;
    }
    var renderer = this.renderer;
    if (renderer != null) {
      renderer.srcObject = null;
      renderer.dispose();
      this.renderer = null;
    }
  }

  RTCVideoView? createView({
    RTCVideoViewObjectFit objectFit =
        RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    bool mirror = false,
    FilterQuality filterQuality = FilterQuality.low,
  }) {
    var renderer = this.renderer;
    if (renderer != null) {
      return RTCVideoView(renderer,
          objectFit: objectFit, mirror: mirror, filterQuality: filterQuality);
    }
    return null;
  }

  Future<ByteBuffer?> captureFrame() async {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      final videoTrack = mediaStream
          .getVideoTracks()
          .firstWhere((track) => track.kind == 'video');
      final frame = await videoTrack.captureFrame();
      return frame;
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

  void startRecording({String? filePath}) async {
    if (mediaStream == null) throw 'Stream is not initialized';
    if (PlatformParams.instance.ios) {
      logger.e('Recording is not available on iOS');
      return;
    }
    // TODO(rostopira): request write storage permission
    if (filePath == null) {
      Directory? storagePath = await getApplicationDocumentsDirectory();
      if (storagePath == null) throw 'Can\'t find storagePath';
      filePath = '${storagePath.path}/webrtc_sample/test.mp4';
    }
    mediaRecorder = MediaRecorder();
    final videoTrack = mediaStream!
        .getVideoTracks()
        .firstWhere((track) => track.kind == 'video');
    await mediaRecorder!.start(
      filePath,
      videoTrack: videoTrack,
    );
  }

  void stopRecording() async {
    if (mediaRecorder != null) {
      await mediaRecorder!.stop();
      mediaRecorder = null;
    }
  }
}
