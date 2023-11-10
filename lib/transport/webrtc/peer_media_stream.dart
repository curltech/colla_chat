import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/media_stream_util.dart';
import 'package:colla_chat/transport/webrtc/screen_select_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart' as livekit_client;

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

class Participant {
  String peerId;
  String? name;
  String? clientId;

  Participant(this.peerId, {this.clientId, this.name});
}

/// 关联webrtc媒体流和peer的类，可以构造本地媒体流或者传入的媒体流
class PeerMediaStream {
  String? id;
  MediaStream? mediaStream;
  livekit_client.VideoTrack? videoTrack;
  livekit_client.AudioTrack? audioTrack;
  livekit_client.Participant? livekitParticipant;

  //业务相关的数据
  Participant? participant;

  PeerMediaStream({
    this.mediaStream,
    this.videoTrack,
    this.audioTrack,
    this.livekitParticipant,
    this.participant,
  }) {
    if (mediaStream != null) {
      id = mediaStream!.id;
    } else if (videoTrack != null) {
      id = videoTrack!.mediaStream.id;
    } else if (audioTrack != null) {
      id = audioTrack!.mediaStream.id;
    }
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
  setStream(
      {MediaStream? mediaStream, livekit_client.VideoTrack? videoTrack}) async {
    if (this.mediaStream == mediaStream) {
      return;
    }
    if (this.videoTrack == videoTrack) {
      return;
    }
    await close();
    if (mediaStream != null) {
      this.mediaStream = mediaStream;
      id = mediaStream.id;
    } else if (videoTrack != null) {
      this.videoTrack = videoTrack;
      id = videoTrack.mediaStream.id;
    } else {
      this.mediaStream = null;
      this.videoTrack = null;
      id = null;
    }
  }

  ///创建本机视频流，并且设置peer信息
  Future<void> buildVideoMedia(String peerId,
      {String? clientId,
      String? name,
      bool audio = true,
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
    participant = Participant(peerId, clientId: clientId, name: name);
    var mediaStream = await MediaStreamUtil.createVideoMediaStream(
        width: width, height: height, frameRate: frameRate);
    this.mediaStream = mediaStream;
    id = mediaStream.id;
  }

  ///获取本机音频流
  Future<void> buildAudioMedia(String peerId,
      {String? clientId, String? name, bool replace = false}) async {
    if (id != null) {
      if (replace) {
        await close();
      } else {
        return;
      }
    }
    participant = Participant(peerId, clientId: clientId, name: name);
    Map<String, dynamic> mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': false,
    };
    var mediaStream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);
    this.mediaStream = mediaStream;
    id = mediaStream.id;
  }

  ///获取本机屏幕流
  Future<void> buildDisplayMedia(String peerId,
      {String? clientId,
      String? name,
      DesktopCapturerSource? selectedSource,
      bool audio = false,
      bool replace = false}) async {
    if (id != null) {
      if (replace) {
        await close();
      } else {
        return;
      }
    }
    participant = Participant(peerId, clientId: clientId, name: name);

    dynamic video = true;
    if (platformParams.ios) {
      video = {
        'deviceId': 'broadcast',
        'mandatory': {'frameRate': 30.0}
      };
    } else {
      if (selectedSource == null) {
        var sources = await ScreenSelectUtil.getSources();
        if (sources.isNotEmpty) {
          selectedSource = sources[0];
        }
      }
    }
    if (selectedSource != null) {
      video = {
        'deviceId': {'exact': selectedSource.id},
        'mandatory': {'frameRate': 30.0}
      };
    }
    Map<String, dynamic> mediaConstraints = <String, dynamic>{
      'audio': audio,
      'video': video
    };
    await close();
    var mediaStream =
        await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
    this.mediaStream = mediaStream;
    id = mediaStream.id;
  }

  Future<void> buildMediaStream(
    String peerId, {
    MediaStream? mediaStream,
    livekit_client.VideoTrack? videoTrack,
    String? clientId,
    String? name,
  }) async {
    participant = Participant(peerId, clientId: clientId, name: name);
    setStream(mediaStream: mediaStream, videoTrack: videoTrack);
  }

  bool get local {
    if (mediaStream != null) {
      return mediaStream!.ownerTag == 'local';
    } else if (videoTrack != null) {
      return videoTrack!.mediaStream.ownerTag == 'local';
    }
    return false;
  }

  ///关闭媒体流，关闭后里面的流为空
  close() async {
    if (mediaStream != null) {
      var mediaStream = this.mediaStream;
      if (!local) {
        logger.i(
            'dispose non local stream:${mediaStream!.id} ${mediaStream.ownerTag}');
      } else {
        logger.i('dispose stream:${mediaStream!.id} ${mediaStream.ownerTag}');
      }
      try {
        await mediaStream.dispose();
      } catch (e) {
        logger.e('mediaStream.close failure:$e');
      }
      this.mediaStream = null;
      id = null;
    }
    if (videoTrack != null) {
      var mediaStream = videoTrack!.mediaStream;
      if (!local) {
        logger.i(
            'dispose non local videoTrack:${mediaStream.id} ${mediaStream.ownerTag}');
      } else {
        logger
            .i('dispose videoTrack:${mediaStream.id} ${mediaStream.ownerTag}');
      }
      try {
        await videoTrack!.dispose();
      } catch (e) {
        logger.e('videoTrack.close failure:$e');
      }
      videoTrack = null;
      id = null;
    }
  }
}
