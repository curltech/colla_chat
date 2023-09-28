import 'dart:async';
import 'dart:core';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/chainmessagehandler.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/json_util.dart';

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
  list //List<int>
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

final Map<MsgType, BaseAction> p2pActions = {};

/// 发送和接受链消息的抽象类
abstract class BaseAction {
  late MsgType msgType;

  /// websocket收到的chainMessage
  StreamController<ChainMessage> receiveStreamController =
      StreamController<ChainMessage>.broadcast();

  /// websocket发送后收到返回的chainMessage
  StreamController<ChainMessage> responseStreamController =
      StreamController<ChainMessage>.broadcast();

  BaseAction(this.msgType) {
    p2pActions[msgType] = this;
    print('register msgType:$msgType');
  }

  ///发送前的预处理，设置消息的初始值
  ///如果targetPeerId不为空，指的是目标peerclient，否则是直接向connectPeerId的peerendpoint发送信息
  ///传入数据为对象，先转换成json字符串，然后utf-8格式的List<int>
  Future<ChainMessage> prepareSend(dynamic msg,
      {String? connectAddress,
      String? connectPeerId,
      String? targetPeerId,
      String? topic,
      String? targetClientId,
      PayloadType? payloadType}) async {
    List<int> data;
    if (payloadType == PayloadType.string) {
      /// 字符串数据转换成utf-8二进制
      data = CryptoUtil.stringToUtf8(msg);
    } else if (payloadType == PayloadType.list) {
      ///二进制数据直接使用
      data = msg;
    } else {
      ///其他数据先转换成json字符串，然后转换成utf-8二进制
      String payloadStr = JsonUtil.toJsonString(msg);
      data = CryptoUtil.stringToUtf8(payloadStr);
    }
    return chainMessageHandler.prepareSend(data, msgType,
        connectAddress: connectAddress,
        connectPeerId: connectPeerId,
        targetPeerId: targetPeerId,
        topic: topic,
        targetClientId: targetClientId,
        payloadType: payloadType);
  }

  /// 主动发送消息，在发送之前对消息进行必要的分片处理
  /// 接受返回的消息
  Future<bool> send(ChainMessage chainMessage) async {
    List<ChainMessage> slices = chainMessageHandler.slice(chainMessage);
    if (slices.isNotEmpty) {
      if (slices.length == 1) {
        var success = await chainMessageHandler.send(slices[0]);
        return success;
      } else {
        List<Future<bool>> ps = [];
        for (var slice in slices) {
          var p = chainMessageHandler.send(slice);
          ps.add(p);
        }
        List<bool> results = await Future.wait(ps);
        if (results.isNotEmpty) {
          for (var result in results) {
            if (!result) {
              return false;
            }
          }
        }
      }
    }

    return true;
  }

  /// 接收消息进行处理的方法，在接收之前对消息进行必要的分片合并处理
  /// 缺省的行为是调用注册的接收处理器
  /// 子类可以覆盖这个方法，或者注册自己的接收处理器
  Future<void> receive(ChainMessage chainMessage) async {
    ChainMessage? chainMessage_ = chainMessageHandler.merge(chainMessage);
    if (chainMessage_ != null) {
      await transferPayload(chainMessage_);
      receiveStreamController.add(chainMessage_);
    } else {
      logger.e('receive chainMessage merge failure');
    }
  }

  /// 返回消息进行处理的方法，
  /// 缺省的行为是调用注册的返回处理器
  /// 子类可以覆盖这个方法，或者注册自己的返回处理器
  Future<void> response(ChainMessage chainMessage) async {
    await transferPayload(chainMessage);
    responseStreamController.add(chainMessage);
  }

  ///将消息负载转换成具体类型的消息负载
  ///将List<int>数据还原utf-8字符串，然后转换成对象
  Future<void> transferPayload(ChainMessage chainMessage) async {
    ///返回是是utf-8二进制
    List<int> data = chainMessage.payload;
    dynamic payload;
    var payloadType = chainMessage.payloadType;
    if (payloadType == PayloadType.string.name) {
      payload = CryptoUtil.utf8ToString(data);
    } else if (payloadType == PayloadType.list.name) {
      payload = chainMessage.payload;
    } else {
      String payloadStr = CryptoUtil.utf8ToString(data);
      payload = JsonUtil.toJson(payloadStr);
    }

    chainMessage.payload = payload;
  }
}
