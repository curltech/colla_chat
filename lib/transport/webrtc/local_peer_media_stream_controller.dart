import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:synchronized/synchronized.dart';

///媒体控制器，内部是PeerMediaStream的集合，以流的id为key
///LocalPeerMediaStreamController和RemotePeerMediaStreamController是其子类，
///前者代表本地的视频和音频的总共只能有一个，屏幕共享和媒体播放可以有多个
///后者代表远程的视频，包含所有的远程视频流的PeerMediaStream
class PeerMediaStreamController with ChangeNotifier {
  //当前选择的界面渲染器
  PeerMediaStream? _currentPeerMediaStream;

  //媒体流集合，所有的视频流，包括本地和远程
  final Map<String, PeerMediaStream> _peerMediaStreams = {};

  //媒体流集合的操作锁
  final Lock _streamLock = Lock();

  PeerMediaStreamController(
      {List<PeerMediaStream> peerMediaStreams = const []}) {
    if (peerMediaStreams.isNotEmpty) {
      for (var peerMediaStream in peerMediaStreams) {
        add(peerMediaStream);
      }
    }
  }

  ///获取当前媒体流
  PeerMediaStream? get currentPeerMediaStream {
    return _currentPeerMediaStream;
  }

  ///设置当前媒体流
  set currentPeerMediaStream(PeerMediaStream? currentPeerMediaStream) {
    if (_currentPeerMediaStream != currentPeerMediaStream) {
      _currentPeerMediaStream = currentPeerMediaStream;
      notifyListeners();
    }
  }

  ///获取所有的remote媒体流的列表
  List<PeerMediaStream> get peerMediaStreams {
    return [..._peerMediaStreams.values];
  }

  ///根据peerId筛选，获取相应的Peer媒体流的集合
  List<PeerMediaStream> getPeerMediaStreams(String peerId, {String? clientId}) {
    List<PeerMediaStream> peerMediaStreams = [];
    for (var peerMediaStream in _peerMediaStreams.values) {
      if (peerId == peerMediaStream.platformParticipant?.peerId) {
        if (clientId != null) {
          if (clientId == peerMediaStream.platformParticipant?.clientId) {
            if (peerMediaStream.id != null) {
              peerMediaStreams.add(peerMediaStream);
            }
          }
        } else {
          if (peerMediaStream.id != null) {
            peerMediaStreams.add(peerMediaStream);
          }
        }
      }
    }
    return peerMediaStreams;
  }

  ///根据peerId筛选，获取相应的原生的媒体流的集合
  List<MediaStream> getMediaStreams(String peerId, {String? clientId}) {
    List<PeerMediaStream> peerMediaStreams =
        getPeerMediaStreams(peerId, clientId: clientId);
    List<MediaStream> streams = [];
    if (peerMediaStreams.isNotEmpty) {
      for (var stream in peerMediaStreams) {
        var mediaStream = stream.mediaStream;
        if (mediaStream != null) {
          streams.add(mediaStream);
        }
      }
    }
    return streams;
  }

  ///根据流编号获取相应的媒体流
  Future<PeerMediaStream?> getPeerMediaStream(String streamId) async {
    return await _streamLock.synchronized(() {
      return _peerMediaStreams[streamId];
    });
  }

  ///如果不存在，增加peerMediaStream，激活add事件
  add(PeerMediaStream peerMediaStream) async {
    await _streamLock.synchronized(() {
      var id = peerMediaStream.id;
      if (id != null && !_peerMediaStreams.containsKey(id)) {
        _peerMediaStreams[id] = peerMediaStream;
        notifyListeners();
      }
    });
  }

  ///移除媒体流，如果是当前媒体流，则设置当前的媒体流为null，激活remove事件
  Future<PeerMediaStream?> remove(String streamId) async {
    return await _streamLock.synchronized(() async {
      PeerMediaStream? peerMediaStream = _peerMediaStreams[streamId];
      if (peerMediaStream != null) {
        _peerMediaStreams.remove(streamId);
        if (_currentPeerMediaStream != null &&
            _currentPeerMediaStream!.id == streamId) {
          _currentPeerMediaStream = null;
        }
        notifyListeners();
      }
      return peerMediaStream;
    });
  }

  ///关闭指定流并且从集合中删除
  close(String streamId) async {
    PeerMediaStream? peerMediaStream = await remove(streamId);
    if (peerMediaStream != null) {
      //在windows平台上关闭远程流似乎会崩溃，可以注释后进行测试
      if (_currentPeerMediaStream != null &&
          _currentPeerMediaStream!.id == streamId) {
        _currentPeerMediaStream = null;
      }
      await peerMediaStream.close();
      notifyListeners();
    }
  }

  ///移除并且关闭控制器所有的媒体流，激活exit事件
  closeAll() async {
    await _streamLock.synchronized(() async {
      _currentPeerMediaStream = null;
      //先移除，后关闭
      List<PeerMediaStream> peerMediaStreams = [..._peerMediaStreams.values];
      for (var peerMediaStream in peerMediaStreams) {
        await peerMediaStream.close();
      }
      _peerMediaStreams.clear();
      notifyListeners();
    });
  }

  replace(Map<String, PeerMediaStream> peerMediaStreams) async {
    await _streamLock.synchronized(() async {
      _currentPeerMediaStream = null;
      _peerMediaStreams.clear();
      _peerMediaStreams.addAll(peerMediaStreams);
      notifyListeners();
    });
  }
}

///本地媒体控制器
class LocalPeerMediaStreamController extends PeerMediaStreamController {
  //主视频对应的界面渲染器
  PeerMediaStream? _mainPeerMediaStream;

  ///主媒体流
  PeerMediaStream? get mainPeerMediaStream {
    return _mainPeerMediaStream;
  }

  ///设置主媒体流，替换掉主媒体流
  set mainPeerMediaStream(PeerMediaStream? mainPeerMediaStream) {
    if (_mainPeerMediaStream != mainPeerMediaStream) {
      _mainPeerMediaStream = mainPeerMediaStream;
      notifyListeners();
    }
  }

  ///判断主媒体流是否有视频
  bool get video {
    if (_mainPeerMediaStream != null) {
      return _mainPeerMediaStream!.video;
    }
    return false;
  }

  /// 创建本地的主Video render，支持视频和音频的切换，设置当前videoChatRender，激活create。add和remove监听事件
  Future<PeerMediaStream> createMainPeerMediaStream(
      {bool video = true, bool sfu = false}) async {
    ///本地视频不存在，可以直接创建，并发送视频邀请消息，否则根据情况觉得是否音视频切换
    if (mainPeerMediaStream == null) {
      if (video) {
        if (sfu) {
          mainPeerMediaStream = await PeerMediaStream.createLocalVideoTrack();
        } else {
          mainPeerMediaStream = await PeerMediaStream.createLocalVideoMedia();
        }
      } else {
        if (sfu) {
          mainPeerMediaStream = await PeerMediaStream.createLocalAudioTrack();
        } else {
          mainPeerMediaStream = await PeerMediaStream.createLocalAudioMedia();
        }
      }
      add(mainPeerMediaStream!);
    }

    return mainPeerMediaStream!;
  }

  ///创建本地的Display stream，激活create和add监听事件
  Future<PeerMediaStream> createPeerDisplayStream(
      {DesktopCapturerSource? selectedSource,
      bool audio = false,
      bool sfu = false}) async {
    PeerMediaStream peerMediaStream;
    if (sfu) {
      peerMediaStream = await PeerMediaStream.createLocalScreenShareTrack(
          sourceId: selectedSource?.id, audio: audio);
    } else {
      peerMediaStream = await PeerMediaStream.createLocalDisplayMedia(
          selectedSource: selectedSource, audio: audio);
    }
    add(peerMediaStream);

    return peerMediaStream;
  }

  ///创建本地的Stream，激活add监听事件
  Future<PeerMediaStream> createPeerMediaStream({
    MediaStream? mediaStream,
    VideoTrack? videoTrack,
  }) async {
    String streamId = '';
    if (mediaStream != null) {
      streamId = mediaStream.id;
    }
    if (videoTrack != null) {
      streamId = videoTrack.mediaStream.id;
    }
    PeerMediaStream? peerMediaStream = _peerMediaStreams[streamId];
    if (peerMediaStream != null) {
      return peerMediaStream;
    }
    peerMediaStream = await PeerMediaStream.createPeerMediaStream(
      peerId: myself.peerId!,
      mediaStream: mediaStream,
      videoTrack: videoTrack,
      clientId: myself.clientId,
      name: myself.myselfPeer.name,
    );
    add(peerMediaStream);

    return peerMediaStream;
  }

  ///关闭本地特定的流
  @override
  close(String streamId) async {
    if (_mainPeerMediaStream != null && streamId == _mainPeerMediaStream!.id) {
      _mainPeerMediaStream = null;
    }
    await super.close(streamId);
  }

  ///关闭本地所有的流
  @override
  closeAll() async {
    _mainPeerMediaStream = null;
    await super.closeAll();
  }
}

///本地视频流的控制器，本地流操作会触发事件，不涉及webrtc的连接对应的操作
final LocalPeerMediaStreamController localPeerMediaStreamController =
    LocalPeerMediaStreamController();
