import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

///媒体控制器，内部是PeerVideoRender的集合
class VideoRenderController with ChangeNotifier {
  PeerVideoRender? _videoRender;
  final Map<String, PeerVideoRender> videoRenders = {};

  VideoRenderController({List<PeerVideoRender> videoRenders = const []}) {
    if (videoRenders.isNotEmpty) {
      for (var render in videoRenders) {
        add(render);
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
    }
  }

  close({String? streamId}) {
    if (streamId == null) {
      for (var videoRender in videoRenders.values) {
        videoRender.dispose();
      }
      videoRenders.clear();
      _videoRender = null;
    } else {
      var videoRender = videoRenders[streamId];
      if (videoRender != null) {
        videoRender.dispose();
        videoRenders.remove(streamId);
        if (_videoRender != null && _videoRender!.id == streamId) {
          _videoRender = null;
        }
      }
    }
  }
}

///本地媒体控制器
class LocalVideoRenderController extends VideoRenderController {
  Future<PeerVideoRender> createVideoRender(
      {MediaStream? stream,
      bool videoMedia = false,
      bool audioMedia = false,
      bool displayMedia = false}) async {
    if (videoRender != null) {
      if (videoMedia || audioMedia) {
        return videoRender!;
      }
    }
    if (stream != null) {
      var streamId = stream.id;
      var videoRender = videoRenders[streamId];
      if (videoRender != null) {
        return videoRender;
      }
    }
    PeerVideoRender render = await PeerVideoRender.from(myself.peerId!,
        clientId: myself.clientId,
        name: myself.myselfPeer!.name,
        stream: stream,
        videoMedia: videoMedia,
        audioMedia: audioMedia,
        displayMedia: displayMedia);
    if (audioMedia || videoMedia) {
      videoRender = render;
    }
    await render.bindRTCVideoRender();
    add(render);
    render.peerId = myself.peerId;
    render.name = myself.name;
    render.clientId = myself.clientId;
    notifyListeners();

    return render;
  }
}

final LocalVideoRenderController localVideoRenderController =
    LocalVideoRenderController();
