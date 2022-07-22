import 'dart:typed_data';

import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../provider/app_data_provider.dart';

class SignalExtension {
  late String peerId;
  late String clientId;
  Router? router;
  List<Map<String, String>>? iceServers;

  SignalExtension(this.peerId, this.clientId, {this.router, this.iceServers});

  SignalExtension.fromJson(Map json) {
    peerId = json['peerId'];
    clientId = json['clientId'];
    Map<String, dynamic> router = json['router'];
    this.router = Router(router['roomId'],
        id: router['id'],
        type: router['type'],
        action: router['action'],
        identity: router['identity']);
    iceServers = json['iceServers'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json.addAll({
      'peerId': peerId,
      'clientId': clientId,
      'iceServers': iceServers,
    });
    var router = this.router;
    if (router != null) {
      json['router'] = router.toJson();
    }
    return json;
  }
}

class WebrtcEvent {
  String peerId;
  String clientId;
  dynamic data;

  WebrtcEvent(this.peerId, this.clientId, {this.data});
}

///核心的Peer之上加入了业务的编号，peerId和clientId
class PeerConnection {
  late BasePeerConnection peerConnection;

  //对方的参数
  late String peerId;
  late String clientId;
  String? connectPeerId;
  String? connectSessionId;
  List<Map<String, String>>? iceServers = [];
  List<MediaStream> localStreams = [];
  List<MediaStream> remoteStreams = [];
  Router? router;
  int? start;
  int? end;

  PeerConnection();

  Future<bool> init(String peerId, String clientId, bool initiator,
      {List<MediaStream> streams = const [],
      List<Map<String, String>>? iceServers,
      Router? router}) async {
    this.peerId = peerId;
    this.clientId = clientId;
    this.router = router;
    var appDataProvider = AppDataProvider.instance;
    if (iceServers == null) {
      this.iceServers = appDataProvider.defaultNodeAddress.iceServers;
    } else {
      this.iceServers = iceServers;
    }
    if (streams != null) {
      localStreams.addAll(streams);
    }
    // 自定义属性，表示本节点createOffer时加入的sfu的编号，作为出版者还是订阅者，还是都是
    this.router = router;
    start = DateTime.now().millisecondsSinceEpoch;
    var myselfPeerId = myself.peerId;
    var myselfClientId = myself.clientId;
    SignalExtension extension;
    if (myselfPeerId != null && myselfClientId != null) {
      extension = SignalExtension(myselfPeerId, myselfClientId,
          router: router, iceServers: iceServers);
    } else {
      logger.e('myself peerId or clientId is null');
      return false;
    }
    bool result = false;
    if (initiator) {
      this.peerConnection = MasterPeerConnection();
      final peerConnection = this.peerConnection;
      if (peerConnection != null) {
        result =
            await peerConnection.init(streams: streams, extension: extension);
      }
    } else {
      this.peerConnection = FollowPeerConnection();
      final peerConnection = this.peerConnection;
      if (peerConnection != null) {
        result =
            await peerConnection.init(streams: streams, extension: extension);
      }
    }
    if (!result) {
      logger.e('WebrtcCorePeer init result is false');
      return false;
    }
    //下面的三个事件对于发起方和被发起方是一样的
    //可以发起信号
    final peerConnection = this.peerConnection;
    peerConnection.on(WebrtcEventType.signal, (WebrtcSignal signal) async {
      await peerConnectionPool.emit(WebrtcEventType.signal.name,
          WebrtcEvent(peerId, clientId, data: signal));
    });

    //连接建立/
    peerConnection.on(WebrtcEventType.connect, (data) async {
      end = DateTime.now().millisecondsSinceEpoch;
      if (end != null && start != null) {
        var interval = end! - start!;
        logger.i('connect time:$interval');
      }
      await peerConnectionPool.emit(
          WebrtcEventType.connect.name, WebrtcEvent(peerId, clientId));
    });

    peerConnection.on(WebrtcEventType.close, (data) async {
      if (this.peerId != null) {
        await peerConnectionPool.remove(this.peerId!);
      }
    });

    //收到数据
    peerConnection.on(WebrtcEventType.data, (data) async {
      logger.i('${DateTime.now().toUtc()}:got a message from peer: $data');
      await peerConnectionPool.emit(
          WebrtcEventType.data.name, WebrtcEvent(peerId, clientId, data: data));
    });

    peerConnection.on(WebrtcEventType.stream, (stream) async {
      remoteStreams.add(stream);
      if (stream != null) {
        stream.onremovetrack = (event) {
          logger.i('Video track: ${event.track.label} removed');
        };
      }
      await peerConnectionPool.emit(WebrtcEventType.stream.name,
          WebrtcEvent(peerId, clientId, data: stream));
    });

    peerConnection.on(WebrtcEventType.track, (track, stream) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:track');
      await peerConnectionPool.emit(
          WebrtcEventType.track.name,
          WebrtcEvent(peerId, clientId,
              data: {'track': track, 'stream': stream}));
    });

    peerConnection.on(
        WebrtcEventType.error, (err) => {logger.e('webrtcPeerError:$err')});

    return result;
  }

  on(WebrtcEventType name, Function(dynamic)? fn) {
    peerConnection.on(name, fn);
  }

  RTCVideoView attachStream(MediaStream stream) {
    var renderer = RTCVideoRenderer();
    renderer.initialize();
    renderer.srcObject = stream;
    return RTCVideoView(renderer);
  }

  addStream(MediaStream stream) {
    logger.i('add stream to webrtc');
    peerConnection.addStream(stream);
    localStreams.add(stream);
  }

  ///
  removeStream(MediaStream stream) {
    removeLocalStream(stream);
    removeRemoteStream(stream);
  }

  ///
  removeLocalStream(MediaStream stream) {
    int i = 0;
    for (var stream_ in localStreams) {
      if (stream_ == stream) {
        localStreams.remove(stream_);
        peerConnection.removeStream(stream_);
      }
    }
  }

  ///
  removeRemoteStream(MediaStream stream) {
    for (var stream_ in localStreams) {
      if (stream_ == stream) {
        remoteStreams.remove(stream_);
      }
    }
  }

  signal(WebrtcSignal signal) {
    peerConnection.signal(signal);
  }

  bool get connected {
    return peerConnection.connected;
  }

  send(Uint8List data) {
    if (peerConnection.connected) {
      peerConnection.send(data);
    } else {
      logger.e(
          'send failed , peerId:$peerId;connectPeer:$connectPeerId session:$connectSessionId webrtc connection state is not connected');
    }
  }

  destroy(String err) async {
    await peerConnection.destroy(err);
  }
}
