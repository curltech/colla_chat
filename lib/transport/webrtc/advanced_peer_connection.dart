import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../provider/app_data_provider.dart';
import '../../service/p2p/security_context.dart';
import '../../service/servicelocator.dart';
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
  Room? room;

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
      {List<MediaStream> streams = const [],
      List<Map<String, String>>? iceServers}) async {
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
    bool result =
        await basePeerConnection.init(streams: streams, extension: extension);
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
      await peerConnectionPool
          .onConnected(WebrtcEvent(peerId, clientId: clientId));
    });

    basePeerConnection.on(WebrtcEventType.closed, (data) async {
      await peerConnectionPool
          .onClosed(WebrtcEvent(peerId, clientId: clientId));
    });

    //收到数据，带解密功能，取最后一位整数，表示解密选项，得到何种解密方式，然后解密
    basePeerConnection.on(WebrtcEventType.message, onMessage);

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

  addLocalStream(MediaStream stream) {
    logger.i('add stream to webrtc');
    basePeerConnection.addLocalStream(stream: stream);
  }

  removeStream(MediaStream stream) {
    basePeerConnection.removeStream(stream);
  }

  onSignal(WebrtcSignal signal) {
    basePeerConnection.onSignal(signal);
  }

  bool get connected {
    return basePeerConnection.status == PeerConnectionStatus.connected;
  }

  //收到数据，带解密功能，取最后一位整数，表示解密选项，得到何种解密方式，然后解密
  onMessage(Uint8List data) async {
    logger.i('${DateTime.now().toUtc()}:got a message from peer');
    int cryptOption = data[data.length - 1];
    SecurityContextService? securityContextService =
        ServiceLocator.securityContextServices[cryptOption];
    securityContextService =
        securityContextService ?? noneSecurityContextService;
    SecurityContext securityContext = SecurityContext();
    securityContext.srcPeerId = peerId;
    securityContext.payload = data.sublist(0, data.length - 1);
    bool result = await securityContextService.decrypt(securityContext);
    if (result) {
      await peerConnectionPool.onMessage(WebrtcEvent(peerId,
          clientId: clientId, data: securityContext.payload));
    }
  }

  ///发送数据，带加密选项
  Future<void> send(List<int> data,
      {CryptoOption cryptoOption = CryptoOption.none}) async {
    if (connected) {
      int cryptOptionIndex = cryptoOption.index;
      SecurityContextService? securityContextService =
          ServiceLocator.securityContextServices[cryptOptionIndex];
      securityContextService =
          securityContextService ?? cryptographySecurityContextService;
      SecurityContext securityContext = SecurityContext();
      securityContext.targetPeerId = peerId;
      securityContext.payload = data;
      bool result = await securityContextService.encrypt(securityContext);
      if (result) {
        data = CryptoUtil.concat(securityContext.payload, [cryptOptionIndex]);
        return await basePeerConnection.send(data);
      }
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
