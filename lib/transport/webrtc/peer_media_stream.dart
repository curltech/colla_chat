import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/media_stream_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:colla_chat/plugin/talker_logger.dart' as log;

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
  ///直接设置的媒体流，不为空的时候，视频和音频轨道都为空
  MediaStream? mediaStream;

  ///直接设置的单独的livekit的视频轨道
  ///视频和音频轨道的流id可能不同，但是platformParticipant相同
  VideoTrack? videoTrack;

  ///直接设置的单独livekit的音频轨道
  AudioTrack? audioTrack;

  ///流对应的livekit的参与者
  Participant? participant;

  ///平台的业务相关的参与者
  PlatformParticipant? platformParticipant;

  PeerMediaStream({
    this.mediaStream,
    this.videoTrack,
    this.audioTrack,
    this.participant,
    this.platformParticipant,
  });

  String? get id {
    if (mediaStream != null) {
      return mediaStream!.id;
    } else if (videoTrack != null) {
      return videoTrack!.mediaStream.id;
    } else if (audioTrack != null) {
      return audioTrack!.mediaStream.id;
    }
    return null;
  }

  bool contain(String streamId) {
    if (streamId == mediaStream?.id ||
        streamId == videoTrack?.mediaStream.id ||
        streamId == audioTrack?.mediaStream.id) {
      return true;
    }
    return false;
  }

  String? get peerId {
    return platformParticipant?.peerId;
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
        audio: audio, width: width, height: height, frameRate: frameRate);

    return PeerMediaStream(
        mediaStream: mediaStream, platformParticipant: platformParticipant);
  }

  /// 创建本地视频
  static Future<PeerMediaStream> createLocalVideoTrack(
      {CameraCaptureOptions videoOptions = const CameraCaptureOptions(
        cameraPosition: CameraPosition.front,
        params: VideoParametersPresets.h720_169,
      ),
      bool audio = true,
      AudioCaptureOptions audioOptions = const AudioCaptureOptions()}) async {
    LocalVideoTrack localVideo =
        await LocalVideoTrack.createCameraTrack(videoOptions);
    PlatformParticipant platformParticipant = PlatformParticipant(
        myself.peerId!,
        clientId: myself.clientId,
        name: myself.name);
    LocalAudioTrack? localAudio;
    if (audio) {
      localAudio = await LocalAudioTrack.create(audioOptions);
    }

    return PeerMediaStream(
        videoTrack: localVideo,
        audioTrack: localAudio,
        platformParticipant: platformParticipant);
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

  static Future<PeerMediaStream?> createRemotePeerMediaStream(
      RemoteTrack track, RemoteParticipant remoteParticipant) async {
    String identity = remoteParticipant.identity;
    String name = remoteParticipant.name;
    PlatformParticipant platformParticipant =
        PlatformParticipant(identity, name: name);
    PeerMediaStream? peerMediaStream;
    if (track is RemoteVideoTrack) {
      peerMediaStream = PeerMediaStream(
          videoTrack: track,
          platformParticipant: platformParticipant,
          participant: remoteParticipant);
    }
    if (track is RemoteAudioTrack) {
      peerMediaStream = PeerMediaStream(
          audioTrack: track,
          platformParticipant: platformParticipant,
          participant: remoteParticipant);
    }

    return peerMediaStream;
  }

  bool get audio {
    bool a = false;
    if (mediaStream != null) {
      a = mediaStream!.getAudioTracks().isNotEmpty;
    } else if (audioTrack != null) {
      a = audioTrack!.mediaStream.getAudioTracks().isNotEmpty;
    } else if (videoTrack != null) {
      a = videoTrack!.mediaStream.getAudioTracks().isNotEmpty;
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
    } else if (videoTrack != null) {
      this.videoTrack = videoTrack;
    } else if (audioTrack != null) {
      this.audioTrack = audioTrack;
    } else {
      this.mediaStream = null;
      this.videoTrack = null;
    }
  }

  static Future<PeerMediaStream> createPeerMediaStream({
    required PlatformParticipant platformParticipant,
    MediaStream? mediaStream,
    VideoTrack? videoTrack,
    AudioTrack? audioTrack,
  }) async {
    if (mediaStream != null) {
      return PeerMediaStream(
          mediaStream: mediaStream, platformParticipant: platformParticipant);
    }
    return PeerMediaStream(
        videoTrack: videoTrack,
        audioTrack: audioTrack,
        platformParticipant: platformParticipant);
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
    }
  }

  /// 切换第一个视频轨道的摄像头，对sfu模式来说，必须指定position
  switchCamera({CameraPosition? position}) async {
    if (participant != null) {
      final Track? track =
          participant!.videoTrackPublications.firstOrNull?.track;
      if (track != null && track is LocalVideoTrack && position != null) {
        await track.setCameraPosition(position);
      }
    } else {
      if (mediaStream != null) {
        await MediaStreamUtil.switchCamera(mediaStream!);
      }
    }
  }

  /// 参与者是否正在说话，用于sfu模式
  bool? isSpeaking() {
    if (participant != null) {
      return participant?.isSpeaking;
    }
    return null;
  }

  /// 切换设备的麦克风是否打开
  switchSpeaker(bool enableSpeaker) async {
    if (participant != null) {
      await Hardware.instance.setPreferSpeakerOutput(false);
      await Hardware.instance.setSpeakerphoneOn(enableSpeaker);
    } else {
      await Hardware.instance.setPreferSpeakerOutput(false);
      MediaStreamUtil.setSpeakerphoneOn(enableSpeaker);
    }
  }

  /// 是否静音
  bool? isMuted() {
    if (participant != null) {
      for (TrackPublication<Track> audioTrackPublication
          in participant!.audioTrackPublications) {
        return audioTrackPublication.muted;
      }
      for (TrackPublication<Track> videoTrackPublication
          in participant!.videoTrackPublications) {
        return videoTrackPublication.muted;
      }
    } else {
      if (mediaStream != null) {
        return MediaStreamUtil.isMuted(mediaStream!);
      }
    }
    return null;
  }

  /// 设置音频流的麦克风是否静音，用于本地参与者或者本地流
  setMicrophoneMute(bool enableMute) async {
    if (participant != null) {
      for (TrackPublication<Track> audioTrackPublication
          in participant!.audioTrackPublications) {
        LocalTrackPublication localTrackPublication =
            audioTrackPublication as LocalTrackPublication;
        enableMute
            ? localTrackPublication.mute()
            : localTrackPublication.unmute();
      }
      for (TrackPublication<Track> videoTrackPublication
          in participant!.videoTrackPublications) {
        LocalTrackPublication localTrackPublication =
            videoTrackPublication as LocalTrackPublication;
        enableMute
            ? localTrackPublication.mute()
            : localTrackPublication.unmute();
      }
    } else {
      if (mediaStream != null) {
        await MediaStreamUtil.setMicrophoneMute(mediaStream!, enableMute);
      }
    }
  }

  /// 获取参与者的音量，用于sfu模式
  double? getVolume() {
    if (participant != null) {
      return 1 - participant!.audioLevel;
    }
    return null;
  }

  /// 设置参与者或者流的音量
  setVolume(double volume) async {
    if (participant != null) {
      participant?.audioLevel = 1 - volume;
    } else {
      if (mediaStream != null) {
        await MediaStreamUtil.setVolume(mediaStream!, volume);
      }
    }
  }

  /// 设置视频流流的放大缩小
  setZoom(double zoomLevel) async {
    if (participant != null) {
    } else {
      if (mediaStream != null) {
        await MediaStreamUtil.setZoom(mediaStream!, zoomLevel);
      }
    }
  }

  /// 参与者是否加密，用于sfu模式
  bool? isEncrypted() {
    if (participant != null) {
      return participant!.isEncrypted;
    }
    return null;
  }

  /// 摄像头是否发布，用于sfu模式
  bool? isCameraEnabled() {
    if (participant != null) {
      return participant!.isCameraEnabled();
    }
    return null;
  }

  /// 获取参与者的连接质量，用于sfu模式
  ConnectionQuality? getConnectionQuality() {
    if (participant != null) {
      return participant?.connectionQuality;
    }
    return null;
  }

  /// 激活参与者的轨道，用于sfu模式
  enable() async {
    if (participant != null) {
      RemoteParticipant remoteParticipant = participant as RemoteParticipant;
      for (RemoteTrackPublication publication
          in remoteParticipant.trackPublications.values) {
        await publication.enable();
      }
    }
  }

  /// 关闭参与者的轨道，用于sfu模式
  disable() async {
    if (participant != null) {
      RemoteParticipant remoteParticipant = participant as RemoteParticipant;
      for (RemoteTrackPublication publication
          in remoteParticipant.trackPublications.values) {
        await publication.disable();
      }
    }
  }

  /// 设置参与者的轨道的fps，用于sfu模式
  setVideoFPS(int fps) async {
    if (participant != null) {
      RemoteParticipant remoteParticipant = participant as RemoteParticipant;
      for (RemoteTrackPublication publication
          in remoteParticipant.trackPublications.values) {
        await publication.setVideoFPS(fps);
      }
    }
  }

  /// 设置参与者的轨道的视频质量，用于sfu模式
  setVideoQuality(VideoQuality videoQuality) async {
    if (participant != null) {
      RemoteParticipant remoteParticipant = participant as RemoteParticipant;
      for (RemoteTrackPublication publication
          in remoteParticipant.trackPublications.values) {
        await publication.setVideoQuality(videoQuality);
      }
    }
  }
}
