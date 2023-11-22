import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/media_stream_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:colla_chat/plugin/logger.dart' as log;

final emptyVideoView = Center(
  child: AppImage.mdAppImage,
);

enum PeerMediaStreamOperator {
  create,
  add,
  remove,
  unselected,
  selected,
  exit,
  terminate,
  mute,
  volume,
  torch
}

class PlatformParticipant {
  String peerId;
  String? name;
  String? clientId;

  PlatformParticipant(this.peerId, {this.clientId, this.name});
}

/// 关联webrtc媒体流和peer的类，可以构造本地媒体流或者传入的媒体流
class PeerMediaStream {
  String? id;
  MediaStream? mediaStream;
  VideoTrack? videoTrack;
  AudioTrack? audioTrack;
  Participant? livekitParticipant;

  //业务相关的数据
  PlatformParticipant? platformParticipant;

  PeerMediaStream({
    this.mediaStream,
    this.videoTrack,
    this.audioTrack,
    this.livekitParticipant,
    this.platformParticipant,
  }) {
    if (mediaStream != null) {
      id = mediaStream!.id;
    } else if (videoTrack != null) {
      id = videoTrack!.mediaStream.id;
    } else if (audioTrack != null) {
      id = audioTrack!.mediaStream.id;
    }
  }

  /// 创建本机视频流，并且设置peer信息
  static Future<PeerMediaStream> createLocalVideoMedia(
      {bool audio = true,
      double width = 640,
      double height = 480,
      int frameRate = 30}) async {
    PlatformParticipant platformParticipant = PlatformParticipant(
        myself.peerId!,
        clientId: myself.clientId,
        name: myself.name);
    var mediaStream = await MediaStreamUtil.createVideoMediaStream(
        width: width, height: height, frameRate: frameRate);

    return PeerMediaStream(
        mediaStream: mediaStream, platformParticipant: platformParticipant);
  }

  /// 创建本地视频
  static Future<PeerMediaStream> createLocalVideoTrack(
      {CameraCaptureOptions options = const CameraCaptureOptions(
        cameraPosition: CameraPosition.front,
        params: VideoParametersPresets.h720_169,
      )}) async {
    LocalVideoTrack localVideo =
        await LocalVideoTrack.createCameraTrack(options);
    PlatformParticipant platformParticipant = PlatformParticipant(
        myself.peerId!,
        clientId: myself.clientId,
        name: myself.name);

    return PeerMediaStream(
        videoTrack: localVideo, platformParticipant: platformParticipant);
  }

  ///获取本机音频流
  static Future<PeerMediaStream> createLocalAudioMedia() async {
    PlatformParticipant platformParticipant = PlatformParticipant(
        myself.peerId!,
        clientId: myself.clientId,
        name: myself.name);
    var mediaStream = await MediaStreamUtil.createAudioMediaStream();

    return PeerMediaStream(
        mediaStream: mediaStream, platformParticipant: platformParticipant);
  }

  /// 创建本地音频
  static Future<PeerMediaStream?> createLocalAudioTrack(
      {AudioCaptureOptions options = const AudioCaptureOptions()}) async {
    try {
      LocalAudioTrack localAudio = await LocalAudioTrack.create(options);
      PlatformParticipant platformParticipant = PlatformParticipant(
          myself.peerId!,
          clientId: myself.clientId,
          name: myself.name);
      return PeerMediaStream(
          audioTrack: localAudio, platformParticipant: platformParticipant);
    } catch (e) {
      log.logger.w('could not create audio: $e');
    }
    return null;
  }

  ///获取本机屏幕流
  static Future<PeerMediaStream> createLocalDisplayMedia(
      {DesktopCapturerSource? selectedSource, bool audio = false}) async {
    PlatformParticipant platformParticipant = PlatformParticipant(
        myself.peerId!,
        clientId: myself.clientId,
        name: myself.name);
    var mediaStream = await MediaStreamUtil.createDisplayMediaStream(
        selectedSource: selectedSource, audio: audio);

    return PeerMediaStream(
        mediaStream: mediaStream, platformParticipant: platformParticipant);
  }

  /// 创建屏幕共享，screenShareCaptureOptions包含源界面的编号
  static Future<PeerMediaStream> createLocalScreenShareTrack({
    String? sourceId,
    bool audio = true,
  }) async {
    ScreenShareCaptureOptions screenShareCaptureOptions =
        ScreenShareCaptureOptions(
            sourceId: sourceId, captureScreenAudio: audio);
    LocalVideoTrack localVideo =
        await LocalVideoTrack.createScreenShareTrack(screenShareCaptureOptions);
    PlatformParticipant platformParticipant = PlatformParticipant(
        myself.peerId!,
        clientId: myself.clientId,
        name: myself.name);

    return PeerMediaStream(
        videoTrack: localVideo, platformParticipant: platformParticipant);
  }

  bool get audio {
    bool a = false;
    if (mediaStream != null) {
      a = mediaStream!.getAudioTracks().isNotEmpty;
    } else if (videoTrack != null) {
      a = videoTrack!.mediaStream.getAudioTracks().isNotEmpty;
    } else if (audioTrack != null) {
      a = audioTrack!.mediaStream.getAudioTracks().isNotEmpty;
    }

    return a;
  }

  bool get video {
    bool v = false;
    if (mediaStream != null) {
      v = mediaStream!.getVideoTracks().isNotEmpty;
    } else if (videoTrack != null) {
      v = videoTrack!.mediaStream.getVideoTracks().isNotEmpty;
    }

    return v;
  }

  ///关闭旧的媒体流，设置新的媒体流，
  replaceStream({
    MediaStream? mediaStream,
    VideoTrack? videoTrack,
    AudioTrack? audioTrack,
  }) async {
    if (this.mediaStream == mediaStream) {
      return;
    }
    if (this.videoTrack == videoTrack) {
      return;
    }
    if (this.audioTrack == audioTrack) {
      return;
    }
    await close();
    if (mediaStream != null) {
      this.mediaStream = mediaStream;
      id = mediaStream.id;
    } else if (videoTrack != null) {
      this.videoTrack = videoTrack;
      id = videoTrack.mediaStream.id;
    } else if (audioTrack != null) {
      this.audioTrack = audioTrack;
      id = audioTrack.mediaStream.id;
    } else {
      this.mediaStream = null;
      this.videoTrack = null;
      id = null;
    }
  }

  static Future<PeerMediaStream> createPeerMediaStream({
    required PlatformParticipant platformParticipant,
    MediaStream? mediaStream,
    VideoTrack? videoTrack,
    AudioTrack? audioTrack,
  }) async {
    if (videoTrack != null) {
      return PeerMediaStream(
          videoTrack: videoTrack, platformParticipant: platformParticipant);
    }
    if (audioTrack != null) {
      return PeerMediaStream(
          audioTrack: audioTrack, platformParticipant: platformParticipant);
    }
    if (mediaStream != null) {
      return PeerMediaStream(
          mediaStream: mediaStream, platformParticipant: platformParticipant);
    }
    throw 'Must have mediaStream or videoTrack';
  }

  bool get local {
    if (mediaStream != null) {
      return mediaStream!.ownerTag == 'local';
    } else if (videoTrack != null) {
      return videoTrack!.mediaStream.ownerTag == 'local';
    } else if (audioTrack != null) {
      return audioTrack!.mediaStream.ownerTag == 'local';
    }
    return false;
  }

  ///关闭媒体流，关闭后里面的流为空
  close() async {
    if (mediaStream != null) {
      var mediaStream = this.mediaStream;
      try {
        await mediaStream?.dispose();
      } catch (e) {
        log.logger.e('mediaStream.close failure:$e');
      }
      this.mediaStream = null;
      id = null;
    }
    if (videoTrack != null) {
      var mediaStream = videoTrack?.mediaStream;
      try {
        await mediaStream?.dispose();
        await videoTrack?.stop();
        await videoTrack?.dispose();
      } catch (e) {
        log.logger.e('videoTrack.close failure:$e');
      }
      videoTrack = null;
      id = null;
    }
    if (audioTrack != null) {
      var mediaStream = audioTrack?.mediaStream;
      try {
        await mediaStream?.dispose();
        await audioTrack?.stop();
        await audioTrack?.dispose();
      } catch (e) {
        log.logger.e('audioTrack.close failure:$e');
      }
      audioTrack = null;
      id = null;
    }
  }
}
