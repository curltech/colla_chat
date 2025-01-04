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
  final key = UniqueKey();

  //当前选择的界面渲染器
  String? _currentPeerId;

  //媒体流集合，所有的视频流，包括本地和远程，映射的键值peerId
  final Map<String, List<PeerMediaStream>> _peerMediaStreams = {};

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
  String? get currentPeerId {
    return _currentPeerId;
  }

  List<PeerMediaStream>? get currentPeerMediaStreams {
    return _peerMediaStreams[_currentPeerId];
  }

  ///设置当前媒体流
  set currentPeerId(String? currentPeerId) {
    if (_currentPeerId != currentPeerId) {
      _currentPeerId = currentPeerId;
      notifyListeners();
    }
  }

  ///获取所有的remote媒体流的列表
  Map<String, List<PeerMediaStream>> get peerMediaStreams {
    return _peerMediaStreams;
  }

  ///根据peerId筛选，获取相应的Peer媒体流的集合
  List<PeerMediaStream> getPeerMediaStreams(String peerId) {
    List<PeerMediaStream>? peerMediaStreams = _peerMediaStreams[peerId];
    if (peerMediaStreams != null) {
      return peerMediaStreams;
    }
    return [];
  }

  ///根据peerId筛选，获取相应的原生的媒体流的集合
  List<MediaStream> getMediaStreams(String peerId) {
    List<PeerMediaStream> peerMediaStreams = getPeerMediaStreams(peerId);
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

  _add(PeerMediaStream peerMediaStream) async {
    var peerId = peerMediaStream.platformParticipant?.peerId;
    if (peerId != null) {
      if (!_peerMediaStreams.containsKey(peerId)) {
        _peerMediaStreams[peerId] = [peerMediaStream];

        return true;
      } else {
        List<PeerMediaStream> peerMediaStreams = _peerMediaStreams[peerId]!;
        if (!peerMediaStreams.contains(peerMediaStream)) {
          peerMediaStreams.add(peerMediaStream);
          return true;
        }
      }
    }

    return false;
  }

  /// 如果不存在，增加peerMediaStream，激活add事件
  add(PeerMediaStream peerMediaStream, {bool notify = true}) async {
    bool success = await _streamLock.synchronized(() async {
      return await _add(peerMediaStream);
    });

    if (success && notify) {
      notifyListeners();
    }
  }

  addRemoteTrack(RemoteTrack track, RemoteParticipant remoteParticipant,
      {bool notify = true}) async {
    bool changed = false;
    var peerId = remoteParticipant.identity;
    List<PeerMediaStream>? pmss = _peerMediaStreams[peerId];
    if (pmss != null) {
      for (PeerMediaStream pms in pmss) {
        if (pms.mediaStream == null) {
          if (pms.videoTrack == null) {
            if (track is RemoteVideoTrack) {
              pms.videoTrack = track;
              changed = true;
              break;
            }
          }
          if (pms.audioTrack == null) {
            if (track is RemoteAudioTrack) {
              pms.audioTrack = track;
              changed = true;
              break;
            }
          }
        }
      }
    }
    if (!changed) {
      PeerMediaStream? peerMediaStream =
          await PeerMediaStream.createRemotePeerMediaStream(
              track, remoteParticipant);
      if (peerMediaStream != null) {
        await add(peerMediaStream, notify: notify);
      }
    } else {
      if (notify) {
        notifyListeners();
      }
    }
  }

  ///移除媒体流，如果是当前媒体流，则设置当前的媒体流为null，激活remove事件
  Future<bool> remove(PeerMediaStream peerMediaStream,
      {bool notify = true}) async {
    return await _streamLock.synchronized(() async {
      String? peerId = peerMediaStream.peerId;
      List<PeerMediaStream>? peerMediaStreams = _peerMediaStreams[peerId];
      if (peerMediaStreams != null) {
        bool success = peerMediaStreams.remove(peerMediaStream);
        if (success) {
          if (peerMediaStreams.isEmpty) {
            _peerMediaStreams.remove(peerId);
            if (_currentPeerId != null && _currentPeerId == peerId) {
              _currentPeerId = null;
            }
          }
          if (notify) {
            notifyListeners();
          }
        }
        return success;
      }
      return false;
    });
  }

  removeRemoteTrack(RemoteTrack track, RemoteParticipant remoteParticipant,
      {bool notify = true}) async {
    bool changed = false;
    var peerId = remoteParticipant.identity;
    List<PeerMediaStream>? pmss = _peerMediaStreams[peerId];

    if (pmss != null) {
      PeerMediaStream? delete;
      for (PeerMediaStream pms in pmss) {
        if (pms.mediaStream == null) {
          if (pms.videoTrack != null) {
            if (track is RemoteVideoTrack) {
              if (pms.videoTrack!.getCid() == track.getCid()) {
                pms.videoTrack!.stop();
                pms.videoTrack!.dispose();
                pms.videoTrack = null;
                changed = true;
              }
            }
          }
          if (pms.audioTrack != null) {
            if (track is RemoteAudioTrack) {
              if (pms.audioTrack!.getCid() == track.getCid()) {
                pms.audioTrack!.stop();
                pms.audioTrack!.dispose();
                pms.audioTrack = null;
                changed = true;
              }
            }
          }
        }
        if (pms.mediaStream == null &&
            pms.videoTrack == null &&
            pms.audioTrack == null) {
          delete = pms;
        }
        if (changed) {
          break;
        }
      }
      if (delete != null) {
        pmss.remove(delete);
        if (pmss.isEmpty) {
          _peerMediaStreams.remove(peerId);
        }
      }
    }
    if (changed) {
      if (notify) {
        notifyListeners();
      }
    }
  }

  Future<void> removeAll({String? peerId, bool notify = true}) async {
    return await _streamLock.synchronized(() async {
      if (peerId == null) {
        _peerMediaStreams.clear();
        if (notify) {
          notifyListeners();
        }
      } else {
        if (_peerMediaStreams.containsKey(peerId)) {
          _peerMediaStreams.remove(peerId);
          if (notify) {
            notifyListeners();
          }
        }
      }
    });
  }

  ///关闭指定流并且从集合中删除
  Future<bool> close(PeerMediaStream peerMediaStream) async {
    bool success = await remove(peerMediaStream);
    if (success) {
      await peerMediaStream.close();
    }

    return success;
  }

  ///移除并且关闭控制器所有的媒体流，激活exit事件
  closeAll() async {
    await _streamLock.synchronized(() async {
      _currentPeerId = null;
      for (var peerMediaStreams in _peerMediaStreams.values) {
        for (var peerMediaStream in peerMediaStreams) {
          await peerMediaStream.close();
        }
      }
      _peerMediaStreams.clear();

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

  ///关闭本地特定的流
  @override
  Future<bool> close(PeerMediaStream peerMediaStream) async {
    if (_mainPeerMediaStream != null &&
        _mainPeerMediaStream!.contain(peerMediaStream.id!)) {
      _mainPeerMediaStream = null;
    }
    return await super.close(peerMediaStream);
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
