import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

///媒体控制器，内部是PeerVideoRender的集合，以流的id为key
///LocalVideoRenderController和RemoteVideoRoomRenderController是其子类，
///前者代表本地的视频和音频的总共只能有一个，屏幕共享和媒体播放可以有多个
///后者代表远程的视频，包含所有的远程视频流的PeerVideoRender
class VideoRenderController with ChangeNotifier {
  //当前选择的render
  PeerVideoRender? _currentVideoRender;

  //主视频
  PeerVideoRender? _mainVideoRender;

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

  //本地视频和音频的render
  PeerVideoRender? get mainVideoRender {
    return _mainVideoRender;
  }

  set mainVideoRender(PeerVideoRender? mainVideoRender) {
    if (_mainVideoRender != mainVideoRender) {
      if (_mainVideoRender != null) {
        remove(_mainVideoRender!);
      }
      _mainVideoRender = mainVideoRender;
      if (_mainVideoRender != null) {
        add(_mainVideoRender!);
      }
    }
  }

  //判断是否有视频
  bool get video {
    if (_mainVideoRender != null) {
      return _mainVideoRender!.video;
    }
    return false;
  }

  PeerVideoRender? get currentVideoRender {
    return _currentVideoRender;
  }

  set currentVideoRender(PeerVideoRender? currentVideoRender) {
    if (_currentVideoRender != currentVideoRender) {
      onVideoRenderOperator(
          VideoRenderOperator.unselected.name, _currentVideoRender);
      _currentVideoRender = currentVideoRender;
      onVideoRenderOperator(
          VideoRenderOperator.selected.name, _currentVideoRender);
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

  ///增加videoRender，激活add事件
  add(PeerVideoRender videoRender) {
    var id = videoRender.id;
    if (id != null && !videoRenders.containsKey(id)) {
      videoRenders[id] = videoRender;
      onVideoRenderOperator(VideoRenderOperator.add.name, videoRender);
    }
  }

  ///移除视频渲染器和流，激活remove事件
  remove(PeerVideoRender videoRender) async {
    var streamId = videoRender.id;
    if (streamId != null && videoRenders.containsKey(streamId)) {
      videoRenders.remove(streamId);
      if (_currentVideoRender != null && _currentVideoRender!.id == streamId) {
        _currentVideoRender = null;
      }
      if (_mainVideoRender != null && _mainVideoRender!.id == streamId) {
        _mainVideoRender = null;
      }
      //在流被关闭前调用事件处理
      await onVideoRenderOperator(VideoRenderOperator.remove.name, videoRender);
    }
  }

  ///关闭渲染器和流
  close(PeerVideoRender videoRender) async {
    await videoRender.close();
  }

  ///移除并且关闭控制器所有的视频，激活exit事件
  exit() async {
    //先移除，后关闭
    var videoRenders = this.videoRenders.values.toList();
    this.videoRenders.clear();
    for (var videoRender in videoRenders) {
      await videoRender.close();
    }
    _currentVideoRender = null;
    _mainVideoRender = null;
    await onVideoRenderOperator(VideoRenderOperator.exit.name, null);
  }
}

///本地媒体控制器
class LocalVideoRenderController extends VideoRenderController {
  ///创建本地的Video render，设置当前videoChatRender，激活create和add监听事件
  Future<PeerVideoRender> createVideoMediaRender({
    bool audio = true,
    double width = 640,
    double height = 480,
    int frameRate = 30,
  }) async {
    PeerVideoRender render = await PeerVideoRender.fromVideoMedia(
      myself.peerId!,
      clientId: myself.clientId,
      name: myself.myselfPeer.name,
      audio: audio,
      width: width,
      height: height,
      frameRate: frameRate,
    );
    onVideoRenderOperator(VideoRenderOperator.create.name, _mainVideoRender);
    mainVideoRender = render;

    return render;
  }

  ///创建本地的Audio render，设置当前videoChatRender，激活create和add监听事件
  Future<PeerVideoRender> createAudioMediaRender() async {
    PeerVideoRender render = await PeerVideoRender.fromAudioMedia(
      myself.peerId!,
      clientId: myself.clientId,
      name: myself.myselfPeer.name,
    );
    onVideoRenderOperator(VideoRenderOperator.create.name, _mainVideoRender);
    mainVideoRender = render;

    return render;
  }

  ///创建本地的Display render，激活create和add监听事件
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
    onVideoRenderOperator(VideoRenderOperator.create.name, render);
    add(render);

    return render;
  }

  ///创建本地的Stream render，激活add监听事件
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
    onVideoRenderOperator(VideoRenderOperator.create.name, render);
    add(render);

    return render;
  }

  ///在会议创建后，自动创建本地视频，如果存在则直接返回
  openLocalMainVideoRender(bool video) async {
    //如果本地主视频存在，直接返回
    if (mainVideoRender != null) {
      return;
    }
    //根据conference.video来判断是请求音频还是视频，并创建本地视频render
    if (video) {
      await localVideoRenderController.createVideoMediaRender();
      //测试目的，使用屏幕
      // await localVideoRenderController.createDisplayMediaRender();
    } else {
      await localVideoRenderController.createAudioMediaRender();
    }
  }

  ///关闭本地特定的流
  @override
  close(PeerVideoRender videoRender) async {
    await super.close(videoRender);
    if (mainVideoRender != null && videoRender.id == mainVideoRender!.id) {
      mainVideoRender = null;
    }
  }

  ///关闭本地所有的流，激活exit事件
  @override
  exit() async {
    await super.exit();
    mainVideoRender = null;
  }
}

///本地视频流和渲染器的控制器，本地流操作会触发事件，不涉及webrtc的连接对应的操作
final LocalVideoRenderController localVideoRenderController =
    LocalVideoRenderController();
