import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/media_stream_util.dart';
import 'package:colla_chat/transport/webrtc/screen_select_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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
  mute,
  volume,
  torch
}

/// 关联webrtc媒体流和peer的类，可以构造本地媒体流或者传入的媒体流
class PeerMediaStream {
  String? id;
  MediaStream? mediaStream;

  //业务相关的数据
  String? peerId;
  String? name;
  String? clientId;

  bool audio = false;
  bool video = false;

  PeerMediaStream({this.mediaStream}) {
    if (mediaStream != null) {
      id = mediaStream!.id;
    }
  }

  ///关闭旧的媒体流，设置新的媒体流，
  setStream(MediaStream? mediaStream) async {
    if (this.mediaStream == mediaStream) {
      return;
    }
    await close();
    if (mediaStream != null) {
      this.mediaStream = mediaStream;
      id = mediaStream.id;
      video = mediaStream.getVideoTracks().isNotEmpty;
      audio = mediaStream.getAudioTracks().isNotEmpty;
    } else {
      this.mediaStream = null;
      id = null;
      video = false;
      audio = false;
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
    this.peerId = peerId;
    this.clientId = clientId;
    this.name = name;
    var mediaStream = await MediaStreamUtil.createVideoMediaStream(
        width: width, height: height, frameRate: frameRate);
    this.mediaStream = mediaStream;
    id = mediaStream.id;
    this.audio = audio;
    video = true;
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
    this.peerId = peerId;
    this.clientId = clientId;
    this.name = name;
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
    this.peerId = peerId;
    this.clientId = clientId;
    this.name = name;
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

  Future<void> buildMediaStream(
    MediaStream mediaStream,
    String peerId, {
    String? clientId,
    String? name,
  }) async {
    this.peerId = peerId;
    this.clientId = clientId;
    this.name = name;
    setStream(mediaStream);
  }

  String? get ownerTag {
    if (mediaStream != null) {
      return mediaStream!.ownerTag;
    }
    return null;
  }

  ///关闭媒体流，关闭后里面的流为空
  close() async {
    var mediaStream = this.mediaStream;
    if (mediaStream != null) {
      if (mediaStream.ownerTag != 'local') {
        logger.i(
            'dispose non local stream:${mediaStream.id} ${mediaStream.ownerTag}');
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
      audio = false;
      video = false;
    }
  }
}
