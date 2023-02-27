import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

///媒体控制器，内部是PeerVideoRender的集合，以流的id为key
///LocalVideoRenderController和VideoRoomRenderController是其子类，
///前者代表本地的视频和音频的总共只能有一个，屏幕共享和媒体播放可以有多个
///后者代表远程的视频，包含所有的远程视频流的PeerVideoRender
class VideoRenderController with ChangeNotifier {
  //当前选择的render
  PeerVideoRender? _videoRender;

  final Map<String, PeerVideoRender> videoRenders = {};

  Map<String, List<Future<void> Function(PeerVideoRender? videoRender)>> fnsm =
      {};

  VideoRenderController({List<PeerVideoRender> videoRenders = const []}) {
    if (videoRenders.isNotEmpty) {
      for (var render in videoRenders) {
        add(render);
      }
    }
  }

  registerVideoRenderOperator(
      String videoRenderOperator, Future<void> Function(PeerVideoRender?) fn) {
    List<Future<void> Function(PeerVideoRender?)>? fns =
        fnsm[videoRenderOperator];
    if (fns == null) {
      fns = [];
      fnsm[videoRenderOperator] = fns;
    }
    fns.add(fn);
  }

  unregisterVideoRenderOperator(
      String videoRenderOperator, Future<void> Function(PeerVideoRender?) fn) {
    List<Future<void> Function(PeerVideoRender?)>? fns =
        fnsm[videoRenderOperator];
    if (fns == null) {
      return;
    }
    fns.remove(fn);
    if (fns.isEmpty) {
      fnsm.remove(videoRenderOperator);
    }
  }

  onVideoRenderOperator(
      String videoRenderOperator, PeerVideoRender? videoRender) {
    List<Future<void> Function(PeerVideoRender?)>? fns =
        fnsm[videoRenderOperator];
    if (fns != null) {
      for (var fn in fns) {
        fn(videoRender);
      }
    }
  }

  PeerVideoRender? get videoRender {
    return _videoRender;
  }

  set videoRender(PeerVideoRender? videoRender) {
    if (_videoRender != videoRender) {
      _videoRender = videoRender;
    }
  }

  Map<String, PeerVideoRender> getVideoRenders(
      {String? peerId, String? clientId}) {
    if (peerId == null && clientId == null) {
      return this.videoRenders;
    }
    Map<String, PeerVideoRender> videoRenders = {};
    for (var videoRender in this.videoRenders.values) {
      if (peerId != null && peerId == videoRender.peerId) {
        if (clientId != null) {
          if (clientId == videoRender.clientId) {
            if (videoRender.id != null) {
              videoRenders[videoRender.id!] = videoRender;
            }
          }
        } else {
          if (videoRender.id != null) {
            videoRenders[videoRender.id!] = videoRender;
          }
        }
      }
    }
    return videoRenders;
  }

  Map<String, MediaStream> getMediaStreams({String? peerId, String? clientId}) {
    Map<String, PeerVideoRender> renders =
        getVideoRenders(peerId: peerId, clientId: clientId);
    Map<String, MediaStream> streams = {};
    if (renders.isNotEmpty) {
      for (var render in renders.values) {
        var mediaStream = render.mediaStream;
        if (mediaStream != null) {
          streams[mediaStream.id] = mediaStream;
        }
      }
    }
    return streams;
  }

  add(PeerVideoRender videoRender) {
    var id = videoRender.id;
    if (id != null && !videoRenders.containsKey(id)) {
      videoRenders[id] = videoRender;
      onVideoRenderOperator(VideoRenderOperator.add.name, videoRender);
    }
  }

  remove(PeerVideoRender videoRender) {
    var id = videoRender.id;
    if (id != null && videoRenders.containsKey(id)) {
      videoRender.dispose();
      videoRenders.remove(id);
      onVideoRenderOperator(VideoRenderOperator.remove.name, videoRender);
    }
  }

  ///关闭streamId的流或者关闭控制器所有的流
  close({String? streamId}) {
    if (streamId == null) {
      for (var videoRender in videoRenders.values) {
        videoRender.dispose();
      }
      videoRenders.clear();
      _videoRender = null;
      onVideoRenderOperator(VideoRenderOperator.close.name, null);
    } else {
      var videoRender = videoRenders[streamId];
      if (videoRender != null) {
        videoRender.dispose();
        videoRenders.remove(streamId);
        if (_videoRender != null && _videoRender!.id == streamId) {
          _videoRender = null;
        }
        onVideoRenderOperator(VideoRenderOperator.remove.name, videoRender);
      }
    }
  }
}

///本地媒体控制器
class LocalVideoRenderController extends VideoRenderController {
  //本地视频和音频的render，只能是其中一种，可以切换
  PeerVideoRender? _videoChatRender;

  //本地视频和音频的render
  PeerVideoRender? get videoChatRender {
    return _videoChatRender;
  }

  set videoChatRender(PeerVideoRender? videoRender) {
    if (_videoChatRender != videoRender) {
      if (_videoChatRender != null) {
        remove(_videoChatRender!);
      }
      _videoChatRender = videoRender;
      if (videoRender != null) {
        add(videoRender);
      }
    }
  }

  //判断是否有视频
  bool get video {
    if (_videoChatRender != null) {
      return _videoChatRender!.video;
    }
    return false;
  }

  ///创建本地的Video render
  Future<PeerVideoRender> createVideoMediaRender({
    bool audio = true,
    int minWidth = 640,
    int minHeight = 480,
    int minFrameRate = 30,
  }) async {
    PeerVideoRender render = await PeerVideoRender.fromVideoMedia(
      myself.peerId!,
      clientId: myself.clientId,
      name: myself.myselfPeer.name,
      audio: audio,
      minWidth: minWidth,
      minHeight: minHeight,
      minFrameRate: minFrameRate,
    );
    videoChatRender = render;
    onVideoRenderOperator(VideoRenderOperator.create.name, videoRender);

    return render;
  }

  ///创建本地的Audio render
  Future<PeerVideoRender> createAudioMediaRender() async {
    PeerVideoRender render = await PeerVideoRender.fromAudioMedia(
      myself.peerId!,
      clientId: myself.clientId,
      name: myself.myselfPeer.name,
    );
    videoChatRender = render;
    onVideoRenderOperator(VideoRenderOperator.create.name, videoRender);

    return render;
  }

  ///创建本地的Display render
  Future<PeerVideoRender> createDisplayMediaRender({
    DesktopCapturerSource? selectedSource,
    bool audio = false,
  }) async {
    PeerVideoRender render = await PeerVideoRender.fromDisplayMedia(
        myself.peerId!,
        clientId: myself.clientId,
        name: myself.myselfPeer.name,
        selectedSource: selectedSource,
        audio: audio);
    add(render);

    return render;
  }

  ///创建本地的Stream render
  Future<PeerVideoRender> createMediaStreamRender(
    MediaStream stream,
  ) async {
    var streamId = stream.id;
    var videoRender = videoRenders[streamId];
    if (videoRender != null) {
      return videoRender;
    }
    PeerVideoRender render = await PeerVideoRender.fromMediaStream(
      myself.peerId!,
      clientId: myself.clientId,
      name: myself.myselfPeer.name,
      stream: stream,
    );
    add(render);

    return render;
  }

  @override
  close({String? streamId}) {
    if (streamId == null) {
      _videoChatRender = null;
    } else {
      if (_videoChatRender != null && streamId == _videoChatRender!.id) {
        _videoChatRender = null;
      }
    }
    super.close(streamId: streamId);
  }
}

final LocalVideoRenderController localVideoRenderController =
    LocalVideoRenderController();
