import 'dart:core';

import 'package:colla_chat/tool/json_util.dart';
import 'package:uuid/uuid.dart';

import '../../crypto/util.dart';
import '../../entity/dht/myself.dart';
import '../../entity/p2p/chain_message.dart';
import '../../provider/app_data_provider.dart';
import 'chainmessagehandler.dart';

enum PayloadType {
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

const int compressLimit = 2048;

/// 发送和接受链消息的抽象类
abstract class BaseAction {
  late MsgType msgType;
  List<dynamic Function(ChainMessage)> receivers = [];

  List<Future<void> Function(ChainMessage)> responsers = [];

  BaseAction(this.msgType) {
    chainMessageDispatch.registerChainMessageHandler(
        msgType.name, send, receive, response);
  }

  ///注册接收消息的处理器
  void registerReceiver(dynamic Function(ChainMessage) receiver) {
    receivers.add(receiver);
  }

  void registerResponser(Future<void> Function(ChainMessage) responser) {
    responsers.add(responser);
  }

  ///发送前的预处理，设置消息的初始值
  Future<ChainMessage> prepareSend(dynamic data,
      {String? connectAddress,
      String? connectPeerId,
      String? topic,
      String? targetPeerId,
      String? targetClientId}) async {
    ChainMessage chainMessage = ChainMessage();
    if (connectAddress == null) {
      if (appDataProvider.nodeAddress.isNotEmpty) {
        connectAddress = appDataProvider.defaultNodeAddress.wsConnectAddress;
        connectAddress ??=
            appDataProvider.defaultNodeAddress.httpConnectAddress;
      }
    }
    chainMessage.connectAddress = connectAddress;
    if (connectPeerId == null) {
      if (appDataProvider.nodeAddress.isNotEmpty) {
        connectPeerId = appDataProvider.defaultNodeAddress.connectPeerId;
      }
    }
    chainMessage.connectPeerId = connectPeerId;

    if (topic == null && appDataProvider.topics.isNotEmpty) {
      topic ??= appDataProvider.topics[0];
    }
    chainMessage.topic = topic;
    //把负载变成字符串格式
    var jsonStr = JsonUtil.toJsonString(data);

    /// 把负载变成utf8的二进制的数组，方便计数和进一步的处理
    List<int> payload = CryptoUtil.stringToUtf8(jsonStr);
    chainMessage.payload = payload;
    if (payload.length < compressLimit) {
      chainMessage.needCompress = false;
    }

    /// 当targetPeerId不为空的时候才可以进行加密，否则没有对方的公钥
    /// 所以消息发送给客户端时必须有targetPeerId有客户端的peerId，必须加密
    if (targetPeerId == null) {
      chainMessage.needEncrypt = false;
      targetPeerId = connectPeerId;
    }
    chainMessage.targetPeerId = targetPeerId;
    chainMessage.clientId = targetClientId;
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
        dynamic responsePayload = receiver(chainMessage_);
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
    if (responsers.isNotEmpty) {
      await transferPayload(chainMessage);
      for (var responser in responsers) {
        responser(chainMessage);
      }
    }
    return;
  }

  ///将消息负载转换成具体类型的消息负载
  Future<void> transferPayload(ChainMessage chainMessage) async {}
}
