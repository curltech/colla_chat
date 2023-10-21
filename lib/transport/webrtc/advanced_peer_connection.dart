import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/crypto/signalprotocol.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/p2p/chain/action/signal.dart';
import 'package:colla_chat/pages/chat/index/global_chat_message.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_conference_client.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

///基础的PeerConnection之上加入了业务的编号，peerId和clientId，自动进行信号的协商
class AdvancedPeerConnection {
  late BasePeerConnection basePeerConnection;

  //对方的参数
  //主叫创建的时候，一般clientId为空，需要在后面填写
  //作为被叫的时候，clientId是有值的
  String peerId;
  String clientId;
  String name;

  Map<WebrtcEventType, StreamController<WebrtcEvent>>
      webrtcEventStreamControllers = {};

  AdvancedPeerConnection(
    this.peerId, {
    this.clientId = unknownClientId,
    this.name = unknownName,
  }) {
    logger
        .w('advancedPeerConnection peerId:$peerId, clientId:$clientId create');
    if (StringUtil.isEmpty(clientId)) {
      logger.e('SlavePeerConnection clientId must be value');
    }
    final basePeerConnection = BasePeerConnection();
    this.basePeerConnection = basePeerConnection;
    _registerStreamController();
  }

  /// 监听信号流，注册各种webrtc event
  _registerStreamController() {
    for (WebrtcEventType webrtcEventType in WebrtcEventType.values) {
      webrtcEventStreamControllers[webrtcEventType] =
          StreamController<WebrtcEvent>.broadcast();
    }
    listen(WebrtcEventType.message, globalChatMessage.onMessage);
    listen(WebrtcEventType.initiator, onInitiator);
    listen(WebrtcEventType.connected, onConnected);
    listen(WebrtcEventType.connectionState, onConnectionState);
    listen(WebrtcEventType.signalingState, onSignalingState);
    listen(WebrtcEventType.closed, onClosed);
    listen(WebrtcEventType.stream, onStream);
    listen(WebrtcEventType.removeStream, onRemoveStream);
    listen(WebrtcEventType.track, onTrack);
    listen(WebrtcEventType.addTrack, onAddTrack);
    listen(WebrtcEventType.removeTrack, onRemoveTrack);
    listen(WebrtcEventType.error, onError);
  }

  StreamSubscription<WebrtcEvent>? listen(
    WebrtcEventType webrtcEventType,
    void Function(WebrtcEvent) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    StreamController<WebrtcEvent>? webrtcEventStreamController =
        webrtcEventStreamControllers[webrtcEventType];
    return webrtcEventStreamController?.stream.listen((WebrtcEvent event) {
      onData(event);
    }, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  Future<bool> init(bool initiator,
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
    basePeerConnection.on(WebrtcEventType.initiator, (data) async {
      _addWebrtcEventType(WebrtcEventType.initiator, data);
    });

    bool result = await basePeerConnection.init(initiator, extension,
        localStreams: localStreams);
    if (!result) {
      logger.e('WebrtcCorePeer init result is false');
      return false;
    }

    /// 在basePeerConnection中注册webrtcEvent，当basePeerConnection发生相应的事件后，
    /// 在peerConnectionPool的webrtcEventType的流控制器中加入事件
    /// 然后basePeerConnection中调用emit方法，就可以调用对应的方法
    basePeerConnection.on(WebrtcEventType.signal,
        (WebrtcSignal webrtcSignal) async {
      await sendSignal(webrtcSignal);
    });

    //触发basePeerConnection的connect事件，就是调用peerConnectionPool对应的signal方法
    basePeerConnection.on(WebrtcEventType.connected, (data) async {
      _addWebrtcEventType(WebrtcEventType.connected, data);
    });

    basePeerConnection.on(WebrtcEventType.connectionState, (data) async {
      _addWebrtcEventType(WebrtcEventType.connectionState, data);
    });

    basePeerConnection.on(WebrtcEventType.signalingState, (data) async {
      _addWebrtcEventType(WebrtcEventType.signalingState, data);
    });

    basePeerConnection.on(WebrtcEventType.closed, (data) async {
      _addWebrtcEventType(WebrtcEventType.closed, this);
    });

    //收到数据，带解密功能，取最后一位整数，表示解密选项，得到何种解密方式，然后解密
    basePeerConnection.on(WebrtcEventType.message, (data) async {
      _addWebrtcEventType(WebrtcEventType.message, data);
    });

    basePeerConnection.on(WebrtcEventType.stream, (MediaStream stream) async {
      if (connectionState ==
          RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        logger.e('PeerConnection closed');
        return;
      }
      _addWebrtcEventType(WebrtcEventType.stream, stream);
    });

    basePeerConnection.on(WebrtcEventType.removeStream,
        (MediaStream stream) async {
      _addWebrtcEventType(WebrtcEventType.removeStream, stream);
    });

    basePeerConnection.on(WebrtcEventType.track, (data) async {
      _addWebrtcEventType(WebrtcEventType.track, data);
    });

    basePeerConnection.on(WebrtcEventType.addTrack, (data) async {
      _addWebrtcEventType(WebrtcEventType.addTrack, data);
    });

    basePeerConnection.on(WebrtcEventType.removeTrack, (data) async {
      _addWebrtcEventType(WebrtcEventType.removeTrack, data);
    });

    basePeerConnection.on(WebrtcEventType.error, (err) async {
      _addWebrtcEventType(WebrtcEventType.error, err);
    });

    return result;
  }

  /// 在peerConnectionPool的webrtcEventType的流控制器中加入事件
  _addWebrtcEventType(WebrtcEventType webrtcEventType, dynamic data) async {
    StreamController<WebrtcEvent>? webrtcEventStreamController =
        webrtcEventStreamControllers[webrtcEventType];
    if (webrtcEventStreamController != null) {
      WebrtcEvent webrtcEvent = WebrtcEvent(peerId,
          clientId: clientId,
          name: name,
          eventType: webrtcEventType,
          data: data);

      webrtcEventStreamController.add(webrtcEvent);
    }
  }

  renegotiate({bool toggle = false}) async {
    await basePeerConnection.negotiate(toggle: toggle);
  }

  restartIce() async {
    await basePeerConnection.restartIce();
  }

  bool get dataChannelOpen {
    return basePeerConnection.dataChannelOpen;
  }

  RTCPeerConnectionState? get connectionState {
    return basePeerConnection.connectionState;
  }

  RTCSignalingState? get signalingState {
    return basePeerConnection.signalingState;
  }

  ///将本地渲染器包含的流加入连接中，在收到接受视频要求的时候调用
  Future<bool> addLocalStream(PeerMediaStream peerMediaStream) async {
    var stream = peerMediaStream.mediaStream;
    if (stream != null) {
      var success = await basePeerConnection.addLocalStream(stream);
      return success;
    }
    return false;
  }

  /// 主动从连接中移除本地媒体流，然后会激活onRemoveStream
  removeStream(PeerMediaStream peerMediaStream) async {
    if (connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
      logger.e('PeerConnection closed');
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
    if (connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
      logger.e('PeerConnection closed');
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

  bool get connected {
    return basePeerConnection.connected;
  }

  ///发送数据
  Future<bool> send(List<int> data) async {
    if (dataChannelOpen && basePeerConnection.dataChannel != null) {
      return await basePeerConnection.send(data);
    } else {
      logger.e(
          'send failed , peerId:$peerId clientId:$clientId webrtc connection state is not connected');
      return false;
    }
  }

  /// 调用本连接或者signalAction发送signal到信号服务器
  Future<bool> sendSignal(WebrtcSignal signal) async {
    try {
      if (dataChannelOpen && basePeerConnection.dataChannel != null) {
        ChatMessage chatMessage = await chatMessageService.buildChatMessage(
            receiverPeerId: peerId,
            content: signal,
            clientId: clientId,
            messageType: ChatMessageType.system,
            subMessageType: ChatMessageSubType.signal);
        await chatMessageService.send(chatMessage);
        // logger.w(
        //     'sent signal chatMessage by webrtc peerId:$peerId, clientId:$clientId, signal:$jsonStr');
      } else {
        var success =
            await signalAction.signal(signal, peerId, targetClientId: clientId);
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

  ///连接成功
  ///webrtc连接完成后首先交换最新的联系人信息，然后请求新的订阅渠道消息
  ///然后交换棘轮加密的密钥
  onConnected(WebrtcEvent event) async {
    globalChatMessage.sendModifyLinkman(event.peerId, clientId: event.clientId);
    globalChatMessage.sendPreKeyBundle(event.peerId, clientId: event.clientId);
    chatMessageService.sendUnsent(receiverPeerId: event.peerId);
    p2pConferenceClientPool.onConnected(this);
  }

  ///从池中移除连接
  onClosed(WebrtcEvent event) async {
    peerConnectionPool.remove(event.peerId, clientId: event.clientId);
    signalSessionPool.close(peerId: event.peerId, clientId: event.clientId);
  }

  ///连接状态发生改变
  onConnectionState(WebrtcEvent event) async {}

  onSignalingState(WebrtcEvent event) async {}

  onError(WebrtcEvent event) async {}

  onInitiator(WebrtcEvent event) async {}

  onStream(WebrtcEvent event) async {
    String peerId = event.peerId;
    String clientId = event.clientId;
    String name = event.name;
    MediaStream stream = event.data;
  }

  onAddStream(WebrtcEvent event) async {
    String peerId = event.peerId;
    String clientId = event.clientId;
    String name = event.name;
    MediaStream stream = event.data;
  }

  onRemoveStream(WebrtcEvent event) async {
    String peerId = event.peerId;
    String clientId = event.clientId;
    String name = event.name;
    MediaStream stream = event.data;
  }

  onTrack(WebrtcEvent event) async {
    String peerId = event.peerId;
    String clientId = event.clientId;
    String name = event.name;
    dynamic data = event.data;
    MediaStream stream = data['stream'];
    MediaStreamTrack track = data['track'];
  }

  onAddTrack(WebrtcEvent event) async {
    String peerId = event.peerId;
    String clientId = event.clientId;
    String name = event.name;
    dynamic data = event.data;
    MediaStream stream = data['stream'];
    MediaStreamTrack track = data['track'];
  }

  onRemoveTrack(WebrtcEvent event) async {
    String peerId = event.peerId;
    String clientId = event.clientId;
    String name = event.name;
    dynamic data = event.data;
    MediaStream stream = data['stream'];
    MediaStreamTrack track = data['track'];
  }

  close() async {
    await basePeerConnection.close();
  }
}
