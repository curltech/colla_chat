import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

///媒体控制器，内部是PeerMediaStream的集合，以流的id为key
///LocalPeerMediaStreamController和RemotePeerMediaStreamController是其子类，
///前者代表本地的视频和音频的总共只能有一个，屏幕共享和媒体播放可以有多个
///后者代表远程的视频，包含所有的远程视频流的PeerMediaStream
class PeerMediaStreamController with ChangeNotifier {
  //当前选择的界面渲染器
  PeerMediaStream? _currentPeerMediaStream;

  //主视频对应的界面渲染器
  PeerMediaStream? _mainPeerMediaStream;

  //所有的视频流和对应的界面渲染器
  final Map<String, PeerMediaStream> peerMediaStreams = {};

  Map<String, List<Future<void> Function(PeerMediaStream? peerMediaStream)>>
      fnsm = {};

  PeerMediaStreamController(
      {List<PeerMediaStream> peerMediaStreams = const []}) {
    if (peerMediaStreams.isNotEmpty) {
      for (var peerMediaStream in peerMediaStreams) {
        add(peerMediaStream);
      }
    }
  }

  registerPeerMediaStreamOperator(String peerMediaStreamOperator,
      Future<void> Function(PeerMediaStream?) fn) {
    List<Future<void> Function(PeerMediaStream?)>? fns =
        fnsm[peerMediaStreamOperator];
    if (fns == null) {
      fns = [];
      fnsm[peerMediaStreamOperator] = fns;
    }
    fns.add(fn);
  }

  unregisterPeerMediaStreamOperator(String peerMediaStreamOperator,
      Future<void> Function(PeerMediaStream?) fn) {
    List<Future<void> Function(PeerMediaStream?)>? fns =
        fnsm[peerMediaStreamOperator];
    if (fns == null) {
      return;
    }
    fns.remove(fn);
    if (fns.isEmpty) {
      fnsm.remove(peerMediaStreamOperator);
    }
  }

  onPeerMediaStreamOperator(
      String peerMediaStreamOperator, PeerMediaStream? peerMediaStream) {
    List<Future<void> Function(PeerMediaStream?)>? fns =
        fnsm[peerMediaStreamOperator];
    if (fns != null) {
      for (var fn in fns) {
        fn(peerMediaStream);
      }
    }
  }

  //本地视频和音频的stream
  PeerMediaStream? get mainPeerMediaStream {
    return _mainPeerMediaStream;
  }

  set mainPeerMediaStream(PeerMediaStream? mainPeerMediaStream) {
    if (_mainPeerMediaStream != mainPeerMediaStream) {
      if (_mainPeerMediaStream != null) {
        remove(_mainPeerMediaStream!);
      }
      _mainPeerMediaStream = mainPeerMediaStream;
      if (_mainPeerMediaStream != null) {
        add(_mainPeerMediaStream!);
      }
    }
  }

  ///判断是否有视频
  bool get video {
    if (_mainPeerMediaStream != null) {
      return _mainPeerMediaStream!.video;
    }
    return false;
  }

  PeerMediaStream? get currentPeerMediaStream {
    return _currentPeerMediaStream;
  }

  set currentPeerMediaStream(PeerMediaStream? currentPeerMediaStream) {
    if (_currentPeerMediaStream != currentPeerMediaStream) {
      onPeerMediaStreamOperator(
          PeerMediaStreamOperator.unselected.name, _currentPeerMediaStream);
      _currentPeerMediaStream = currentPeerMediaStream;
      onPeerMediaStreamOperator(
          PeerMediaStreamOperator.selected.name, _currentPeerMediaStream);
    }
  }

  Map<String, PeerMediaStream> getPeerMediaStreams(
      {String? peerId, String? clientId}) {
    if (peerId == null && clientId == null) {
      return this.peerMediaStreams;
    }
    Map<String, PeerMediaStream> peerMediaStreams = {};
    for (var peerMediaStream in this.peerMediaStreams.values) {
      if (peerId != null && peerId == peerMediaStream.peerId) {
        if (clientId != null) {
          if (clientId == peerMediaStream.clientId) {
            if (peerMediaStream.id != null) {
              peerMediaStreams[peerMediaStream.id!] = peerMediaStream;
            }
          }
        } else {
          if (peerMediaStream.id != null) {
            peerMediaStreams[peerMediaStream.id!] = peerMediaStream;
          }
        }
      }
    }
    return peerMediaStreams;
  }

  Map<String, MediaStream> getMediaStreams({String? peerId, String? clientId}) {
    Map<String, PeerMediaStream> peerMediaStreams =
        getPeerMediaStreams(peerId: peerId, clientId: clientId);
    Map<String, MediaStream> streams = {};
    if (peerMediaStreams.isNotEmpty) {
      for (var stream in peerMediaStreams.values) {
        var mediaStream = stream.mediaStream;
        if (mediaStream != null) {
          streams[mediaStream.id] = mediaStream;
        }
      }
    }
    return streams;
  }

  ///增加peerMediaStream，激活add事件
  add(PeerMediaStream peerMediaStream) {
    var id = peerMediaStream.id;
    if (id != null && !peerMediaStreams.containsKey(id)) {
      peerMediaStreams[id] = peerMediaStream;
      onPeerMediaStreamOperator(
          PeerMediaStreamOperator.add.name, peerMediaStream);
    }
  }

  ///移除视频渲染器和流，激活remove事件
  remove(PeerMediaStream peerMediaStream) async {
    var streamId = peerMediaStream.id;
    if (streamId != null && peerMediaStreams.containsKey(streamId)) {
      peerMediaStreams.remove(streamId);
      if (_currentPeerMediaStream != null &&
          _currentPeerMediaStream!.id == streamId) {
        _currentPeerMediaStream = null;
      }
      if (_mainPeerMediaStream != null &&
          _mainPeerMediaStream!.id == streamId) {
        _mainPeerMediaStream = null;
      }
      //在流被关闭前调用事件处理
      await onPeerMediaStreamOperator(
          PeerMediaStreamOperator.remove.name, peerMediaStream);
    }
  }

  ///关闭渲染器和流
  close(PeerMediaStream peerMediaStream) async {
    await remove(peerMediaStream);
    await peerMediaStream.close();
  }

  ///移除并且关闭控制器所有的视频，激活exit事件
  exit() async {
    //先移除，后关闭
    var peerMediaStreams = this.peerMediaStreams.values.toList();
    this.peerMediaStreams.clear();
    for (var peerMediaStream in peerMediaStreams) {
      await peerMediaStream.close();
    }
    _currentPeerMediaStream = null;
    _mainPeerMediaStream = null;
    await onPeerMediaStreamOperator(PeerMediaStreamOperator.exit.name, null);
  }
}

///本地媒体控制器
class LocalPeerMediaStreamController extends PeerMediaStreamController {
  ///创建本地的Video stream，设置当前PeerMediaStream，激活create和add监听事件
  Future<PeerMediaStream> createPeerVideoStream({
    bool audio = true,
    double width = 640,
    double height = 480,
    int frameRate = 30,
  }) async {
    PeerMediaStream peerMediaStream = PeerMediaStream();
    await peerMediaStream.buildVideoMedia(
      myself.peerId!,
      clientId: myself.clientId,
      name: myself.myselfPeer.name,
      audio: audio,
      width: width,
      height: height,
      frameRate: frameRate,
    );
    onPeerMediaStreamOperator(
        PeerMediaStreamOperator.create.name, _mainPeerMediaStream);
    mainPeerMediaStream = peerMediaStream;

    return peerMediaStream;
  }

  ///创建本地的Audio stream，设置当前PeerMediaStream，激活create和add监听事件
  Future<PeerMediaStream> createPeerAudioStream() async {
    PeerMediaStream peerMediaStream = PeerMediaStream();
    await peerMediaStream.buildAudioMedia(
      myself.peerId!,
      clientId: myself.clientId,
      name: myself.myselfPeer.name,
    );
    onPeerMediaStreamOperator(
        PeerMediaStreamOperator.create.name, _mainPeerMediaStream);
    mainPeerMediaStream = peerMediaStream;

    return peerMediaStream;
  }

  ///创建本地的Display stream，激活create和add监听事件
  Future<PeerMediaStream> createPeerDisplayStream({
    DesktopCapturerSource? selectedSource,
    bool audio = false,
  }) async {
    PeerMediaStream peerMediaStream = PeerMediaStream();
    await peerMediaStream.buildDisplayMedia(myself.peerId!,
        clientId: myself.clientId,
        name: myself.myselfPeer.name,
        selectedSource: selectedSource,
        audio: audio);
    onPeerMediaStreamOperator(
        PeerMediaStreamOperator.create.name, peerMediaStream);
    add(peerMediaStream);

    return peerMediaStream;
  }

  ///创建本地的Stream stream，激活add监听事件
  Future<PeerMediaStream> createPeerMediaStream(
    MediaStream stream,
  ) async {
    var streamId = stream.id;
    PeerMediaStream? peerMediaStream = peerMediaStreams[streamId];
    if (peerMediaStream != null) {
      return peerMediaStream;
    }
    peerMediaStream = PeerMediaStream();
    await peerMediaStream.buildMediaStream(
      stream,
      myself.peerId!,
      clientId: myself.clientId,
      name: myself.myselfPeer.name,
    );
    onPeerMediaStreamOperator(
        PeerMediaStreamOperator.create.name, peerMediaStream);
    add(peerMediaStream);

    return peerMediaStream;
  }

  ///在会议创建后，自动创建本地视频，如果存在则直接返回
  openLocalMainPeerMediaStream(bool video) async {
    //如果本地主视频存在，直接返回
    if (mainPeerMediaStream != null) {
      return;
    }
    //根据conference.video来判断是请求音频还是视频，并创建本地视频stream
    if (video) {
      await localPeerMediaStreamController.createPeerVideoStream();
      //测试目的，使用屏幕
      // await localPeerMediaStreamController.createDisplayMediaStream();
    } else {
      await localPeerMediaStreamController.createPeerAudioStream();
    }
  }

  ///关闭本地特定的流
  @override
  close(PeerMediaStream peerMediaStream) async {
    await super.close(peerMediaStream);
    if (mainPeerMediaStream != null &&
        peerMediaStream.id == mainPeerMediaStream!.id) {
      mainPeerMediaStream = null;
    }
  }

  ///关闭本地所有的流，激活exit事件
  @override
  exit() async {
    await super.exit();
    mainPeerMediaStream = null;
  }
}

///本地视频流的控制器，本地流操作会触发事件，不涉及webrtc的连接对应的操作
final LocalPeerMediaStreamController localPeerMediaStreamController =
    LocalPeerMediaStreamController();
