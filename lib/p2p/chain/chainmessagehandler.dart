import '../../entity/dht/base.dart';
import '../../tool/util.dart';
import '../message.dart';
import '../payload.dart';

const packetSize = 4 * 1024 * 1024;
const webRtcPacketSize = 128 * 1024;

/// 原始消息的分派处理
class ChainMessageHandler {
  Map<String, List<ChainMessage>> caches = <String, List<ChainMessage>>{};

  ChainMessageHandler() {
    // libp2pClientPool.registProtocolHandler(config.appParams.chainProtocolId, this.receiveRaw);
    // webrtcPeerPool.registProtocolHandler(config.appParams.chainProtocolId, this.receiveRaw);
    // ionSfuClientPool.registProtocolHandler(config.appParams.chainProtocolId, this.receiveRaw);
  }

  /**
      将接收的原始数据还原成ChainMessage，然后根据消息类型进行分支处理
      并将处理的结果转换成原始数据，发回去
   */
  Future<List<int>> receiveRaw(List<int> data, String remotePeerId,
      String remoteAddr) async {
    ChainMessage response;
    var json = JsonUtil.toMap(String.fromCharCodes(data));
    ChainMessage chainMessage = ChainMessage.fromJson(json);
    // 源节点的id和地址
    chainMessage.SrcPeerId ??= remotePeerId;
    chainMessage.SrcAddress ??= remoteAddr;
    // 本次连接的源节点id和地址
    chainMessage.LocalConnectPeerId = remotePeerId;
    chainMessage.LocalConnectAddress = remoteAddr;
    response = await chainMessageHandler.receive(chainMessage);
    /**
     * 把响应报文转成原始数据
     */
    if (response != null) {
      try {
        await chainMessageHandler.encrypt(response);
      }
      catch
      (err) {
        response = chainMessageHandler.error(chainMessage.MessageType, err);
      }
      chainMessageHandler.setResponse(chainMessage, response);
      List<int> responseData = MessageSerializer.marshal(response);

      return
        responseData;
    }
    return
      null;
  }

  /// 将返回的原始报文数据转换成chainmessge
  /// @param data
  /// @param remotePeerId
  /// @param remoteAddr
  Future<ChainMessage> responseRaw(List<int> data, String remotePeerId,
      String remoteAddr) async {
    ChainMessage response;
    var json = JsonUtil.toMap(String.fromCharCodes(data));
    ChainMessage chainMessage = ChainMessage.fromJson(json);
    chainMessage.LocalConnectPeerId = remotePeerId;
    chainMessage.LocalConnectAddress = remoteAddr;
    response = await chainMessageHandler.receive(chainMessage);

    return response;
  }

  /**
      发送ChainMessage消息的唯一方法
      1.找出发送的目标地址和方式
      2.根据情况处理校验，加密，压缩等
      3.建立合适的通道并发送，比如libp2p的Pipe并Write消息流
      4.等待即时的返回，校验，解密，解压缩等
   */
  Future<ChainMessage> send(ChainMessage msg) async {
    /**
     * 消息的发送目标由三个字段决定，topic表示发送到主题
     * targetPeerId表示发送到p2p节点
     * targetAddress表示采用外部发送方式，比如http，wss
     */
    var
    targetPeerId = msg.TargetPeerId;
    var topic = msg.Topic;
    var connectPeerId = msg.ConnectPeerId;
    var connectAddress = msg.ConnectAddress;
    List<int> data;
    if (msg.MessageType != MsgType.P2PCHAT.toString()) {
      await chainMessageHandler.encrypt(msg);
      data = MessageSerializer.marshal(msg);
    }
    /**
     * 发送数据后返回的响应数据
     */
    var success = false;
    var result = null;
    try {
      if (targetPeerId) {
    var
    webrtcPeers
    : WebrtcPeer[] = webrtcPeerPool.getConnected(targetPeerId);
    if ((msg.MessageType != MsgType[MsgType.P2PCHAT] || (msg.MessageType == MsgType[MsgType.P2PCHAT] && msg.Payload.payload.length <= webRtcPacketSize)) && (webrtcPeers && webrtcPeers.length > 0)) {
    success = true;
    if (msg.MessageType == MsgType[MsgType.P2PCHAT]) {
    msg.Payload = msg.Payload.payload;
    await chainMessageHandler.encrypt(msg);
    data = messageSerializer.marshal(msg);
    }
    // @ts-ignore
    if (data) {
    result = await webrtcPeerPool.send(targetPeerId, data);
    }
    }
    }
    if (success == false && connectPeerId) {
    success = true;
    if (msg.MessageType == MsgType[MsgType.P2PCHAT]) {
    msg.Payload.payload = null;
    msg.PayloadType = PayloadType.DataBlock;
    await chainMessageHandler.encrypt(msg);
    data = messageSerializer.marshal(msg);
    }
    if (data) {
    result = await libp2pClientPool.send(connectPeerId, p2pPeer.chainProtocolId, data);
    }
    }
    if (success == false && connectAddress) {
    if (connectAddress.startsWith('ws')) {
    var websocket = websocketPool.get(connectAddress);
    if (websocket) {
    success = true;
    if (data) {
    result = websocket.sendMsg(data);
    }
    }
    }
    if (success == false && connectAddress.startsWith('http')) {
    var httpClient = httpClientPool.get(connectAddress);
    if (httpClient) {
    success = true;
    result = httpClient.send('/receive', data);
    }
    }
    }
    if (topic) {
    if (data) {
    result = await pubsubPool.send(topic, data);
    }
    }
    } catch (err) {
    console.error('send message:' + err);
    }
    /**
     * 把响应数据转换成chainmessage
     */
    if (result && result.data) {
    var response = await chainMessageHandler.responseRaw(result.data, result.remotePeerId, result.remoteAddr);
    return response;
    }

    return
    null;
  }

  /**
      接收报文处理的入口，包括接收请求报文和返回报文，并分配不同的处理方法
   */
  Future<ChainMessage?> receive(ChainMessage chainMessage) async {
    await chainMessageHandler.decrypt(chainMessage);
    var typ = chainMessage.MessageType;
    var direct = chainMessage.MessageDirect;
    var handlers = chainMessageDispatch.getChainMessageHandler(typ);
    ChainMessage response ;
    //分发到对应注册好的处理器，主要是Receive和Response方法
    if (direct == MsgDirect.Request.toString()) {
    try {
    response = await receiveHandler(chainMessage);
    } catch (err) {
    print('receiveHandler chainMessage:' + err.toString());
    response = chainMessageHandler.error(typ, err);

    return response;
    }
    } else if (direct == MsgDirect.Response.toString()) {
    response = await responseHandler(chainMessage);
    }

    return response;
  }

  /**
   * 发送消息前负载的加密处理
   * @param chainMessage
   */
  Future<ChainMessage?> encrypt(ChainMessage chainMessage) async {
    var payload = chainMessage.Payload;
    if (!payload) {
      return null;
    }
    SecurityParams
    securityParams = SecurityParams();
    securityParams.NeedCompress = chainMessage.NeedCompress;
    securityParams.NeedEncrypt = chainMessage.NeedEncrypt;
    var targetPeerId = chainMessage.TargetPeerId;
    if (targetPeerId == null) {
      targetPeerId = chainMessage.ConnectPeerId;
    }
    securityParams.TargetPeerId = targetPeerId;
    if (chainMessage.ConnectPeerId != null && targetPeerId != null &&
        chainMessage.ConnectPeerId.contains(targetPeerId) &&
        securityParams.NeedEncrypt) {
      print('ConnectPeerId equals TargetPeerId && NeedEncrypt is true!');
    }
    SecurityParams result = await SecurityPayload.encrypt(
        payload, securityParams);
    if (result != null) {
      chainMessage.TransportPayload = result.TransportPayload;
      chainMessage.Payload = null;
      chainMessage.PayloadSignature = result.PayloadSignature;
      chainMessage.PreviousPublicKeyPayloadSignature =
          result.PreviousPublicKeyPayloadSignature;
      chainMessage.NeedCompress = result.NeedCompress;
      chainMessage.NeedEncrypt = result.NeedEncrypt;
      chainMessage.PayloadKey = result.PayloadKey;
    }

    return
      chainMessage;
  }

  /**
   * 消息接收前的解密处理
   * @param chainMessage
   */
  Future<ChainMessage?> decrypt(ChainMessage chainMessage) async {
    if (chainMessage.TransportPayload == null) {
      return null;
    }
    SecurityParams securityParams = SecurityParams();
    securityParams.NeedCompress = chainMessage.NeedCompress;
    securityParams.NeedEncrypt = chainMessage.NeedEncrypt;
    securityParams.PayloadSignature = chainMessage.PayloadSignature;
    securityParams.PreviousPublicKeyPayloadSignature =
        chainMessage.PreviousPublicKeyPayloadSignature;
    securityParams.PayloadKey = chainMessage.PayloadKey;
    var targetPeerId = chainMessage.TargetPeerId;
    targetPeerId ??= chainMessage.ConnectPeerId;
    securityParams.TargetPeerId = targetPeerId;
    securityParams.SrcPeerId = chainMessage.SrcPeerId;
    var payload = await SecurityPayload.decrypt(
        chainMessage.TransportPayload, securityParams);
    if (payload) {
      chainMessage.Payload = payload;
      chainMessage.TransportPayload = null;
    }
  }

  ChainMessage error(String msgType, dynamic err) {
    var errMessage = ChainMessage();
    errMessage.Payload = MsgType.ERROR.toString();
    errMessage.MessageType = msgType;
    errMessage.Tip = err.message;
    errMessage.MessageDirect = MsgDirect.Response.toString();

    return errMessage;
  }

  ChainMessage response(String msgType, dynamic payload) {
    var responseMessage = new ChainMessage();
    responseMessage.Payload = payload;
    responseMessage.MessageType = msgType;
    responseMessage.MessageDirect = MsgDirect.Response.toString();

    return responseMessage;
  }

  ChainMessage ok(String msgType) {
    var okMessage = new ChainMessage();
    okMessage.Payload = MsgType.OK.toString();
    okMessage.MessageType = msgType;
    okMessage.Tip = "OK";
    okMessage.MessageDirect = MsgDirect.Response.toString();

    return okMessage;
  }

  ChainMessage wait(String msgType) {
    var waitMessage = ChainMessage();
    waitMessage.Payload = MsgType.WAIT.toString();

    waitMessage.MessageType = msgType;

    waitMessage.Tip = "WAIT";

    waitMessage.MessageDirect = MsgDirect.Response.toString();

    return waitMessage;
  }

  setResponse(ChainMessage request, ChainMessage response) {
    response.LocalConnectAddress = "";
    response.LocalConnectPeerId = "";
    response.ConnectAddress = request.LocalConnectAddress;
    response.ConnectPeerId = request.LocalConnectPeerId;
    response.Topic = request.Topic;
  }

  validate(ChainMessage chainMessage) {
    if (chainMessage.ConnectPeerId == null) {
      throw 'NullConnectPeerId';
    }
    if (chainMessage.SrcPeerId == null) {
      throw'NullSrcPeerId';
    }
  }

  /// 如果消息太大，而且被要求分片的话
  /// @param chainMessage
  List<ChainMessage> slice(ChainMessage chainMessage) {
    var _packSize = (chainMessage.MessageType != MsgType.P2PCHAT.toString())
        ? packetSize
        : webRtcPacketSize;
    if (chainMessage.NeedSlice
        || chainMessage.Payload.length <= _packSize) {
      return [chainMessage];
    }
    /**
     * 如果源已经有值，说明不是最开始的节点，不用分片
     */
    if (chainMessage.SrcPeerId != null) {
      return [chainMessage];
    }
    var _payload = chainMessage.Payload;

    int sliceSize = chainMessage.Payload.length / _packSize;
    //sliceSize = math.ceil(sliceSize);
    chainMessage.SliceSize = sliceSize;
    List<ChainMessage> slices = [];
    for (var i = 0; i < sliceSize; ++i) {
      ChainMessage slice = ChainMessage();
      //ObjectUtil.copy(chainMessage, slice);
      slice.SliceNumber = i;
      var slicePayload = null;
      if (i == sliceSize - 1) {
        slicePayload = _payload.substr(i * _packSize, _payload.length);
      } else {
        slicePayload = _payload.substring(i * _packSize, (i + 1) * _packSize);
      }
      slice.Payload = slicePayload;
      slices.add(slice);
    }
    return
      slices;
  }

  /// 如果分片进行合并
  ChainMessage? merge(ChainMessage chainMessage) {
    if (!chainMessage.NeedSlice
        || chainMessage.SliceSize == null || chainMessage.SliceSize < 2) {
      return chainMessage;
    }
    /**
     * 如果不是最终目标，不用合并
     */
    var targetPeerId = chainMessage.TargetPeerId;
    targetPeerId ??= chainMessage.ConnectPeerId;
    if (targetPeerId != myself.myselfPeer.peerId) {
      return chainMessage;
    }
    var uuid = chainMessage.UUID;
    var sliceSize = chainMessage.SliceSize;
    if (!caches.containsKey(uuid)) {
      List<ChainMessage> slices = [];
      caches[uuid] = slices;
    }
    List<ChainMessage>? slices = this.caches[uuid];
    if (slices == null) {
      return null;
    }
    slices[chainMessage.SliceNumber] = chainMessage;
    if (slices.length == sliceSize) {
      var payload = null;
      for (var slice in slices) {
        var _payload = slice.Payload;
        payload = payload ? payload + _payload : _payload;
      }
      print("merge");
      print(chainMessage);
      print(payload);
      chainMessage.Payload = payload;
      caches.remove(uuid);

      return chainMessage;
    }
    return null;
  }
}

var chainMessageHandler = ChainMessageHandler();

/// 根据ChainMessage的类型进行分派
class ChainMessageDispatch {
  /**
      为每个消息类型注册接收和发送的处理函数，从ChainMessage中解析出消息类型，自动分发到合适的处理函数
   */
  Map<String,dynamic> chainMessageHandlers = {};


  Map<String,dynamic> getChainMessageHandler(String msgType) {
    return chainMessageHandlers[msgType];
  }

  registChainMessageHandler(String msgType,
      dynamic sendHandler,
      dynamic receiveHandler,
      dynamic responseHandler) {
    dynamic chainMessageHandler = {
      'sendHandler': sendHandler,
      'receiveHandler': receiveHandler,
      'responseHandler': responseHandler
    };

    chainMessageHandlers[msgType] = chainMessageHandler;
  }
}

var chainMessageDispatch = ChainMessageDispatch();
