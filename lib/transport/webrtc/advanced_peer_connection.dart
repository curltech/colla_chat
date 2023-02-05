import 'dart:async';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/local_video_render_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:colla_chat/transport/webrtc/video_room_controller.dart';
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

  //如果本连接有视频或者音频，则room不为空，单聊的roomId是对方的peerId:clientId
  //群聊，会议的roomId是发起和接受聊天请求时由发起者创建，并随着聊天请求传输到被发起方
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
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    await _addRemoteStream(stream);
    await peerConnectionPool.onAddStream(
        WebrtcEvent(peerId, clientId: clientId, name: name, data: stream));
  }

  Future<PeerVideoRender?> _addRemoteStream(MediaStream stream) async {
    if (room == null || room!.roomId == null) {
      logger.e('room is not exist');
      return null;
    }
    String roomId = room!.roomId!;
    VideoRoomController? videoRoomController =
        videoRoomPool.getVideoRoomController(roomId);
    if (videoRoomController == null) {
      logger.e('videoRoomController:$roomId is not exist');
      return null;
    }

    String streamId = stream.id;
    PeerVideoRender? videoRender = videoRoomController.videoRenders[streamId];
    if (videoRender != null) {
      return videoRender;
    }
    PeerVideoRender render = await PeerVideoRender.fromMediaStream(peerId,
        clientId: clientId, name: name, stream: stream);
    videoRoomController.add(render);

    return render;
  }

  onRemoveRemoteStream(MediaStream stream) async {
    logger.i('peerId: $peerId clientId:$clientId is onRemoveRemoteStream');
    await _removeRemoteStream(stream);
    await peerConnectionPool.onRemoveStream(
        WebrtcEvent(peerId, clientId: clientId, name: name, data: stream));
  }

  _removeRemoteStream(MediaStream stream) async {
    if (room == null || room!.roomId == null) {
      logger.e('room is not exist');
      return null;
    }
    String roomId = room!.roomId!;
    VideoRoomController? videoRoomController =
        videoRoomPool.getVideoRoomController(roomId);
    if (videoRoomController == null) {
      logger.e('videoRoomController:$roomId is not exist');
      return null;
    }

    var streamId = stream.id;
    videoRoomController.close(streamId: streamId);
  }

  onRemoteTrack(RTCTrackEvent event) async {
    logger.i('peerId: $peerId clientId:$clientId is onRemoteTrack');
    await peerConnectionPool.onTrack(
        WebrtcEvent(peerId, clientId: clientId, name: name, data: event));
  }

  onAddRemoteTrack(dynamic data) async {
    logger.i('peerId: $peerId clientId:$clientId is onAddRemoteTrack');
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
    logger.i(
        'AdvancedPeerConnection peerId:$peerId addLocalRender ${render.mediaStream!.id}, localVideoRenders length:${localVideoRenderController.videoRenders.length}');

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
      localVideoRenderController.add(render);
      logger.i(
          'AdvancedPeerConnection peerId:$peerId _addLocalRender $streamId, localVideoRenders length:${localVideoRenderController.videoRenders.length}');
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
      localVideoRenderController.close(streamId: streamId);
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

  ///收到数据，先解密，然后转换成还原utf-8字符串，再将json字符串变成map对象
  onMessage(List<int> data) async {
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
      String jsonStr = CryptoUtil.utf8ToString(securityContext.payload);
      var json = JsonUtil.toJson(jsonStr);
      await peerConnectionPool.onMessage(
          WebrtcEvent(peerId, clientId: clientId, name: name, data: json));
    }
  }

  ///发送数据，带加密选项，传入数据为对象，先转换成json字符串，然后utf-8，再加密，最后发送
  Future<bool> send(dynamic obj,
      {CryptoOption cryptoOption = CryptoOption.cryptography}) async {
    if (connected) {
      var jsonStr = JsonUtil.toJsonString(obj);
      List<int> data = CryptoUtil.stringToUtf8(jsonStr);
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
