import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/transport/webrtc/screen_select_widget.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';

final emptyVideoView = Center(
  child: AppImage.mdAppImage,
);

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
    await dispose();
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
    int minWidth = 640,
    int minHeight = 480,
    int minFrameRate = 30,
  }) async {
    PeerVideoRender render = PeerVideoRender();
    render.peerId = peerId;
    render.clientId = clientId;
    render.name = name;
    await render.createVideoMedia(
      audio: audio,
      minWidth: minWidth,
      minHeight: minHeight,
      minFrameRate: minFrameRate,
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

  ///获取本机视频流
  Future<void> createVideoMedia(
      {bool audio = true,
      int minWidth = 640,
      int minHeight = 480,
      int minFrameRate = 30,
      bool replace = false}) async {
    if (id != null) {
      if (replace) {
        await dispose();
      } else {
        return;
      }
    }
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
        await dispose();
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
    await dispose();
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
        await dispose();
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

  dispose() async {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      try {
        await mediaStream.dispose();
      } catch (e) {
        logger.e('mediaStream.dispose failure:$e');
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
    Color? color,
  }) {
    RTCVideoView? videoView;
    var renderer = this.renderer;
    if (renderer != null) {
      videoView = RTCVideoView(renderer,
          objectFit: objectFit, mirror: mirror, filterQuality: filterQuality);
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
