import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/path_util.dart';
import 'package:colla_chat/transport/webrtc/screen_select_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

final emptyVideoView = Center(
  child: AppImage.mdAppImage,
);

enum VideoRenderOperator {
  create,
  add,
  remove,
  unselected,
  selected,
  exit,
  mute,
  volume,
  torch
}

/// 简单包装webrtc视频流的渲染器，可以构造本地视频流或者传入的视频流
/// 视频流绑定渲染器，并创建展示视图
class PeerVideoRender {
  String? id;
  MediaStream? mediaStream;
  RTCVideoRenderer? renderer;
  MediaRecorder? mediaRecorder;
  List<MediaDeviceInfo>? mediaDevicesList;

  //业务相关的数据
  String? peerId;
  String? name;
  String? clientId;

  bool audio = false;
  bool video = false;

  PeerVideoRender({this.mediaStream}) {
    if (mediaStream != null) {
      id = mediaStream!.id;
    }
  }

  setStream(MediaStream? mediaStream) async {
    await close();
    if (mediaStream != null) {
      this.mediaStream = mediaStream;
      id = mediaStream.id;
    } else {
      this.mediaStream = null;
      id = null;
    }
  }

  static Future<PeerVideoRender> fromVideoMedia(
    String peerId, {
    String? clientId,
    String? name,
    bool audio = true,
    double width = 640,
    double height = 480,
    int frameRate = 30,
  }) async {
    PeerVideoRender render = PeerVideoRender();
    render.peerId = peerId;
    render.clientId = clientId;
    render.name = name;
    await render.createVideoMedia(
      audio: audio,
      width: width,
      height: height,
      frameRate: frameRate,
    );
    await render.bindRTCVideoRender();

    return render;
  }

  static Future<PeerVideoRender> fromAudioMedia(
    String peerId, {
    String? clientId,
    String? name,
  }) async {
    PeerVideoRender render = PeerVideoRender();
    render.peerId = peerId;
    render.clientId = clientId;
    render.name = name;
    await render.createAudioMedia();
    await render.bindRTCVideoRender();

    return render;
  }

  static Future<PeerVideoRender> fromDisplayMedia(
    String peerId, {
    String? clientId,
    String? name,
    DesktopCapturerSource? selectedSource,
    bool audio = false,
  }) async {
    PeerVideoRender render = PeerVideoRender();
    render.peerId = peerId;
    render.clientId = clientId;
    render.name = name;
    await render.createDisplayMedia(
      selectedSource: selectedSource,
      audio: audio,
    );
    await render.bindRTCVideoRender();

    return render;
  }

  static Future<PeerVideoRender> fromMediaStream(
    String peerId, {
    required MediaStream stream,
    String? clientId,
    String? name,
  }) async {
    PeerVideoRender render = PeerVideoRender();
    render.peerId = peerId;
    render.clientId = clientId;
    render.name = name;
    render.mediaStream = stream;
    render.id = stream.id;
    await render.bindRTCVideoRender();

    return render;
  }

  Map<String, dynamic> _getDefaultConstraints({
    required double width,
    required double height,
    bool audio = true,
    int frameRate = 30,
    int minWidth = 640,
    int minHeight = 360,
    int minFrameRate = 15,
    double aspectRatio = 9 / 16,
  }) {
    return {
      "audio": audio
          ? {
              "volume": 1, // 音量 0-1
              "sampleRate": {"exact": 48000}, // 采样率
              "sampleSize": {"exact": 16}, // 采样位数
              "channelCount": {"exact": 1}, // 声道
              "echoCancellation": true, // 回音消除
              "autoGainControl": true, // 自动增益
              "noiseSuppression": true // 降噪
            }
          : false,
      "video": {
        "focusMode": 'continuous', // 持续对焦
        "facingMode": 'user', // 前摄
        "resizeMode": 'crop-and-scale', // 'none'或'crop-and-scale'
        "frameRate": {"ideal": frameRate, 'min': minFrameRate}, // 帧率
        "aspectRatio": aspectRatio,
        "width": {"ideal": width, "min": minWidth},
        "height": {"ideal": height, "min": minHeight},
        'mandatory': {
          'minWidth': minWidth,
          'minHeight': minHeight,
          'minFrameRate': minFrameRate,
        },
        'optional': [
          {'DtlsSrtpKeyAgreement': true}
        ],
      },
    };
  }

  ///获取本机视频流
  Future<void> createVideoMedia(
      {bool audio = true,
      double width = 640,
      double height = 480,
      int frameRate = 30,
      bool replace = false}) async {
    if (id != null) {
      if (replace) {
        await close();
      } else {
        return;
      }
    }
    Map<String, dynamic> mediaConstraints =
        _getDefaultConstraints(width: width, height: height);
    var mediaStream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);
    this.mediaStream = mediaStream;
    id = mediaStream.id;
    this.audio = audio;
    video = true;
  }

  ///获取本机屏幕流
  Future<void> createDisplayMedia(
      {DesktopCapturerSource? selectedSource,
      bool audio = false,
      bool replace = false}) async {
    if (id != null) {
      if (replace) {
        await close();
      } else {
        return;
      }
    }
    if (selectedSource == null) {
      var sources = await ScreenSelectUtil.getSources();
      if (sources.isNotEmpty) {
        selectedSource = sources[0];
      }
    }
    dynamic video = selectedSource == null
        ? true
        : {
            'deviceId': {'exact': selectedSource.id},
            'mandatory': {'frameRate': 30.0}
          };
    Map<String, dynamic> mediaConstraints = <String, dynamic>{
      'audio': audio,
      'video': video
    };
    await close();
    var mediaStream =
        await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
    this.mediaStream = mediaStream;
    id = mediaStream.id;
    this.audio = audio;
    this.video = true;
  }

  ///获取本机音频流
  Future<void> createAudioMedia({bool replace = false}) async {
    if (id != null) {
      if (replace) {
        await close();
      } else {
        return;
      }
    }
    Map<String, dynamic> mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': false,
    };
    var mediaStream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);
    this.mediaStream = mediaStream;
    id = mediaStream.id;
    audio = true;
    video = false;
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
      RTCVideoRenderer? renderer = this.renderer;
      if (renderer == null) {
        renderer = RTCVideoRenderer();
        await renderer.initialize();
        renderer.srcObject = mediaStream;
        this.renderer = renderer;
        logger.i('bind VideoRender videoHeight:$height, videoWidth:$width');
      }
    }
  }

  int? get height {
    if (renderer != null) {
      return renderer!.videoHeight;
    }
    return null;
  }

  int? get width {
    if (renderer != null) {
      return renderer!.videoWidth;
    }
    return null;
  }

  String? get ownerTag {
    if (mediaStream != null) {
      return mediaStream!.ownerTag;
    }
    return null;
  }

  ///关闭视频渲染器和流，关闭后里面的流为空
  close() async {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      if (mediaStream.ownerTag != 'local') {
        logger.e('dispose stream:${mediaStream.id} ${mediaStream.ownerTag}');
      } else {
        logger.i('dispose stream:${mediaStream.id} ${mediaStream.ownerTag}');
      }
      try {
        await mediaStream.dispose();
      } catch (e) {
        logger.e('mediaStream.close failure:$e');
      }
      this.mediaStream = null;
      id = null;
    }
    var renderer = this.renderer;
    if (renderer != null) {
      renderer.srcObject = null;
      try {
        renderer.dispose();
      } catch (e) {
        logger.e('renderer.dispose failure:$e');
      }
      this.renderer = null;
    }
  }

  Widget _createVideoViewContainer({
    double? width,
    double? height,
    Color? color = Colors.black,
    Widget? child,
  }) {
    child ??= emptyVideoView;
    Widget container = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      height = height ?? constraints.maxHeight;
      width = width ?? constraints.maxWidth;
      return Center(
        child: Container(
          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
          width: width,
          height: height,
          decoration: BoxDecoration(color: color),
          child: child,
        ),
      );
    });

    return container;
  }

  /// 渲染器创建展示视图
  Widget createVideoView({
    RTCVideoViewObjectFit objectFit =
        RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    bool mirror = false,
    FilterQuality filterQuality = FilterQuality.low,
    bool fitScreen = false,
    double? width,
    double? height,
    Color? color = Colors.black,
  }) {
    Widget? videoView;
    var renderer = this.renderer;
    if (renderer != null) {
      videoView = RTCVideoView(renderer,
          objectFit: objectFit, mirror: mirror, filterQuality: filterQuality);
      if (audio && !video) {
        videoView = Stack(children: [
          const Center(
              child: Icon(
            Icons.multitrack_audio_outlined,
            color: Colors.white,
            size: 60,
          )),
          videoView,
        ]);
      }
    }
    Widget container = _createVideoViewContainer(
        width: width, height: height, color: color, child: videoView);
    if (!fitScreen) {
      return container;
    }

    //用屏幕尺寸
    return OrientationBuilder(
      builder: (context, orientation) {
        width = MediaQuery.of(context).size.width;
        height = MediaQuery.of(context).size.height;
        container = _createVideoViewContainer(
            width: width, height: height, child: videoView);
        return container;
      },
    );
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
  Future<void> switchSpeaker(bool enable) async {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      var tracks = mediaStream.getAudioTracks();
      if (tracks.isNotEmpty) {
        tracks[0].enableSpeakerphone(enable);
        Helper.setSpeakerphoneOn(enable);
      }
    }
  }

  Future<void> setTorch(bool torch) async {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      var tracks = mediaStream.getVideoTracks();
      if (tracks.isNotEmpty) {
        tracks[0].setTorch(torch);
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
  Future<void> setVolume(double volume) async {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      var tracks = mediaStream.getAudioTracks();
      if (tracks.isNotEmpty) {
        await Helper.setVolume(volume, tracks[0]);
      }
    }
  }

  /// 开始记录视频流到文件
  void startRecording({String? filePath}) async {
    if (mediaStream == null) throw 'Stream is not initialized';
    if (platformParams.ios) {
      logger.e('Recording is not available on iOS');
      return;
    }
    // TODO(rostopira): request write storage permission
    if (filePath == null) {
      Directory? storagePath = await PathUtil.getApplicationDirectory();
      filePath = '${storagePath?.path}/webrtc_sample/test.mp4';
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
