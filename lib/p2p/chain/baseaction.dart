import 'dart:core';

import '../../app.dart';
import '../../entity/p2p/message.dart';
import 'chainmessagehandler.dart';

enum PayloadType {
  PeerClient,
  PeerEndpoint,
  ChainApp,
  DataBlock,
  ConsensusLog,
  PeerClients,
  PeerEndpoints,
  ChainApps,
  DataBlocks,
  String,
  Map,
}

class NamespacePrefix {
  static String PeerEndpoint = 'peerEndpoint';
  static String PeerClient = 'peerClient';
  static String PeerClient_Mobile = 'peerClientMobile';
  static String ChainApp = 'chainApp';
  static String DataBlock = 'dataBlock';
  static String DataBlock_Owner = 'dataBlockOwner';
  static String PeerTransaction_Src = 'peerTransactionSrc';
  static String PeerTransaction_Target = 'peerTransactionTarget';
  static String TransactionKey = 'transactionKey';

  static String getPeerEndpointKey(String peerId) {
    String key = '/' + NamespacePrefix.PeerEndpoint + '/' + peerId;

    return key;
  }

  static String getPeerClientKey(String peerId) {
    String key = '/' + NamespacePrefix.PeerClient + '/' + peerId;

    return key;
  }

  static String getPeerClientMobileKey(String mobile) {
    //mobileHash:= std.EncodeBase64(std.Hash(mobile, "sha3_256"))
    String key = '/' + NamespacePrefix.PeerClient_Mobile + '/' + mobile;

    return key;
  }

  static String getChainAppKey(String peerId) {
    String key = '/' + NamespacePrefix.ChainApp + '/' + peerId;

    return key;
  }

  static String getDataBlockKey(String blockId) {
    String key = '/' + NamespacePrefix.DataBlock + '/' + blockId;

    return key;
  }
}

/// 发送和接受链消息的抽象类
abstract class BaseAction {
  late MsgType msgType;
  Map<String, dynamic> receivers = <String, dynamic>{};

  BaseAction(MsgType msgType) {
    this.msgType = msgType;
    chainMessageDispatch.registerChainMessageHandler(
        msgType.name, send, receive, response);
  }

  ///注册接收消息的处理器
  bool registerReceiver(String name, dynamic receiver) {
    if (receivers.containsKey(name)) {
      return false;
    }
    receivers[name] = receiver;

    return true;
  }

  ///发送前的预处理，设置消息的初始值
  Future<ChainMessage> prepareSend(dynamic data,
      {String? connectAddress,
      String? connectPeerId,
      String? topic,
      String? targetPeerId}) async {
    ChainMessage chainMessage = ChainMessage();
    var appParams = AppParams.instance;
    if (connectAddress == null) {
      if (appParams.wsConnectAddress.isNotEmpty) {
        connectAddress = appParams.wsConnectAddress[0];
      } else if (appParams.httpConnectAddress.isNotEmpty) {
        connectAddress = appParams.httpConnectAddress[0];
      }
    }
    chainMessage.connectAddress = connectAddress;
    if (appParams.connectPeerId.isNotEmpty) {
      connectPeerId = appParams.connectPeerId[0];
      chainMessage.connectPeerId = connectPeerId;
    }
    if (topic == null && appParams.topics.isNotEmpty) {
      topic ??= appParams.topics[0];
    }
    chainMessage.topic = topic;
    chainMessage.payload = data;
    chainMessage.targetPeerId = targetPeerId;
    chainMessage.payloadType = PayloadType.Map.name;
    chainMessage.messageType = msgType.name;
    chainMessage.messageDirect = MsgDirect.Request.name;
    chainMessage.needCompress = true;
    chainMessage.needEncrypt = false;
    chainMessage.uuid = '';

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

  /// 接收消息进行处理，在接收之前对消息进行必要的分片合并处理
  /// 返回为空则没有返回消息，否则，有返回消息
  Future<ChainMessage?> receive(ChainMessage chainMessage) async {
    return chainMessageHandler.merge(chainMessage);
  }

  ///  处理返回消息
  Future<ChainMessage> response(ChainMessage chainMessage) async {
    return chainMessage;
  }
}
