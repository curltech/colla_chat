import 'dart:async';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/service/p2p/message_serializer.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/dio_http_client.dart';
import 'package:colla_chat/transport/websocket/websocket_channel.dart';
import 'package:dio/dio.dart';

const packetSize = 4 * 1024 * 1024;
const webRtcPacketSize = 128 * 1024;

/// websocket的原始消息的分派处理
class ChainMessageHandler {
  final Map<MsgType, BaseAction> p2pActions = {};
  Map<String, List<ChainMessage>> caches = <String, List<ChainMessage>>{};

  /// websocket的原始消息流
  StreamController<WebsocketData> websocketDataStreamController =
      StreamController<WebsocketData>();

  ChainMessageHandler() {
    websocketDataStreamController.stream.listen((WebsocketData websocketData) {
      receiveRaw(websocketData);
    });
  }

  ///发送前的预处理，设置消息的初始值
  ///如果targetPeerId不为空，指的是目标peerclient，否则是直接向connectPeerId的peerendpoint发送信息
  Future<ChainMessage> prepareSend(List<int>? data, MsgType msgType,
      {String? connectAddress,
      String? connectPeerId,
      String? targetPeerId,
      String? topic,
      String? targetClientId,
      PayloadType? payloadType}) async {
    ChainMessage chainMessage = ChainMessage();

    //如果指出了目标客户端，则查询目标客户端的信息
    if (targetPeerId != null) {
      PeerClient? peerClient =
          await peerClientService.findCachedOneByPeerId(targetPeerId);
      if (peerClient != null) {
        chainMessage.targetConnectAddress = peerClient.connectAddress;
        chainMessage.targetConnectPeerId = peerClient.connectPeerId;
        targetClientId ??= peerClient.clientId;
        //如果没有指定connectPeerId，本次优先采用目标的最近连接节点
        if (connectPeerId == null) {
          connectPeerId = peerClient.connectPeerId;
          connectAddress = peerClient.connectAddress;
        }
      }
    } else {
      //消息发给连接节点，websocket协议下不用加密，libp2p自动加密
      chainMessage.needEncrypt = false;
    }
    chainMessage.targetPeerId = targetPeerId;
    chainMessage.targetClientId = targetClientId;

    //查找本次连接节点，最差是获取缺省的连接节点
    PeerEndpoint? peerEndpoint = peerEndpointController.find(
        peerId: connectPeerId, address: connectAddress);
    if (peerEndpoint != null) {
      connectPeerId = peerEndpoint.peerId;
      connectAddress = peerEndpoint.wsConnectAddress;
    }
    chainMessage.connectPeerId = connectPeerId;
    chainMessage.connectAddress = connectAddress;
    if (connectAddress != null) {
      WebSocketChannel? websocket = (await websocketPool.get(connectAddress));
      if (websocket != null) {
        chainMessage.connectSessionId = websocket.sessionId;
      }
    }

    //本客户机最近的连接节点的属性，对方回信的时候可以用于连接
    PeerEndpoint? defaultPeerEndpoint =
        peerEndpointController.defaultPeerEndpoint;
    if (defaultPeerEndpoint != null) {
      chainMessage.srcConnectAddress = defaultPeerEndpoint.wsConnectAddress;
      WebSocketChannel? websocket =
          (await websocketPool.get(defaultPeerEndpoint.wsConnectAddress!));
      if (websocket != null) {
        chainMessage.srcConnectSessionId = websocket.sessionId;
      }
    }

    if (topic == null && appDataProvider.topics.isNotEmpty) {
      topic ??= appDataProvider.topics[0];
    }
    chainMessage.topic = topic;
    chainMessage.payload = data;
    chainMessage.payloadType = payloadType?.name;
    chainMessage.messageType = msgType.name;
    chainMessage.messageDirect = MsgDirect.Request.name;
    chainMessage.uuid = StringUtil.uuid();
    chainMessage.srcPeerId = myself.peerId;
    chainMessage.srcClientId = myself.clientId;

    return chainMessage;
  }

  /// 将接收的原始数据还原成ChainMessage，然后根据消息类型进行分支处理
  /// 并将处理的结果转换成原始数据，发回去
  Future<void> receiveRaw(WebsocketData websocketData) async {
    String? remotePeerId = websocketData.peerId;
    String? remoteAddr = websocketData.address;
    List<int> data = websocketData.data;
    var json = JsonUtil.toJson(String.fromCharCodes(data));
    ChainMessage chainMessage = ChainMessage.fromJson(json);
    // 源节点的peerid和地址
    chainMessage.srcPeerId ??= remotePeerId;
    chainMessage.srcConnectAddress ??= remoteAddr;
    await receive(chainMessage);
  }

  /// 将返回的原始报文数据转换成chainmessge
  /// @param data
  /// @param remotePeerId
  /// @param remoteAddr
  Future<void> responseRaw(List<int> data,
      {String? remotePeerId, String? remoteAddr}) async {
    var json = JsonUtil.toJson(String.fromCharCodes(data));
    ChainMessage chainMessage = ChainMessage.fromJson(json);
    await receive(chainMessage);
  }

  // 发送ChainMessage消息的唯一方法
  // 1.找出发送的目标地址和方式
  // 2.根据情况处理校验，加密，压缩等
  // 3.建立合适的通道并发送，比如libp2p的Pipe并Write消息流
  // 4.等待即时的返回，校验，解密，解压缩等
  Future<bool> send(ChainMessage chainMessage) async {
    // * 消息的发送方式由二个字段决定
    // * connectPeerId表示采用篇libp2p发送到p2p节点
    // * connectAddress表示采用https，wss发送
    // 消息的发送目标：topic表示发送到主题，targetPeerId表示目标的peerId，可以时服务器节点，也可以是客户端
    /// 目前flutter没有libp2p的客户端，所以connectPeerId总是为空，不支持走libp2p协议
    var connectPeerId = chainMessage.connectPeerId;
    //本PeerClient的连接定位器地址
    var connectAddress = chainMessage.connectAddress;
    //目标PeerClient的连接定位器地址
    var targetConnectAddress = chainMessage.targetConnectAddress;
    await encrypt(chainMessage);
    //// 发送数据后返回的响应数据
    var success = false;
    dynamic result;
    try {
      if (!success &&
          targetConnectAddress != null &&
          targetConnectAddress.startsWith('ws')) {
        var websocket = await websocketPool.get(targetConnectAddress);
        // var websocket = websocketPool.getDefault();
        // if (websocket == null || websocket.status != SocketStatus.connected) {
        //   Future.delayed(const Duration(seconds: 1));
        // }
        if (websocket != null &&
            websocket.status?.name == SocketStatus.connected.name) {
          var data = MessageSerializer.marshal(chainMessage);
          success = await websocket.sendMsg(data);
        }
      }
      if (!success &&
          connectAddress != null &&
          connectAddress.startsWith('ws')) {
        var websocket = await websocketPool.get(connectAddress);
        // if (websocket == null || websocket.status != SocketStatus.connected) {
        //   Future.delayed(const Duration(seconds: 1));
        // }
        if (websocket != null) {
          var data = MessageSerializer.marshal(chainMessage);
          success = await websocket.sendMsg(data);
        }
      }
      if (!success &&
          connectAddress != null &&
          connectAddress.startsWith('http')) {
        var httpClient = httpClientPool.get(connectAddress);
        var data = JsonUtil.toJsonString(chainMessage);
        Response response = await httpClient.send('/receive', data);
        result = response.data;
        success = true;
      }
    } catch (err) {
      logger.e('send message:$err');
    }

    // 把响应数据转换成chainmessage
    if (result != null) {
      ChainMessage? response;
      if (result is Map) {
        response = ChainMessage.fromJson(result);
        await receive(response);
      } else if (result is List<int>) {
        await responseRaw(result);
      }
    }

    return success;
  }

  /// 接收报文处理的入口，包括接收请求报文和返回报文，并分配不同的处理方法
  Future<void> receive(ChainMessage chainMessage) async {
    await decrypt(chainMessage);
    var typ = chainMessage.messageType;
    var direct = chainMessage.messageDirect;
    MsgType? msgType = StringUtil.enumFromString(MsgType.values, typ);
    if (msgType == null) {
      logger.e('chainMessage has no msgType p2p action:$typ');
      return;
    }
    BaseAction? action = p2pActions[msgType];
    if (action == null) {
      logger.e('chainMessage has no register msgType p2p action:$typ');
      return;
    }
    //分发到对应注册好的处理器，主要是Receive和Response方法
    if (direct == MsgDirect.Request.name) {
      await action.receive(chainMessage);
    } else if (direct == MsgDirect.Response.name) {
      await action.response(chainMessage);
    }
  }

  /// 发送消息前负载的加密处理
  /// @param chainMessage
  Future<ChainMessage?> encrypt(ChainMessage chainMessage) async {
    List<int>? payload = chainMessage.payload as List<int>?;
    if (payload == null) {
      return null;
    }
    SecurityContext securityContext = SecurityContext();
    securityContext.needCompress = chainMessage.needCompress;
    securityContext.needEncrypt = chainMessage.needEncrypt;
    var targetPeerId = chainMessage.targetPeerId;
    securityContext.targetPeerId = targetPeerId;

    /// connectPeerId只有在libp2p协议的情况下才不为空，目前不支持
    // if (chainMessage.connectPeerId != null &&
    //     targetPeerId != null &&
    //     chainMessage.connectPeerId == targetPeerId &&
    //     securityContext.needEncrypt) {
    //   logger.e('ConnectPeerId equals TargetPeerId && NeedEncrypt is true!');
    // }
    securityContext.payload = payload;
    try {
      bool result = await linkmanCryptographySecurityContextService
          .encrypt(securityContext);
      if (result) {
        chainMessage.transportPayload =
            CryptoUtil.encodeBase64(securityContext.payload);
        chainMessage.payload = null;
        chainMessage.payloadSignature = securityContext.payloadSignature;
        chainMessage.previousPublicKeyPayloadSignature =
            securityContext.previousPublicKeyPayloadSignature;
        chainMessage.needCompress = securityContext.needCompress;
        chainMessage.needEncrypt = securityContext.needEncrypt;
      }
    } catch (err) {
      logger.e('ChainMessage encrypt error:${err.toString()}');
    }

    return chainMessage;
  }

  /// 消息接收前的解密处理
  /// @param chainMessage
  Future<ChainMessage?> decrypt(ChainMessage chainMessage) async {
    if (chainMessage.transportPayload == null) {
      return null;
    }
    SecurityContext securityContext = SecurityContext();
    securityContext.needCompress = chainMessage.needCompress;
    securityContext.needEncrypt = chainMessage.needEncrypt;
    securityContext.payloadSignature = chainMessage.payloadSignature;
    securityContext.previousPublicKeyPayloadSignature =
        chainMessage.previousPublicKeyPayloadSignature;
    var targetPeerId = chainMessage.targetPeerId;
    targetPeerId ??= chainMessage.connectPeerId;
    securityContext.targetPeerId = targetPeerId;
    securityContext.srcPeerId = chainMessage.srcPeerId;
    securityContext.payload =
        CryptoUtil.decodeBase64(chainMessage.transportPayload!);
    try {
      var result = await linkmanCryptographySecurityContextService
          .decrypt(securityContext);
      if (result) {
        chainMessage.needCompress = securityContext.needCompress;
        chainMessage.needEncrypt = securityContext.needEncrypt;
        var payload = securityContext.payload;
        if (payload != null) {
          chainMessage.payload = payload;
          chainMessage.transportPayload = '';
        }
      }
    } catch (err) {
      logger.e('ChainMessage decrypt error:${err.toString()}');
    }
    return chainMessage;
  }

  validate(ChainMessage chainMessage) {
    if (chainMessage.connectPeerId == null) {
      throw 'NullConnectPeerId';
    }
    if (chainMessage.srcPeerId == null) {
      throw 'NullSrcPeerId';
    }
  }

  /// 如果消息太大，而且被要求分片的话
  /// @param chainMessage
  List<ChainMessage> slice(ChainMessage chainMessage) {
    List<int>? payload = chainMessage.payload;
    var packSize = (chainMessage.messageType != MsgType.P2PCHAT.name)
        ? packetSize
        : webRtcPacketSize;
    if (!chainMessage.needSlice ||
        payload == null ||
        payload.length <= packSize) {
      return [chainMessage];
    }

    ///如果源已经有值，说明不是最开始的节点，不用分片
    if (chainMessage.srcPeerId != null) {
      return [chainMessage];
    }
    int sliceSize = payload.length ~/ packSize;
    //sliceSize = math.ceil(sliceSize);
    chainMessage.sliceSize = sliceSize;
    List<ChainMessage> slices = [];
    for (var i = 0; i < sliceSize; ++i) {
      ChainMessage slice = ChainMessage();
      //ObjectUtil.copy(chainMessage, slice);
      slice.sliceNumber = i;
      List<int> slicePayload;
      if (i == sliceSize - 1) {
        slicePayload = payload.sublist(i * packSize, payload.length);
      } else {
        slicePayload = payload.sublist(i * packSize, (i + 1) * packSize);
      }
      slice.payload = slicePayload;
      slices.add(slice);
    }
    return slices;
  }

  /// 如果分片进行合并
  ChainMessage? merge(ChainMessage chainMessage) {
    if (!chainMessage.needSlice || chainMessage.sliceSize < 2) {
      return chainMessage;
    }
    /**
     * 如果不是最终目标，不用合并
     */
    var targetPeerId = chainMessage.targetPeerId;
    targetPeerId ??= chainMessage.connectPeerId;
    var peerId = myself.peerId;
    if (peerId != null && targetPeerId != peerId) {
      return chainMessage;
    }
    var uuid = chainMessage.uuid;
    var sliceSize = chainMessage.sliceSize;
    if (!caches.containsKey(uuid)) {
      List<ChainMessage> slices = [];
      caches[uuid!] = slices;
    }
    List<ChainMessage>? slices = caches[uuid];
    if (slices == null) {
      return null;
    }
    slices[chainMessage.sliceNumber] = chainMessage;
    if (slices.length == sliceSize) {
      List<int> payload = [];
      for (var slice in slices) {
        List<int>? slicePayload = slice.payload;
        if (slicePayload != null) {
          payload = CryptoUtil.concat(payload, slicePayload);
        }
      }
      chainMessage.payload = payload;
      caches.remove(uuid);

      return chainMessage;
    }
    return null;
  }
}

final ChainMessageHandler chainMessageHandler = ChainMessageHandler();
