import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:colla_chat/plugin/logger.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';

import '../../platform.dart';

/// 简单包装webrtc视频流的渲染器，可以构造本地视频流或者传入的视频流
/// 视频流绑定渲染器，并创建展示视图
class PeerVideoRender {
  String? id;
  MediaStream? mediaStream;
  RTCVideoRenderer? renderer;
  MediaRecorder? mediaRecorder;
  List<MediaDeviceInfo>? mediaDevicesList;

  PeerVideoRender({this.mediaStream}) {
    if (mediaStream != null) {
      id = mediaStream!.id;
    }
  }

  static PeerVideoRender from(
      {MediaStream? stream,
      bool userMedia = false,
      bool displayMedia = false}) {
    PeerVideoRender render = PeerVideoRender();
    if (stream == null && !userMedia && !displayMedia) {
      userMedia = true;
    }
    if (userMedia) {
      render.createUserMedia();
    } else if (displayMedia) {
      render.createDisplayMedia();
    } else if (stream != null) {
      render.mediaStream = stream;
      render.id = stream.id;
    }

    return render;
  }

  ///获取本机视频流
  Future<void> createUserMedia(
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
    id = mediaStream.id;
  }

  ///获取本机屏幕流
  Future<void> createDisplayMedia(
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
    id = mediaStream.id;
  }

  ///获取本机音频流
  Future<void> createAudioMedia() async {
    Map<String, dynamic> mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': false,
    };
    var mediaStream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);
    this.mediaStream = mediaStream;
    id = mediaStream.id;
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
  Future<void> bindRTCVideoRender() async {
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

  /// 渲染器创建展示视图
  RTCVideoView? createVideoView({
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

  /// 捕获视频流的帧，就是快照
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

  /// 对视频流的第一个视频轨道切换摄像头，对手机来说，就是切换前置和后置摄像头
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

  /// 对视频流的第一个音频轨道切换音频播放设备，对手机来说就是耳机还是喇叭
  void switchSpeaker(bool enable) async {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      var tracks = mediaStream.getAudioTracks();
      if (tracks.isNotEmpty) {
        tracks[0].enableSpeakerphone(enable);
      }
    }
  }

  /// 对视频流的第一个音频轨道静音设置
  void setMute(bool mute) {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      var tracks = mediaStream.getAudioTracks();
      if (tracks.isNotEmpty) {
        Helper.setMicrophoneMute(mute, tracks[0]);
      }
    }
  }

  /// 打开或者关闭视频流的第一个视频轨道
  void turnTrack(bool mute) {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      var tracks = mediaStream.getVideoTracks();
      if (tracks.isNotEmpty) {
        tracks[0].enabled = mute;
      }
    }
  }

  /// 对视频流的第一个音频轨道设置音量
  void setVolume(double volume) {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      var tracks = mediaStream.getAudioTracks();
      if (tracks.isNotEmpty) {
        Helper.setVolume(volume, tracks[0]);
      }
    }
  }

  /// 开始记录视频流到文件
  void startRecording({String? filePath}) async {
    if (mediaStream == null) throw 'Stream is not initialized';
    if (PlatformParams.instance.ios) {
      logger.e('Recording is not available on iOS');
      return;
    }
    // TODO(rostopira): request write storage permission
    if (filePath == null) {
      Directory? storagePath = await getApplicationDocumentsDirectory();
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

  /// 停止视频流的记录
  void stopRecording() async {
    if (mediaRecorder != null) {
      await mediaRecorder!.stop();
      mediaRecorder = null;
    }
  }
}
