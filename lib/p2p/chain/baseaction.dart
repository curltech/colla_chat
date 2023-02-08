import 'dart:core';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/chainmessagehandler.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/websocket.dart';
import 'package:uuid/uuid.dart';

enum PayloadType {
  chatMessage,
  peerClient,
  peerEndpoint,
  chainApp,
  dataBlock,
  consensusLog,
  peerClients,
  peerEndpoints,
  chainApps,
  dataBlocks,
  string,
  map,
}

class NamespacePrefix {
  static String peerEndpoint = 'peerEndpoint';
  static String peerClient = 'peerClient';
  static String peerClientMobile = 'peerClientMobile';
  static String chainApp = 'chainApp';
  static String dataBlock = 'dataBlock';
  static String dataBlockOwner = 'dataBlockOwner';
  static String peerTransactionSrc = 'peerTransactionSrc';
  static String peerTransactionTarget = 'peerTransactionTarget';
  static String transactionKey = 'transactionKey';

  static String getPeerEndpointKey(String peerId) {
    String key = '/${NamespacePrefix.peerEndpoint}/$peerId';

    return key;
  }

  static String getPeerClientKey(String peerId) {
    String key = '/${NamespacePrefix.peerClient}/$peerId';

    return key;
  }

  static String getPeerClientMobileKey(String mobile) {
    //mobileHash:= std.EncodeBase64(std.Hash(mobile, "sha3_256"))
    String key = '/${NamespacePrefix.peerClientMobile}/$mobile';

    return key;
  }

  static String getChainAppKey(String peerId) {
    String key = '/${NamespacePrefix.chainApp}/$peerId';

    return key;
  }

  static String getDataBlockKey(String blockId) {
    String key = '/${NamespacePrefix.dataBlock}/$blockId';

    return key;
  }
}


/// 发送和接受链消息的抽象类
abstract class BaseAction {
  late MsgType msgType;
  List<dynamic Function(ChainMessage)> receivers = [];

  List<Future<void> Function(ChainMessage)> responsors = [];

  BaseAction(this.msgType) {
    chainMessageDispatch.registerChainMessageHandler(
        msgType.name, send, receive, response);
  }

  ///注册接收消息的处理器
  void registerReceiver(dynamic Function(ChainMessage) receiver) {
    receivers.add(receiver);
  }

  void registerResponsor(Future<void> Function(ChainMessage) responsor) {
    responsors.add(responsor);
  }

  void unregisterReceiver(dynamic Function(ChainMessage) receiver) {
    receivers.remove(receiver);
  }

  void unregisterResponsor(Future<void> Function(ChainMessage) responsor) {
    responsors.remove(responsor);
  }

  ///发送前的预处理，设置消息的初始值
  ///如果targetPeerId不为空，指的是目标peerclient，否则是直接向connectPeerId的peerendpoint发送信息
  ///传入数据为对象，先转换成json字符串，然后utf-8格式的List<int>
  Future<ChainMessage> prepareSend(dynamic data,
      {String? connectAddress,
      String? connectPeerId,
      String? targetPeerId,
      String? topic,
      String? targetClientId}) async {
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
    if (connectPeerId != null) {
      Websocket? websocket = await websocketPool.get(connectPeerId);
      if (websocket != null) {
        chainMessage.connectSessionId = websocket.sessionId;
      }
    }

    //本客户机最近的连接节点的属性，对方回信的时候可以用于连接
    PeerEndpoint? defaultPeerEndpoint =
        peerEndpointController.defaultPeerEndpoint;
    if (defaultPeerEndpoint != null) {
      chainMessage.srcConnectAddress = defaultPeerEndpoint.wsConnectAddress;
      chainMessage.srcConnectPeerId = defaultPeerEndpoint.peerId;
      Websocket? websocket =
          await websocketPool.get(defaultPeerEndpoint.wsConnectAddress!);
      if (websocket != null) {
        chainMessage.srcConnectSessionId = websocket.sessionId;
      }
    }

    if (topic == null && appDataProvider.topics.isNotEmpty) {
      topic ??= appDataProvider.topics[0];
    }
    chainMessage.topic = topic;
    //把负载变成字符串格式
    var jsonStr = JsonUtil.toJsonString(data);

    /// 把负载变成utf8的二进制的数组，方便计数和进一步的处理
    List<int> payload = CryptoUtil.stringToUtf8(jsonStr);
    chainMessage.payload = payload;
    chainMessage.payloadType = PayloadType.map.name;
    chainMessage.messageType = msgType.name;
    chainMessage.messageDirect = MsgDirect.Request.name;
    var uuid = const Uuid();
    chainMessage.uuid = uuid.v4();
    chainMessage.srcPeerId = myself.peerId;
    chainMessage.srcClientId = myself.clientId;

    return chainMessage;
  }

  /// 主动发送消息，在发送之前对消息进行必要的分片处理
  /// 接受返回的消息
  Future<ChainMessage?> send(ChainMessage chainMessage) async {
    List<ChainMessage> slices = chainMessageHandler.slice(chainMessage);
    if (slices.isNotEmpty) {
      if (slices.length == 1) {
        var response = await chainMessageHandler.send(slices[0]);
        return response;
      } else {
        List<Future> ps = [];
        for (var slice in slices) {
          var p = chainMessageHandler.send(slice);
          ps.add(p);
        }
        List<dynamic> responses = await Future.wait(ps);
        if (responses.length > 1) {
          var response = ChainMessage();
          //ObjectUtil.copy(responses[0], response);
          var payloads = [];
          for (var res in responses) {
            if (res && res.payload) {
              payloads.add(res.payload);
            }
          }
          response.payload = payloads;

          return response;
        }
      }
    }

    return null;
  }

  /// 接收消息进行处理的方法，在接收之前对消息进行必要的分片合并处理
  /// 缺省的行为是调用注册的接收处理器
  /// 子类可以覆盖这个方法，或者注册自己的接收处理器
  Future<ChainMessage?> receive(ChainMessage chainMessage) async {
    var chainMessage_ = chainMessageHandler.merge(chainMessage);
    if (chainMessage_ != null && receivers.isNotEmpty) {
      await transferPayload(chainMessage_);
      for (var receiver in receivers) {
        dynamic responsePayload = await receiver(chainMessage_);
        return chainMessageHandler.response(
            chainMessage.messageType, responsePayload);
      }
    }
    return null;
  }

  /// 返回消息进行处理的方法，
  /// 缺省的行为是调用注册的返回处理器
  /// 子类可以覆盖这个方法，或者注册自己的返回处理器
  Future<void> response(ChainMessage chainMessage) async {
    if (responsors.isNotEmpty) {
      await transferPayload(chainMessage);
      for (var responsor in responsors) {
        responsor(chainMessage);
      }
    }
    return;
  }

  ///将消息负载转换成具体类型的消息负载
  ///将List<int>数据还原utf-8字符串，然后转换成对象
  Future<void> transferPayload(ChainMessage chainMessage) async {
    var payload = chainMessage.payload;
    String data = CryptoUtil.utf8ToString(payload);
    var json = JsonUtil.toJson(data);
    chainMessage.payload = json;
  }
}
