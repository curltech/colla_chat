import 'dart:typed_data';

import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../provider/app_data_provider.dart';

class SignalExtension {
  late String peerId;
  late String clientId;
  Room? room;
  List<Map<String, String>>? iceServers;

  SignalExtension(this.peerId, this.clientId, {this.room, this.iceServers});

  SignalExtension.fromJson(Map json) {
    peerId = json['peerId'];
    clientId = json['clientId'];
    Map<String, dynamic> router = json['router'];
    room = Room(router['roomId'],
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
    var room = this.room;
    if (room != null) {
      json['room'] = room.toJson();
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

///基础的PeerConnection之上加入了业务的编号，peerId和clientId，自动进行信号的协商
class AdvancedPeerConnection {
  late BasePeerConnection basePeerConnection;

  //对方的参数
  late String peerId;
  late String clientId;
  String? connectPeerId;
  String? connectSessionId;
  List<Map<String, String>>? iceServers = [];
  Room? room;
  int? start;
  int? end;

  AdvancedPeerConnection();

  Future<bool> init(String peerId, String clientId, bool initiator,
      {bool getUserMedia = false,
      List<MediaStream> streams = const [],
      List<Map<String, String>>? iceServers,
      Room? room}) async {
    this.peerId = peerId;
    this.clientId = clientId;
    this.room = room;
    start = DateTime.now().millisecondsSinceEpoch;
    var myselfPeerId = myself.peerId;
    var myselfClientId = myself.clientId;
    SignalExtension extension;
    if (myselfPeerId != null && myselfClientId != null) {
      extension = SignalExtension(myselfPeerId, myselfClientId,
          room: room, iceServers: iceServers);
    } else {
      logger.e('myself peerId or clientId is null');
      return false;
    }
    bool result = false;
    if (initiator) {
      this.basePeerConnection = MasterPeerConnection();
      final basePeerConnection = this.basePeerConnection;
      result = await basePeerConnection.init(
          getUserMedia: getUserMedia, streams: streams, extension: extension);
    } else {
      this.basePeerConnection = SlavePeerConnection();
      final basePeerConnection = this.basePeerConnection;
      result = await basePeerConnection.init(
          getUserMedia: getUserMedia, streams: streams, extension: extension);
    }
    if (!result) {
      logger.e('WebrtcCorePeer init result is false');
      return false;
    }
    //下面的三个事件对于发起方和被发起方是一样的
    //可以发起信号
    final basePeerConnection = this.basePeerConnection;
    basePeerConnection.on(WebrtcEventType.signal, (WebrtcSignal signal) async {
      await peerConnectionPool.emit(
          WebrtcEventType.signal, WebrtcEvent(peerId, clientId, data: signal));
    });

    //连接建立
    basePeerConnection.on(WebrtcEventType.connect, (data) async {
      end = DateTime.now().millisecondsSinceEpoch;
      if (end != null && start != null) {
        var interval = end! - start!;
        logger.i('connect time:$interval');
      }
      await peerConnectionPool.emit(
          WebrtcEventType.connect, WebrtcEvent(peerId, clientId));
    });

    basePeerConnection.on(WebrtcEventType.close, (data) async {
      await peerConnectionPool.remove(this.peerId);
    });

    //收到数据
    basePeerConnection.on(WebrtcEventType.message, (data) async {
      logger.i('${DateTime.now().toUtc()}:got a message from peer: $data');
      await peerConnectionPool.emit(
          WebrtcEventType.message, WebrtcEvent(peerId, clientId, data: data));
    });

    basePeerConnection.on(WebrtcEventType.stream, (stream) async {
      if (stream != null) {
        stream.onremovetrack = (event) {
          logger.i('Video track: ${event.track.label} removed');
        };
      }
      await peerConnectionPool.emit(
          WebrtcEventType.stream, WebrtcEvent(peerId, clientId, data: stream));
    });

    basePeerConnection.on(WebrtcEventType.track, (track, stream) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:track');
      await peerConnectionPool.emit(
          WebrtcEventType.track,
          WebrtcEvent(peerId, clientId,
              data: {'track': track, 'stream': stream}));
    });

    basePeerConnection.on(
        WebrtcEventType.error, (err) => {logger.e('webrtcPeerError:$err')});

    return result;
  }

  on(WebrtcEventType name, Function(dynamic)? fn) {
    basePeerConnection.on(name, fn);
  }

  addStream(MediaStream stream) {
    logger.i('add stream to webrtc');
    basePeerConnection.addStream(stream);
  }

  ///
  removeStream(MediaStream stream) {
    removeLocalStream(stream);
    removeRemoteStream(stream);
  }

  ///
  removeLocalStream(MediaStream stream) {
    int i = 0;
    for (var render_ in basePeerConnection.localVideoRenders) {
      if (render_.mediaStream == stream) {
        render_.dispose();
        basePeerConnection.localVideoRenders.remove(render_);
        break;
      }
    }
  }

  ///
  removeRemoteStream(MediaStream stream) {
    for (var render_ in basePeerConnection.remoteVideoRenders) {
      if (render_.mediaStream == stream) {
        render_.dispose();
        basePeerConnection.remoteVideoRenders.remove(render_);
        break;
      }
    }
  }

  onSignal(WebrtcSignal signal) {
    basePeerConnection.onSignal(signal);
  }

  bool get connected {
    return basePeerConnection.status == PeerConnectionStatus.connected;
  }

  send(Uint8List data) {
    if (connected) {
      basePeerConnection.send(data);
    } else {
      logger.e(
          'send failed , peerId:$peerId;connectPeer:$connectPeerId session:$connectSessionId webrtc connection state is not connected');
    }
  }

  close() async {
    await basePeerConnection.close();

  }
}
