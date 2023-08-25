import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/p2p/chain/action/signal.dart';
import 'package:colla_chat/pages/chat/index/global_chat_message_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:synchronized/synchronized.dart';

///基础的PeerConnection之上加入了业务的编号，peerId和clientId，自动进行信号的协商
class AdvancedPeerConnection {
  late BasePeerConnection basePeerConnection;

  //对方的参数
  //主叫创建的时候，一般clientId为空，需要在后面填写
  //作为被叫的时候，clientId是有值的
  String peerId;
  String clientId;
  String name;

  Map<String, List<Future<void> Function(WebrtcEvent event)>> fnsm = {};
  final Lock _fnsmLock = Lock();

  AdvancedPeerConnection(
    this.peerId,
    bool initiator, {
    this.clientId = unknownClientId,
    this.name = unknownName,
  }) {
    logger.w(
        'advancedPeerConnection peerId:$peerId, clientId:$clientId, initiator:$initiator create');
    if (StringUtil.isEmpty(clientId)) {
      logger.e('SlavePeerConnection clientId must be value');
    }
    final basePeerConnection = BasePeerConnection(initiator: initiator);
    this.basePeerConnection = basePeerConnection;
  }

  ///注册特定连接的事件监听器
  registerWebrtcEvent(
      WebrtcEventType eventType, Future<void> Function(WebrtcEvent) fn) async {
    await _fnsmLock.synchronized(() {
      List<Future<void> Function(WebrtcEvent)>? fns = fnsm[eventType.name];
      if (fns == null) {
        fns = [];
        fnsm[eventType.name] = fns;
      }
      fns.add(fn);
    });
  }

  unregisterWebrtcEvent(
      WebrtcEventType eventType, Future<void> Function(WebrtcEvent) fn) async {
    await _fnsmLock.synchronized(() {
      List<Future<void> Function(WebrtcEvent)>? fns = fnsm[eventType.name];
      if (fns == null) {
        return;
      }
      fns.remove(fn);
      if (fns.isEmpty) {
        fnsm.remove(eventType.name);
      }
    });
  }

  ///调用注册到本连接的事件处理监听器
  onWebrtcEvent(WebrtcEvent event) async {
    await _fnsmLock.synchronized(() {
      String peerId = event.peerId;
      WebrtcEventType eventType = event.eventType;
      logger.w('Webrtc peer connection $peerId webrtcEvent $eventType coming');
      var data = event.data;
      if (data != null && data is WebrtcSignal) {
        logger.w(
            'Webrtc peer connection $peerId webrtcEvent $eventType coming, and signalType:${data.signalType}');
      }
      List<Future<void> Function(WebrtcEvent)>? fns = fnsm[eventType.name];
      if (fns != null) {
        for (var fn in fns) {
          fn(event);
        }
      }
    });
  }

  Future<bool> init(
      {List<Map<String, String>>? iceServers,
      Uint8List? aesKey,
      List<PeerMediaStream> localPeerMediaStreams = const []}) async {
    var myselfPeerId = myself.peerId;
    var myselfClientId = myself.clientId;
    var myselfName = myself.myselfPeer.name;
    SignalExtension extension;
    if (myselfPeerId != null && myselfClientId != null) {
      extension = SignalExtension(myselfPeerId, myselfClientId,
          name: myselfName, iceServers: iceServers);
      extension.aesKey = aesKey;
    } else {
      logger.e('myself peerId or clientId is null');
      return false;
    }
    List<MediaStream> localStreams = [];
    if (localPeerMediaStreams.isNotEmpty) {
      for (var localPeerMediaStream in localPeerMediaStreams) {
        var stream = localPeerMediaStream.mediaStream;
        if (stream != null) {
          localStreams.add(stream);
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
    basePeerConnection.on(WebrtcEventType.signal,
        (WebrtcSignal webrtcSignal) async {
      var webrtcEvent = WebrtcEvent(peerId,
          clientId: clientId,
          name: name,
          eventType: WebrtcEventType.signal,
          data: webrtcSignal);
      onWebrtcEvent(webrtcEvent);
      await signal(webrtcEvent);
    });

    //触发basePeerConnection的connect事件，就是调用peerConnectionPool对应的signal方法
    basePeerConnection.on(WebrtcEventType.connected, (data) async {
      var webrtcEvent = WebrtcEvent(peerId,
          clientId: clientId,
          name: name,
          eventType: WebrtcEventType.connected,
          data: data);
      onWebrtcEvent(webrtcEvent);
      await peerConnectionPool.onConnected(webrtcEvent);
    });

    basePeerConnection.on(WebrtcEventType.status, (data) async {
      var webrtcEvent = WebrtcEvent(peerId,
          clientId: clientId,
          name: name,
          eventType: WebrtcEventType.status,
          data: data);
      onWebrtcEvent(webrtcEvent);
      await peerConnectionPool.onStatusChanged(webrtcEvent);
    });

    basePeerConnection.on(WebrtcEventType.closed, (data) async {
      var webrtcEvent = WebrtcEvent(peerId,
          clientId: clientId,
          name: name,
          eventType: WebrtcEventType.closed,
          data: this);
      onWebrtcEvent(webrtcEvent);
      await peerConnectionPool.onClosed(webrtcEvent);
    });

    //收到数据，带解密功能，取最后一位整数，表示解密选项，得到何种解密方式，然后解密
    basePeerConnection.on(WebrtcEventType.message, onMessage);

    basePeerConnection.on(WebrtcEventType.stream, (MediaStream stream) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:stream');
      await onAddRemoteStream(stream);
    });

    basePeerConnection.on(WebrtcEventType.removeStream,
        (MediaStream stream) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:removeStream');
      await onRemoveRemoteStream(stream);
    });

    basePeerConnection.on(WebrtcEventType.track, (data) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:track');
      await onRemoteTrack(data);
    });

    basePeerConnection.on(WebrtcEventType.addTrack, (data) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:addTrack');
      await onAddRemoteTrack(data);
    });

    basePeerConnection.on(WebrtcEventType.removeTrack, (data) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:removeTrack');
      await onRemoveRemoteTrack(data);
    });

    basePeerConnection.on(WebrtcEventType.error, (err) async {
      var webrtcEvent = WebrtcEvent(peerId,
          clientId: clientId,
          name: name,
          eventType: WebrtcEventType.error,
          data: err);
      onWebrtcEvent(webrtcEvent);
      await peerConnectionPool.onError(webrtcEvent);
    });

    return result;
  }

  negotiate() async {
    await basePeerConnection.negotiate();
  }

  bool get dataChannelOpen {
    return basePeerConnection.dataChannelOpen;
  }

  PeerConnectionStatus get status {
    return basePeerConnection.status;
  }

  NegotiateStatus get negotiateStatus {
    return basePeerConnection.negotiateStatus;
  }

  onAddRemoteStream(MediaStream stream) async {
    logger.i('streamId: ${stream.id} onAddRemoteStream');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    var webrtcEvent = WebrtcEvent(peerId,
        clientId: clientId,
        name: name,
        eventType: WebrtcEventType.stream,
        data: stream);
    onWebrtcEvent(webrtcEvent);
    await peerConnectionPool.onAddStream(webrtcEvent);
  }

  onRemoveRemoteStream(MediaStream stream) async {
    logger.i('streamId: ${stream.id} onRemoveRemoteStream');
    var webrtcEvent = WebrtcEvent(peerId,
        clientId: clientId,
        name: name,
        eventType: WebrtcEventType.removeStream,
        data: stream);
    onWebrtcEvent(webrtcEvent);
    await peerConnectionPool.onRemoveStream(webrtcEvent);
  }

  onRemoteTrack(dynamic data) async {
    MediaStream stream = data['stream'];
    MediaStreamTrack track = data['track'];
    logger.i('streamId: ${stream.id} trackId:${track.id} is onRemoteTrack');
    var webrtcEvent = WebrtcEvent(peerId,
        clientId: clientId,
        name: name,
        eventType: WebrtcEventType.track,
        data: data);
    onWebrtcEvent(webrtcEvent);
    await peerConnectionPool.onTrack(webrtcEvent);
  }

  onAddRemoteTrack(dynamic data) async {
    MediaStream stream = data['stream'];
    MediaStreamTrack track = data['track'];
    logger.i('streamId: ${stream.id} trackId:${track.id} is onAddRemoteTrack');
    var webrtcEvent = WebrtcEvent(peerId,
        clientId: clientId,
        name: name,
        eventType: WebrtcEventType.addTrack,
        data: data);
    onWebrtcEvent(webrtcEvent);
    await peerConnectionPool.onAddTrack(webrtcEvent);
  }

  onRemoveRemoteTrack(dynamic data) async {
    MediaStream stream = data['stream'];
    MediaStreamTrack track = data['track'];
    logger
        .i('streamId: ${stream.id} trackId:${track.id} is onRemoveRemoteTrack');
    var webrtcEvent = WebrtcEvent(peerId,
        clientId: clientId,
        name: name,
        eventType: WebrtcEventType.removeTrack,
        data: data);
    onWebrtcEvent(webrtcEvent);
    await peerConnectionPool.onRemoveTrack(webrtcEvent);
  }

  ///将本地渲染器包含的流加入连接中，在收到接受视频要求的时候调用
  Future<bool> addLocalStream(PeerMediaStream peerMediaStream) async {
    logger.i('addLocalStream ${peerMediaStream.id}');
    var stream = peerMediaStream.mediaStream;
    if (stream != null) {
      var success = await basePeerConnection.addLocalStream(stream);
      return success;
    }
    return false;
  }

  /// 主动从连接中移除本地媒体流，然后会激活onRemoveStream
  removeStream(PeerMediaStream peerMediaStream) async {
    logger.i('removeStream ${peerMediaStream.id}');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    var streamId = peerMediaStream.id;
    if (streamId != null) {
      if (peerMediaStream.mediaStream != null) {
        await basePeerConnection.removeStream(peerMediaStream.mediaStream!);
      }
    }
  }

  /// 主动从连接中移除一个本地轨道，然后会激活onRemoveTrack
  removeTrack(MediaStream stream, MediaStreamTrack track) async {
    await basePeerConnection.removeTrack(stream, track);
  }

  ///把渲染器的流克隆，然后可以当作本地流加入到其他连接中，用于转发
  Future<MediaStream?> cloneStream(PeerMediaStream peerMediaStream) async {
    logger.i('cloneStream ${peerMediaStream.id}');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return null;
    }
    var streamId = peerMediaStream.id;
    if (streamId != null) {
      if (peerMediaStream.mediaStream != null) {
        return await basePeerConnection
            .cloneStream(peerMediaStream.mediaStream!);
      }
    }
    return null;
  }

  replaceTrack(MediaStream stream, MediaStreamTrack oldTrack,
      MediaStreamTrack newTrack) async {
    await basePeerConnection.replaceTrack(stream, oldTrack, newTrack);
  }

  onSignal(WebrtcSignal signal) async {
    await basePeerConnection.onSignal(signal);
  }

  bool get connected {
    return basePeerConnection.status == PeerConnectionStatus.connected;
  }

  ///收到数据，先解密，然后转换成还原utf-8字符串，再将json字符串变成map对象
  onMessage(List<int> data) async {
    ChatMessage? chatMessage = await chatMessageService.decrypt(data);
    if (chatMessage != null) {
      //对消息进行业务处理
      chatMessage.transportType = TransportType.webrtc.name;
      await globalChatMessageController.receiveChatMessage(chatMessage);

      var webrtcEvent = WebrtcEvent(peerId,
          clientId: clientId,
          name: name,
          eventType: WebrtcEventType.message,
          data: chatMessage);
      onWebrtcEvent(webrtcEvent);
      await peerConnectionPool.onMessage(webrtcEvent);
    } else {
      logger.e('Received chatMessage but decrypt failure');
    }
  }

  ///发送数据
  Future<bool> send(List<int> data) async {
    if (connected) {
      return await basePeerConnection.send(data);
    } else {
      logger.e(
          'send failed , peerId:$peerId clientId:$clientId webrtc connection state is not connected');
      return false;
    }
  }

  ///调用本连接或者signalAction发送signal到信号服务器
  Future<bool> signal(WebrtcEvent evt) async {
    try {
      if (connected) {
        ChatMessage chatMessage = await chatMessageService.buildChatMessage(
            receiverPeerId: peerId,
            content: evt.data,
            clientId: clientId,
            messageType: ChatMessageType.system,
            subMessageType: ChatMessageSubType.signal);
        await chatMessageService.sendAndStore(chatMessage);
        // logger.w(
        //     'sent signal chatMessage by webrtc peerId:$peerId, clientId:$clientId, signal:$jsonStr');
      } else {
        var success = await signalAction.signal(evt.data, peerId,
            targetClientId: clientId);
        if (!success) {
          logger.e('signalAction signal err');
        }
        return success;
      }
    } catch (err) {
      logger.e('signal err:$err');
    }
    return false;
  }

  close() async {
    await basePeerConnection.close();
  }
}
