import 'dart:async';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/local_video_render_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_connections_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
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
  Room? room;

  AdvancedPeerConnection(this.peerId, bool initiator,
      {this.clientId = unknownClientId, this.name = unknownName, this.room}) {
    logger.w(
        'advancedPeerConnection peerId:$peerId, clientId:$clientId, initiator:$initiator create');
    if (StringUtil.isEmpty(clientId)) {
      logger.e('SlavePeerConnection clientId must be value');
    }
    final basePeerConnection = BasePeerConnection(initiator: initiator);
    this.basePeerConnection = basePeerConnection;
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
      await peerConnectionPool.signal(
          WebrtcEvent(peerId, clientId: clientId, name: name, data: signal));
    });

    //触发basePeerConnection的connect事件，就是调用peerConnectionPool对应的signal方法
    basePeerConnection.on(WebrtcEventType.connected, onConnected);

    basePeerConnection.on(WebrtcEventType.status, (data) async {
      await peerConnectionPool.onStatus(
          WebrtcEvent(peerId, clientId: clientId, name: name, data: data));
    });

    basePeerConnection.on(WebrtcEventType.closed, (data) async {
      await peerConnectionPool.onClosed(
          WebrtcEvent(peerId, clientId: clientId, name: name, data: data));
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

    basePeerConnection.on(WebrtcEventType.track, (RTCTrackEvent event) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:track');
      await onRemoteTrack(event);
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
      await peerConnectionPool.onError(
          WebrtcEvent(peerId, clientId: clientId, name: name, data: err));
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
    logger.i('peerId: $peerId clientId:$clientId is onAddRemoteStream');
    await _addRemoteStream(stream);
    await peerConnectionPool.onAddStream(
        WebrtcEvent(peerId, clientId: clientId, name: name, data: stream));
  }

  onRemoveRemoteStream(MediaStream stream) async {
    logger.i('peerId: $peerId clientId:$clientId is onRemoveRemoteStream');
    await _removeRemoteStream(stream);
    await peerConnectionPool.onRemoveStream(
        WebrtcEvent(peerId, clientId: clientId, name: name, data: stream));
  }

  onRemoteTrack(RTCTrackEvent event) async {
    logger.i('peerId: $peerId clientId:$clientId is onRemoteTrack');
    await peerConnectionPool.onTrack(
        WebrtcEvent(peerId, clientId: clientId, name: name, data: event));
  }

  onAddRemoteTrack(dynamic data) async {
    logger.i('peerId: $peerId clientId:$clientId is onAddRemoteTrack');
    // MediaStream stream = data['stream'];
    // String streamId = stream.id;
    // if (!videoRenders.containsKey(streamId)) {
    //   _addStream(stream);
    // }
    await peerConnectionPool.onAddTrack(
        WebrtcEvent(peerId, clientId: clientId, name: name, data: data));
  }

  onRemoveRemoteTrack(dynamic data) async {
    logger.i('peerId: $peerId clientId:$clientId is onRemoveRemoteTrack');
    await peerConnectionPool.onRemoveTrack(
        WebrtcEvent(peerId, clientId: clientId, name: name, data: data));
  }

  ///把渲染器加入到渲染器集合，并将包含的流加入连接中
  Future<bool> addLocalRender(PeerVideoRender render) async {
    VideoRenderController videoRenderController =
        localVideoRenderController.videoRenderController;
    logger.i(
        'AdvancedPeerConnection peerId:$peerId addLocalRender ${render.mediaStream!.id}, localVideoRenders length:${videoRenderController.videoRenders.length}');

    bool success = _addLocalRender(render);
    if (success) {
      var stream = render.mediaStream;
      if (stream != null) {
        success = await basePeerConnection.addLocalStream(stream);
        return success;
      }
    }
    return false;
  }

  ///把渲染器加入到渲染器集合
  bool _addLocalRender(PeerVideoRender render) {
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return false;
    }
    var streamId = render.id;
    if (streamId != null) {
      VideoRenderController videoRenderController =
          localVideoRenderController.videoRenderController;
      videoRenderController.add(render);
      render.peerId = peerId;
      render.name = name;
      render.clientId = clientId;
      logger.i(
          'AdvancedPeerConnection peerId:$peerId _addLocalRender $streamId, localVideoRenders length:${videoRenderController.videoRenders.length}');
      return true;
    }
    return false;
  }

  ///把渲染器的流连接中删除，然后把渲染器从渲染器集合删除，并关闭
  removeLocalRender(PeerVideoRender render) async {
    logger.i('removeLocalRender ${render.id}');
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

  ///把渲染器从渲染器集合删除，并关闭
  _removeRender(PeerVideoRender render) async {
    logger.i('_removeRender ${render.id}');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    var streamId = render.id;
    if (streamId != null) {
      VideoRenderController videoRenderController =
          localVideoRenderController.videoRenderController;
      videoRenderController.close(streamId: streamId);
    }
  }

  bool _addRemoteRender(PeerVideoRender render) {
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return false;
    }
    var streamId = render.id;
    if (streamId != null) {
      VideoRenderController videoRenderController = peerConnectionsController
          .videoRenderControllers[basePeerConnection.id]!;
      videoRenderController.add(render);
      render.peerId = peerId;
      render.name = name;
      render.clientId = clientId;
      logger.i(
          'AdvancedPeerConnection peerId:$peerId _addRemoteRender $streamId, remoteVideoRenders length:${videoRenderController.videoRenders.length}');
      return true;
    }
    return false;
  }

  Future<PeerVideoRender> _addRemoteStream(MediaStream stream) async {
    String streamId = stream.id;
    VideoRenderController? videoRenderController =
        peerConnectionsController.videoRenderControllers[basePeerConnection.id];
    if (videoRenderController != null) {
      PeerVideoRender? render = videoRenderController.videoRenders[streamId];
      if (render != null) {
        return render;
      }
    }
    PeerVideoRender render = await PeerVideoRender.from(peerId,
        clientId: clientId, name: name, stream: stream);
    await render.bindRTCVideoRender();
    _addRemoteRender(render);

    return render;
  }

  _removeRemoteStream(MediaStream stream) async {
    var streamId = stream.id;
    VideoRenderController? videoRenderController =
        peerConnectionsController.videoRenderControllers[basePeerConnection.id];
    if (videoRenderController != null) {
      videoRenderController.close(streamId: streamId);
    }
  }

  removeTrack(MediaStream stream, MediaStreamTrack track) async {
    await basePeerConnection.removeTrack(stream, track);
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

  onConnected(dynamic data) async {
    await peerConnectionPool.onConnected(
        WebrtcEvent(peerId, clientId: clientId, name: name, data: data));
  }

  ///收到数据，带解密功能，取最后一位整数，表示解密选项，得到何种解密方式，然后解密
  onMessage(List<int> data) async {
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
          clientId: clientId, name: name, data: securityContext.payload));
    }
  }

  ///发送数据，带加密选项
  Future<bool> send(List<int> data,
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
      return false;
    } else {
      logger.e(
          'send failed , peerId:$peerId clientId:$clientId webrtc connection state is not connected');
      return false;
    }
  }

  close() async {
    await basePeerConnection.close();
  }
}
