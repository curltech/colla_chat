import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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

  //远程媒体流渲染器数组，在onAddStream,onAddTrack等的回调方法中得到
  Map<String, PeerVideoRender> videoRenders = {};

  AdvancedPeerConnection(this.peerId, bool initiator,
      {this.clientId, this.name, this.room}) {
    if (initiator) {
      final basePeerConnection = BasePeerConnection(initiator: true);
      this.basePeerConnection = basePeerConnection;
    } else {
      if (StringUtil.isEmpty(clientId)) {
        logger.e('SlavePeerConnection clientId must be value');
      }
      final basePeerConnection = BasePeerConnection(initiator: false);
      this.basePeerConnection = basePeerConnection;
    }
  }

  Future<bool> init({List<Map<String, String>>? iceServers}) async {
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
    bool result = await basePeerConnection.init(extension: extension);
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

    basePeerConnection.on(WebrtcEventType.status, (data) async {
      await peerConnectionPool
          .onStatus(WebrtcEvent(peerId, clientId: clientId, data: data));
    });

    basePeerConnection.on(WebrtcEventType.closed, (data) async {
      await peerConnectionPool
          .onClosed(WebrtcEvent(peerId, clientId: clientId));
    });

    //收到数据，带解密功能，取最后一位整数，表示解密选项，得到何种解密方式，然后解密
    basePeerConnection.on(WebrtcEventType.message, onMessage);

    basePeerConnection.on(WebrtcEventType.stream, (stream) async {
      await peerConnectionPool
          .onAddStream(WebrtcEvent(peerId, clientId: clientId, data: stream));
    });

    basePeerConnection.on(WebrtcEventType.removeStream, (stream) async {
      await peerConnectionPool.onRemoveStream(
          WebrtcEvent(peerId, clientId: clientId, data: stream));
    });

    basePeerConnection.on(WebrtcEventType.track, (track, stream) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:track');
      await peerConnectionPool.onTrack(WebrtcEvent(peerId,
          clientId: clientId, data: {'track': track, 'stream': stream}));
    });

    basePeerConnection.on(WebrtcEventType.addTrack, (track, stream) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:addTrack');
      await peerConnectionPool.onAddTrack(WebrtcEvent(peerId,
          clientId: clientId, data: {'track': track, 'stream': stream}));
    });

    basePeerConnection.on(WebrtcEventType.removeTrack, (track, stream) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:removeTrack');
      await peerConnectionPool.onRemoveTrack(WebrtcEvent(peerId,
          clientId: clientId, data: {'track': track, 'stream': stream}));
    });

    basePeerConnection.on(WebrtcEventType.error, (err) async {
      await peerConnectionPool
          .onError(WebrtcEvent(peerId, clientId: clientId, data: err));
    });

    return result;
  }

  PeerConnectionStatus get status {
    return basePeerConnection.status;
  }

  /// 主动把渲染器加入到渲染器集合，并把渲染器的流加入到连接中，然后会激活onAddStream
  /// @param {MediaStream} stream
  addRender(PeerVideoRender render) async {
    logger.i('addRender ${render.id}');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    var streamId = render.id;
    if (streamId != null) {
      if (videoRenders.containsKey(streamId)) {
        return;
      }
      videoRenders[streamId] = render;
      if (render.mediaStream != null) {
        await basePeerConnection.addStream(render.mediaStream!);
      }
    }
  }

  removeRender(PeerVideoRender render) async {
    logger.i('removeRender ${render.id}');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    var streamId = render.id;
    if (streamId != null) {
      if (videoRenders.containsKey(streamId)) {
        videoRenders.remove(streamId);
      }
      if (render.mediaStream != null) {
        await basePeerConnection.removeStream(render.mediaStream!);
      }
      render.dispose();
    }
  }

  addStream(MediaStream stream) async {
    PeerVideoRender render = await PeerVideoRender.from(peerId,
        clientId: clientId, name: name, stream: stream);
    render.bindRTCVideoRender();
    addRender(render);
  }

  removeStream(MediaStream stream) async {
    var streamId = stream.id;
    var render = videoRenders[streamId];
    if (render != null) {
      videoRenders.remove(streamId);
      if (render.mediaStream != null) {
        await basePeerConnection.removeStream(render.mediaStream!);
      }
      render.dispose();
    }
  }

  addTrack(MediaStreamTrack track, MediaStream stream) async {
    await basePeerConnection.addTrack(track, stream);
  }

  removeTrack(MediaStreamTrack track, MediaStream stream) async {
    await basePeerConnection.removeTrack(track, stream);
  }

  replaceTrack(
    MediaStreamTrack oldTrack,
    MediaStreamTrack newTrack,
    MediaStream stream,
  ) async {
    await basePeerConnection.replaceTrack(oldTrack, newTrack, stream);
  }

  onSignal(WebrtcSignal signal) {
    basePeerConnection.onSignal(signal);
  }

  bool get connected {
    return basePeerConnection.status == PeerConnectionStatus.connected;
  }

  ///收到数据，带解密功能，取最后一位整数，表示解密选项，得到何种解密方式，然后解密
  onMessage(Uint8List data) async {
    logger.i('${DateTime.now().toUtc()}:got a message from peer');
    int cryptOption = data[data.length - 1];
    SecurityContextService? securityContextService =
        ServiceLocator.securityContextServices[cryptOption];
    securityContextService =
        securityContextService ?? noneSecurityContextService;
    SecurityContext securityContext = SecurityContext();
    securityContext.srcPeerId = peerId;
    securityContext.clientId = clientId;
    securityContext.payload = data.sublist(0, data.length - 1);
    bool result = await securityContextService.decrypt(securityContext);
    if (result) {
      await peerConnectionPool.onMessage(WebrtcEvent(peerId,
          clientId: clientId, data: securityContext.payload));
    }
  }

  ///发送数据，带加密选项
  Future<void> send(List<int> data,
      {CryptoOption cryptoOption = CryptoOption.signal}) async {
    if (connected) {
      int cryptOptionIndex = cryptoOption.index;
      SecurityContextService? securityContextService =
          ServiceLocator.securityContextServices[cryptOptionIndex];
      securityContextService =
          securityContextService ?? cryptographySecurityContextService;
      SecurityContext securityContext = SecurityContext();
      securityContext.targetPeerId = peerId;
      securityContext.clientId = clientId;
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
