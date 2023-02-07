import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/p2p/message_serializer.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/httpclient.dart';
import 'package:colla_chat/transport/websocket.dart';
import 'package:dio/dio.dart';

const packetSize = 4 * 1024 * 1024;
const webRtcPacketSize = 128 * 1024;

/// 原始消息的分派处理
class ChainMessageHandler {
  Map<String, List<ChainMessage>> caches = <String, List<ChainMessage>>{};

  ChainMessageHandler() {
    // webrtcPeerPool.registProtocolHandler(config.appParams.chainProtocolId, this.receiveRaw);
    // ionSfuClientPool.registProtocolHandler(config.appParams.chainProtocolId, this.receiveRaw);
  }

  /// 将接收的原始数据还原成ChainMessage，然后根据消息类型进行分支处理
  ///    并将处理的结果转换成原始数据，发回去
  Future<List<int>?> receiveRaw(
      List<int> data, String remotePeerId, String remoteAddr) async {
    ChainMessage? response;
    var json = JsonUtil.toJson(String.fromCharCodes(data));
    ChainMessage chainMessage = ChainMessage.fromJson(json);
    // 源节点的id和地址
    chainMessage.srcPeerId ??= remotePeerId;
    chainMessage.srcAddress ??= remoteAddr;
    response = await chainMessageHandler.receive(chainMessage);

    ///把响应报文转成原始数据
    if (response != null) {
      try {
        await chainMessageHandler.encrypt(response);
      } catch (err) {
        response =
            chainMessageHandler.error(chainMessage.messageType, err.toString());
      }
      chainMessageHandler.setResponse(chainMessage, response);
      List<int> responseData = MessageSerializer.marshal(response);

      return responseData;
    }
    return null;
  }

  /// 将返回的原始报文数据转换成chainmessge
  /// @param data
  /// @param remotePeerId
  /// @param remoteAddr
  Future<ChainMessage?> responseRaw(List<int> data,
      {String? remotePeerId, String? remoteAddr}) async {
    ChainMessage? response;
    var json = JsonUtil.toJson(String.fromCharCodes(data));
    ChainMessage chainMessage = ChainMessage.fromJson(json);
    response = await chainMessageHandler.receive(chainMessage);

    return response;
  }

  // 发送ChainMessage消息的唯一方法
  // 1.找出发送的目标地址和方式
  // 2.根据情况处理校验，加密，压缩等
  // 3.建立合适的通道并发送，比如libp2p的Pipe并Write消息流
  // 4.等待即时的返回，校验，解密，解压缩等
  Future<ChainMessage?> send(ChainMessage msg) async {
    // * 消息的发送方式由二个字段决定
    // * connectPeerId表示采用篇libp2p发送到p2p节点
    // * connectAddress表示采用https，wss发送
    // 消息的发送目标：topic表示发送到主题，targetPeerId表示目标的peerId，可以时服务器节点，也可以是客户端
    /// 目前flutter没有libp2p的客户端，所以connectPeerId总是为空，不支持走libp2p协议
    var connectPeerId = msg.connectPeerId;
    var connectAddress = msg.connectAddress;
    await chainMessageHandler.encrypt(msg);
    //// 发送数据后返回的响应数据
    var success = false;
    dynamic result;
    try {
      if (!success &&
          connectAddress != null &&
          connectAddress.startsWith('ws')) {
        var websocket = await websocketPool.get(connectAddress);
        if (websocket != null) {
          var data = MessageSerializer.marshal(msg);
          success = await websocket.sendMsg(data);
        }
      }
      if (!success &&
          connectAddress != null &&
          connectAddress.startsWith('http')) {
        var httpClient = HttpClientPool.instance.get(connectAddress);
        if (httpClient != null) {
          var data = JsonUtil.toJsonString(msg);
          Response response = await httpClient.send('/receive', data);
          result = response.data;
          success = true;
        }
      }
      if (!success) {
        throw 'send failure';
      }
    } catch (err) {
      logger.e('send message:$err');
      throw err.toString();
    }

    // 把响应数据转换成chainmessage
    if (result != null) {
      ChainMessage? response;
      if (result is Map) {
        response = ChainMessage.fromJson(result);
        response = await chainMessageHandler.receive(response);
      } else if (result is List<int>) {
        response = await chainMessageHandler.responseRaw(result);
      }

      return response;
    }

    return null;
  }

  ///   接收报文处理的入口，包括接收请求报文和返回报文，并分配不同的处理方法
  Future<ChainMessage?> receive(ChainMessage chainMessage) async {
    await chainMessageHandler.decrypt(chainMessage);
    var typ = chainMessage.messageType;
    var direct = chainMessage.messageDirect;
    var handlers = chainMessageDispatch.getChainMessageHandler(typ);
    var sendHandler = handlers['sendHandler'];
    var receiveHandler = handlers['receiveHandler'];
    var responseHandler = handlers['responseHandler'];
    ChainMessage? response;
    //分发到对应注册好的处理器，主要是Receive和Response方法
    if (direct == MsgDirect.Request.name) {
      try {
        response = await receiveHandler(chainMessage);
      } catch (err) {
        logger.e('receiveHandler chainMessage:$err');
        response = chainMessageHandler.error(typ, err.toString());

        return response;
      }
    } else if (direct == MsgDirect.Response.name) {
      response = await responseHandler(chainMessage);
    }

    return response;
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
      bool result =
          await cryptographySecurityContextService.encrypt(securityContext);
      if (result) {
        chainMessage.transportPayload =
            CryptoUtil.encodeBase64(securityContext.payload);
        chainMessage.payload = null;
        chainMessage.payloadSignature = securityContext.payloadSignature;
        chainMessage.previousPublicKeyPayloadSignature =
            securityContext.previousPublicKeyPayloadSignature;
        chainMessage.needCompress = securityContext.needCompress;
        chainMessage.needEncrypt = securityContext.needEncrypt;
        chainMessage.payloadKey = securityContext.payloadKey;
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
    securityContext.payloadKey = chainMessage.payloadKey;
    var targetPeerId = chainMessage.targetPeerId;
    targetPeerId ??= chainMessage.connectPeerId;
    securityContext.targetPeerId = targetPeerId;
    securityContext.srcPeerId = chainMessage.srcPeerId;
    securityContext.payload =
        CryptoUtil.decodeBase64(chainMessage.transportPayload!);
    try {
      var result =
          await cryptographySecurityContextService.decrypt(securityContext);
      if (result) {
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

  ChainMessage error(String msgType, dynamic err) {
    var errMessage = ChainMessage();
    errMessage.payload = MsgType.ERROR.name.codeUnits;
    errMessage.messageType = msgType;
    errMessage.tip = err;
    errMessage.messageDirect = MsgDirect.Response.name;

    return errMessage;
  }

  ChainMessage response(String msgType, dynamic payload) {
    var responseMessage = ChainMessage();
    responseMessage.payload = payload;
    responseMessage.messageType = msgType;
    responseMessage.messageDirect = MsgDirect.Response.name;

    return responseMessage;
  }

  ChainMessage ok(String msgType) {
    var okMessage = ChainMessage();
    okMessage.payload = MsgType.OK.name.codeUnits;
    okMessage.messageType = msgType;
    okMessage.tip = "OK";
    okMessage.messageDirect = MsgDirect.Response.name;

    return okMessage;
  }

  ChainMessage wait(String msgType) {
    var waitMessage = ChainMessage();
    waitMessage.payload = MsgType.WAIT.name.codeUnits;

    waitMessage.messageType = msgType;

    waitMessage.tip = "WAIT";

    waitMessage.messageDirect = MsgDirect.Response.name;

    return waitMessage;
  }

  setResponse(ChainMessage request, ChainMessage response) {
    response.connectAddress = request.connectAddress;
    response.connectPeerId = request.connectPeerId;
    response.topic = request.topic;
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
    List<int> payload = chainMessage.payload as List<int>;
    var _packSize = (chainMessage.messageType != MsgType.P2PCHAT.name)
        ? packetSize
        : webRtcPacketSize;
    if (!chainMessage.needSlice || payload.length <= _packSize) {
      return [chainMessage];
    }

    ///如果源已经有值，说明不是最开始的节点，不用分片
    if (chainMessage.srcPeerId != null) {
      return [chainMessage];
    }
    int sliceSize = payload.length ~/ _packSize;
    //sliceSize = math.ceil(sliceSize);
    chainMessage.sliceSize = sliceSize;
    List<ChainMessage> slices = [];
    for (var i = 0; i < sliceSize; ++i) {
      ChainMessage slice = ChainMessage();
      //ObjectUtil.copy(chainMessage, slice);
      slice.sliceNumber = i;
      List<int> slicePayload;
      if (i == sliceSize - 1) {
        slicePayload = payload.sublist(i * _packSize, payload.length);
      } else {
        slicePayload = payload.sublist(i * _packSize, (i + 1) * _packSize);
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

var chainMessageHandler = ChainMessageHandler();

/// 根据ChainMessage的类型进行分派
class ChainMessageDispatch {
  //   为每个消息类型注册接收和发送的处理函数，从ChainMessage中解析出消息类型，自动分发到合适的处理函数

  Map<String, Map<String, dynamic>> chainMessageHandlers = {};

  Map<String, dynamic> getChainMessageHandler(String msgType) {
    var chainMessageHandler = chainMessageHandlers[msgType];
    if (chainMessageHandler != null) {
      return chainMessageHandler;
    }
    throw '';
  }

  registerChainMessageHandler(String msgType, dynamic sendHandler,
      dynamic receiveHandler, dynamic responseHandler) {
    Map<String, dynamic> chainMessageHandler = {
      'sendHandler': sendHandler,
      'receiveHandler': receiveHandler,
      'responseHandler': responseHandler
    };

    chainMessageHandlers[msgType] = chainMessageHandler;
  }
}

var chainMessageDispatch = ChainMessageDispatch();
