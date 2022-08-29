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

  Future<bool> init(
      {List<Map<String, String>>? iceServers,
      List<PeerVideoRender> localRenders = const []}) async {
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
    List<MediaStream> localStreams = [];
    if (localRenders.isNotEmpty) {
      for (var localRender in localRenders) {
        var stream = localRender.mediaStream;
        if (stream != null) {
          localStreams.add(stream);
          videoRenders[localRender.id!] = localRender;
        }
      }
    }
    bool result = await basePeerConnection.init(
        extension: extension, localStreams: localStreams);
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
          .onConnected(WebrtcEvent(peerId, clientId: clientId, data: data));
    });

    basePeerConnection.on(WebrtcEventType.status, (data) async {
      await peerConnectionPool
          .onStatus(WebrtcEvent(peerId, clientId: clientId, data: data));
    });

    basePeerConnection.on(WebrtcEventType.closed, (data) async {
      await peerConnectionPool
          .onClosed(WebrtcEvent(peerId, clientId: clientId, data: data));
    });

    //收到数据，带解密功能，取最后一位整数，表示解密选项，得到何种解密方式，然后解密
    basePeerConnection.on(WebrtcEventType.message, onMessage);

    basePeerConnection.on(WebrtcEventType.stream, (MediaStream stream) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:stream');
      await onAddStream(stream);
    });

    basePeerConnection.on(WebrtcEventType.removeStream,
        (MediaStream stream) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:removeStream');
      await onRemoveStream(stream);
    });

    basePeerConnection.on(WebrtcEventType.track, (RTCTrackEvent event) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:track');
      await onTrack(event);
    });

    basePeerConnection.on(WebrtcEventType.addTrack, (data) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:addTrack');
      await onAddTrack(data);
    });

    basePeerConnection.on(WebrtcEventType.removeTrack, (data) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:removeTrack');
      await onRemoveTrack(data);
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

  onAddStream(MediaStream stream) async {
    logger.i('peerId: $peerId clientId:$clientId is onAddStream');
    //await addStream(stream);
    await peerConnectionPool
        .onAddStream(WebrtcEvent(peerId, clientId: clientId, data: stream));
  }

  onRemoveStream(MediaStream stream) async {
    logger.i('peerId: $peerId clientId:$clientId is onRemoveStream');
    await _removeStream(stream);
    await peerConnectionPool
        .onRemoveStream(WebrtcEvent(peerId, clientId: clientId, data: stream));
  }

  onTrack(RTCTrackEvent event) async {
    logger.i('peerId: $peerId clientId:$clientId is onTrack');
    await peerConnectionPool
        .onTrack(WebrtcEvent(peerId, clientId: clientId, data: event));
  }

  onAddTrack(dynamic data) async {
    logger.i('peerId: $peerId clientId:$clientId is onAddTrack');
    // MediaStream stream = data['stream'];
    // String streamId = stream.id;
    // if (!videoRenders.containsKey(streamId)) {
    //   _addStream(stream);
    // }
    await peerConnectionPool
        .onAddTrack(WebrtcEvent(peerId, clientId: clientId, data: data));
  }

  onRemoveTrack(dynamic data) async {
    logger.i('peerId: $peerId clientId:$clientId is onRemoveTrack');
    await peerConnectionPool
        .onRemoveTrack(WebrtcEvent(peerId, clientId: clientId, data: data));
  }

  ///把渲染器加入到渲染器集合
  _addRender(PeerVideoRender render) async {
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    var streamId = render.id;
    if (streamId != null) {
      videoRenders[streamId] = render;
      logger.i(
          'AdvancedPeerConnection peerId:$peerId _addRender $streamId, videoRenders length:${videoRenders.length}');
    }
  }

  ///把渲染器从渲染器集合删除，并关闭
  _removeRender(PeerVideoRender render) async {
    logger.i('_removeRender ${render.id}');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    var streamId = render.id;
    if (streamId != null) {
      if (videoRenders.containsKey(streamId)) {
        videoRenders.remove(streamId);
      }
      await render.dispose();
    }
  }

  ///把渲染器的流连接中删除，然后把渲染器从渲染器集合删除，并关闭
  removeRender(PeerVideoRender render) async {
    logger.i('removeRender ${render.id}');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    var streamId = render.id;
    if (streamId != null) {
      if (render.mediaStream != null) {
        await basePeerConnection.removeStream(render.mediaStream!);
      }
      await _removeRender(render);
    }
  }

  ///生成流的渲染器，然后加入到渲染器集合
  Future<PeerVideoRender> addStream(MediaStream stream) async {
    String streamId = stream.id;
    if (videoRenders.containsKey(streamId)) {
      logger.e('stream:$streamId exist in videoRenders, be replaced');
    }
    PeerVideoRender render = await PeerVideoRender.from(peerId,
        clientId: clientId, name: name, stream: stream);
    await render.bindRTCVideoRender();
    await _addRender(render);

    return render;
  }

  _removeStream(MediaStream stream) async {
    var streamId = stream.id;
    var render = videoRenders[streamId];
    if (render != null) {
      await _removeRender(render);
    }
  }

  removeStream(MediaStream stream) async {
    var streamId = stream.id;
    var render = videoRenders[streamId];
    if (render != null) {
      if (render.mediaStream != null) {
        await basePeerConnection.removeStream(render.mediaStream!);
      }
      await _removeRender(render);
    }
  }

  removeTrack(MediaStream stream, MediaStreamTrack track) async {
    await basePeerConnection.removeTrack(stream, track);
  }

  replaceTrack(MediaStream stream, MediaStreamTrack oldTrack,
      MediaStreamTrack newTrack) async {
    await basePeerConnection.replaceTrack(stream, oldTrack, newTrack);
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
      {CryptoOption cryptoOption = CryptoOption.cryptography}) async {
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
