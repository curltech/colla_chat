import 'dart:typed_data';

import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../provider/app_data_provider.dart';
import '../../tool/util.dart';

class SignalExtension {
  late String peerId;
  late String clientId;
  String? name;
  Room? room;
  List<Map<String, String>>? iceServers;

  SignalExtension(this.peerId, this.clientId,
      {this.name, this.room, this.iceServers});

  SignalExtension.fromJson(Map json) {
    peerId = json['peerId'];
    clientId = json['clientId'];
    name = json['name'];
    Map<String, dynamic>? room = json['room'];
    if (room != null) {
      this.room = Room(room['roomId'],
          id: room['id'],
          type: room['type'],
          action: room['action'],
          identity: room['identity']);
    }
    var iceServers = json['iceServers'];
    if (iceServers != null) {
      if (iceServers is List && iceServers.isNotEmpty) {
        if (this.iceServers == null) {
          this.iceServers = [];
        }
        for (var iceServer in iceServers) {
          for (var entry in (iceServer as Map).entries) {
            this.iceServers!.add({entry.key: entry.value});
          }
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json.addAll({
      'peerId': peerId,
      'clientId': clientId,
      'name': name,
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
  String? clientId;
  dynamic data;

  WebrtcEvent(this.peerId, {this.clientId, this.data});
}

///基础的PeerConnection之上加入了业务的编号，peerId和clientId，自动进行信号的协商
class AdvancedPeerConnection {
  late BasePeerConnection basePeerConnection;

  //对方的参数
  //主叫创建的时候，一般clientId为空，需要在后面填写
  //作为被叫的时候，clientId是有值的
  String peerId;
  String? clientId;
  String? name;
  String? connectPeerId;
  String? connectSessionId;
  List<Map<String, String>>? iceServers = [];
  Room? room;
  int? start;
  int? end;

  AdvancedPeerConnection(this.peerId, bool initiator,
      {this.clientId, this.name, this.room}) {
    if (initiator) {
      final basePeerConnection = MasterPeerConnection();
      this.basePeerConnection = basePeerConnection;
    } else {
      if (StringUtil.isEmpty(clientId)) {
        logger.e('SlavePeerConnection clientId must be value');
      }
      final basePeerConnection = SlavePeerConnection();
      this.basePeerConnection = basePeerConnection;
    }
  }

  Future<bool> init(
      {bool getUserMedia = false,
      List<MediaStream> streams = const [],
      List<Map<String, String>>? iceServers}) async {
    start = DateTime.now().millisecondsSinceEpoch;
    var myselfPeerId = myself.peerId;
    var myselfClientId = myself.clientId;
    var myselfName = myself.myselfPeer!.name;
    SignalExtension extension;
    if (myselfPeerId != null && myselfClientId != null) {
      extension = SignalExtension(myselfPeerId, myselfClientId,
          name: myselfName, room: room, iceServers: iceServers);
    } else {
      logger.e('myself peerId or clientId is null');
      return false;
    }
    bool result = await basePeerConnection.init(
        getUserMedia: getUserMedia, streams: streams, extension: extension);
    if (!result) {
      logger.e('WebrtcCorePeer init result is false');
      return false;
    }

    ///所有basePeerConnection的事件都缺省转发到peerConnectionPool相同的处理
    //触发basePeerConnection的signal事件，就是调用peerConnectionPool对应的signal方法
    basePeerConnection.on(WebrtcEventType.signal, (WebrtcSignal signal) async {
      await peerConnectionPool
          .signal(WebrtcEvent(peerId, clientId: clientId, data: signal));
    });

    //触发basePeerConnection的connect事件，就是调用peerConnectionPool对应的signal方法
    basePeerConnection.on(WebrtcEventType.connected, (data) async {
      end = DateTime.now().millisecondsSinceEpoch;
      if (end != null && start != null) {
        var interval = end! - start!;
        logger.i('connect time:$interval');
      }
      await peerConnectionPool
          .onConnected(WebrtcEvent(peerId, clientId: clientId));
    });

    basePeerConnection.on(WebrtcEventType.closed, (data) async {
      await peerConnectionPool
          .onClosed(WebrtcEvent(peerId, clientId: clientId));
    });

    //收到数据
    basePeerConnection.on(WebrtcEventType.message, (data) async {
      logger.i('${DateTime.now().toUtc()}:got a message from peer');
      await peerConnectionPool
          .onMessage(WebrtcEvent(peerId, clientId: clientId, data: data));
    });

    basePeerConnection.on(WebrtcEventType.stream, (stream) async {
      if (stream != null) {
        stream.onremovetrack = (event) {
          logger.i('Video track: ${event.track.label} removed');
        };
      }
      await peerConnectionPool
          .onStream(WebrtcEvent(peerId, clientId: clientId, data: stream));
    });

    basePeerConnection.on(WebrtcEventType.track, (track, stream) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:track');
      await peerConnectionPool.onTrack(WebrtcEvent(peerId,
          clientId: clientId, data: {'track': track, 'stream': stream}));
    });

    basePeerConnection.on(WebrtcEventType.error, (err) async {
      await peerConnectionPool
          .onError(WebrtcEvent(peerId, clientId: clientId, data: err));
    });

    return result;
  }

  addStream(MediaStream stream) {
    logger.i('add stream to webrtc');
    basePeerConnection.addStream(stream);
  }

  removeStream(MediaStream stream) {
    removeLocalStream(stream);
    removeRemoteStream(stream);
  }

  ///
  removeLocalStream(MediaStream stream) {
    for (var render_ in basePeerConnection.localVideoRenders) {
      if (render_.mediaStream == stream) {
        render_.dispose();
        basePeerConnection.localVideoRenders.remove(render_);
        break;
      }
    }
  }

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

  Future<void> send(Uint8List data) async{
    if (connected) {
      return await basePeerConnection.send(data);
    } else {
      logger.e(
          'send failed , peerId:$peerId;connectPeer:$connectPeerId session:$connectSessionId webrtc connection state is not connected');
      return;
    }
  }

  close() async {
    await basePeerConnection.close();
  }
}
