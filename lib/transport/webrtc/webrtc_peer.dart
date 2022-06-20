import 'dart:typed_data';

import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/transport/webrtc/webrtc_core_peer.dart';
import 'package:colla_chat/transport/webrtc/webrtcpeerpool.dart';
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
class WebrtcPeer {
  late WebrtcCorePeer webrtcCorePeer;

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

  WebrtcPeer();

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
      webrtcCorePeer = MasterWebrtcCorePeer();
      final webrtcPeer = this.webrtcCorePeer;
      if (webrtcPeer != null) {
        result = await webrtcPeer.init(streams: streams, extension: extension);
      }
    } else {
      this.webrtcCorePeer = FollowWebrtcCorePeer();
      final webrtcPeer = this.webrtcCorePeer;
      if (webrtcPeer != null) {
        result = await webrtcPeer.init(streams: streams, extension: extension);
      }
    }
    if (!result) {
      logger.e('WebrtcCorePeer init result is false');
      return false;
    }
    //下面的三个事件对于发起方和被发起方是一样的
    //可以发起信号
    final webrtcPeer = this.webrtcCorePeer;
    webrtcPeer.on(WebrtcEventType.signal, (WebrtcSignal signal) async {
      await WebrtcPeerPool.instance.emit(WebrtcEventType.signal.name,
          WebrtcEvent(peerId, clientId, data: signal));
    });

    //连接建立/
    webrtcPeer.on(WebrtcEventType.connect, (data) async {
      end = DateTime.now().millisecondsSinceEpoch;
      if (end != null && start != null) {
        var interval = end! - start!;
        logger.i('connect time:$interval');
      }
      await WebrtcPeerPool.instance
          .emit(WebrtcEventType.connect.name, WebrtcEvent(peerId, clientId));
    });

    webrtcPeer.on(WebrtcEventType.close, (data) async {
      if (this.peerId != null) {
        await WebrtcPeerPool.instance.remove(this.peerId!);
      }
    });

    //收到数据
    webrtcPeer.on(WebrtcEventType.data, (data) async {
      logger.i('${DateTime.now().toUtc()}:got a message from peer: $data');
      await WebrtcPeerPool.instance.emit(
          WebrtcEventType.data.name, WebrtcEvent(peerId, clientId, data: data));
    });

    webrtcPeer.on(WebrtcEventType.stream, (stream) async {
      remoteStreams.add(stream);
      if (stream != null) {
        stream.onremovetrack = (event) {
          logger.i('Video track: ${event.track.label} removed');
        };
      }
      await WebrtcPeerPool.instance.emit(WebrtcEventType.stream.name,
          WebrtcEvent(peerId, clientId, data: stream));
    });

    webrtcPeer.on(WebrtcEventType.track, (track, stream) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:track');
      await WebrtcPeerPool.instance.emit(
          WebrtcEventType.track.name,
          WebrtcEvent(peerId, clientId,
              data: {'track': track, 'stream': stream}));
    });

    webrtcPeer.on(
        WebrtcEventType.error, (err) => {logger.e('webrtcPeerError:$err')});

    return result;
  }

  on(WebrtcEventType name, Function(dynamic)? fn) {
    webrtcCorePeer.on(name, fn);
  }

  RTCVideoView attachStream(MediaStream stream) {
    var renderer = RTCVideoRenderer();
    renderer.initialize();
    renderer.srcObject = stream;
    return RTCVideoView(renderer);
  }

  addStream(MediaStream stream) {
    logger.i('add stream to webrtc');
    webrtcCorePeer.addStream(stream);
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
    for (var _stream in localStreams) {
      if (_stream == stream) {
        localStreams.remove(_stream);
        webrtcCorePeer.removeStream(_stream);
      }
    }
  }

  ///
  removeRemoteStream(MediaStream stream) {
    for (var _stream in localStreams) {
      if (_stream == stream) {
        remoteStreams.remove(_stream);
      }
    }
  }

  signal(WebrtcSignal signal) {
    webrtcCorePeer.signal(signal);
  }

  bool get connected {
    return webrtcCorePeer.connected;
  }

  send(Uint8List data) {
    if (webrtcCorePeer.connected) {
      webrtcCorePeer.send(data);
    } else {
      logger.e(
          'send failed , peerId:$peerId;connectPeer:$connectPeerId session:$connectSessionId webrtc connection state is not connected');
    }
  }

  destroy(String err) async {
    await webrtcCorePeer.destroy(err);
  }
}
