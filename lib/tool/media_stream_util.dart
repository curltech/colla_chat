import 'dart:typed_data';

import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/transport/webrtc/screen_select_widget.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

class MediaStreamUtil {
  static Map<String, dynamic> _getDefaultConstraints({
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
  static Future<MediaStream> createVideoMediaStream(
      {bool audio = true,
      double width = 640,
      double height = 480,
      int frameRate = 30}) async {
    Map<String, dynamic> mediaConstraints =
        _getDefaultConstraints(width: width, height: height);
    var mediaStream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);
    return mediaStream;
  }

  ///获取本机屏幕流
  static Future<MediaStream> createDisplayMediaStream(
      {DesktopCapturerSource? selectedSource, bool audio = true}) async {
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
    var mediaStream =
        await navigator.mediaDevices.getDisplayMedia(mediaConstraints);

    return mediaStream;
  }

  ///获取本机音频流
  static Future<MediaStream> createAudioMediaStream(
      {bool replace = false}) async {
    Map<String, dynamic> mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': false,
    };
    var mediaStream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);
    return mediaStream;
  }

  ///获取本机的设备清单
  static Future<List<MediaDeviceInfo>?> enumerateDevices() async {
    return await navigator.mediaDevices.enumerateDevices();
  }

  static Future<List<MediaDeviceInfo>> get cameras =>
      Helper.enumerateDevices('videoinput');

  static Future<List<MediaDeviceInfo>> get audiooutputs =>
      Helper.enumerateDevices('audiooutput');

  ///获取媒体轨道支持的参数
  static MediaTrackSupportedConstraints getSupportedConstraints() {
    var mediaTrackSupportedConstraints =
        navigator.mediaDevices.getSupportedConstraints();

    return mediaTrackSupportedConstraints;
  }

  /// 捕获视频流的帧，就是快照
  static Future<ByteBuffer?> captureFrame(MediaStream mediaStream) async {
    final videoTrack = mediaStream
        .getVideoTracks()
        .firstWhere((track) => track.kind == 'video');
    final frame = await videoTrack.captureFrame();

    return frame;
  }

  /// 对视频流的第一个视频轨道切换摄像头，对手机来说，就是切换前置和后置摄像头
  static Future<bool> switchCamera(MediaStream mediaStream) async {
    var tracks = mediaStream.getVideoTracks();
    if (tracks.isNotEmpty) {
      for (MediaStreamTrack track in tracks) {
        return await Helper.switchCamera(track);
      }
    }

    return false;
  }

  /// 对视频流的第一个视频轨道设置远近
  static Future<void> setZoom(MediaStream mediaStream, double zoomLevel) async {
    var tracks = mediaStream.getVideoTracks();
    if (tracks.isNotEmpty) {
      for (MediaStreamTrack track in tracks) {
        return await Helper.setZoom(track, zoomLevel);
      }
    }
  }

  static Future<void> selectAudioOutput(String deviceId) async {
    await Helper.selectAudioOutput(deviceId);
  }

  static Future<void> selectAudioInput(String deviceId) async {
    await Helper.selectAudioInput(deviceId);
  }

  /// 对视频流的第一个音频轨道切换音频播放设备，对手机来说就是耳机还是喇叭
  static Future<void> switchSpeaker(
      MediaStream mediaStream, bool enable) async {
    var tracks = mediaStream.getAudioTracks();
    if (tracks.isNotEmpty) {
      for (MediaStreamTrack track in tracks) {
        track.enableSpeakerphone(enable);
      }
    }
  }

  /// 打开或者关闭手机的喇叭
  static Future<void> setSpeakerphoneOn(bool enable) async {
    await Helper.setSpeakerphoneOn(enable);
  }

  /// 打开手机的喇叭，优先使用蓝牙
  static Future<void> setSpeakerphoneOnButPreferBluetooth() async {
    await Helper.setSpeakerphoneOnButPreferBluetooth();
  }

  static Future<void> setTorch(MediaStream mediaStream, bool torch) async {
    var tracks = mediaStream.getVideoTracks();
    if (tracks.isNotEmpty) {
      for (MediaStreamTrack track in tracks) {
        await track.setTorch(torch);
      }
    }
  }

  /// 有一个轨道muted则返回muted
  static bool? isMuted(MediaStream mediaStream) {
    bool? muted;
    List<MediaStreamTrack> tracks = mediaStream.getAudioTracks();
    if (tracks.isNotEmpty) {
      for (MediaStreamTrack track in tracks) {
        muted = track.muted;
        if (muted == true) {
          break;
        }
      }
    }
    return muted;
  }

  static bool enabled(MediaStream mediaStream) {
    bool enabled = false;
    List<MediaStreamTrack> tracks = mediaStream.getAudioTracks();
    if (tracks.isNotEmpty) {
      for (MediaStreamTrack track in tracks) {
        enabled = track.enabled;
        if (enabled) {
          break;
        }
      }
    }
    tracks = mediaStream.getVideoTracks();
    if (!enabled && tracks.isNotEmpty) {
      for (MediaStreamTrack track in tracks) {
        enabled = track.enabled;
        if (enabled) {
          break;
        }
      }
    }
    return enabled;
  }

  /// 对视频流的第一个音频轨道的输入设备设置静音设置
  static Future<void> setMicrophoneMute(
      MediaStream mediaStream, bool mute) async {
    var tracks = mediaStream.getAudioTracks();
    if (tracks.isNotEmpty) {
      for (MediaStreamTrack track in tracks) {
        await Helper.setMicrophoneMute(mute, track);
      }
    }
  }

  /// 打开或者关闭视频流的第一个视频轨道
  static void turnTrack(MediaStream mediaStream, bool enabled) {
    var tracks = mediaStream.getVideoTracks();
    if (tracks.isNotEmpty) {
      for (MediaStreamTrack track in tracks) {
        track.enabled = enabled;
      }
    }
    tracks = mediaStream.getAudioTracks();
    if (tracks.isNotEmpty) {
      for (MediaStreamTrack track in tracks) {
        track.enabled = enabled;
      }
    }
  }

  /// 对视频流的第一个音频轨道设置音量
  static Future<void> setVolume(MediaStream mediaStream, double volume) async {
    var tracks = mediaStream.getAudioTracks();
    if (tracks.isNotEmpty) {
      for (MediaStreamTrack track in tracks) {
        await Helper.setVolume(volume, track);
      }
    }
  }

  /// 开始记录视频流到文件
  static Future<MediaRecorder?> startRecording(MediaStream mediaStream,
      {String? filePath}) async {
    if (platformParams.ios) {
      logger.e('Recording is not available on iOS');
      return null;
    }
    var uuid = const Uuid();
    String name = uuid.v4();
    if (filePath == null) {
      String storagePath = platformParams.path;
      filePath = '$storagePath/media_record/$name.mp4';
    }
    MediaRecorder mediaRecorder = MediaRecorder();
    final videoTrack = mediaStream
        .getVideoTracks()
        .firstWhere((track) => track.kind == 'video');
    await mediaRecorder.start(
      filePath,
      videoTrack: videoTrack,
    );

    return mediaRecorder;
  }

  /// 停止视频流的记录
  static Future<dynamic> stopRecording(MediaRecorder mediaRecorder) async {
    return await mediaRecorder.stop();
  }
}
