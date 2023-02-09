import 'dart:core';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/chainmessagehandler.dart';
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
  List<Future<void> Function(ChainMessage)> receivers = [];

  List<Future<void> Function(ChainMessage)> responsors = [];

  BaseAction(this.msgType) {
    chainMessageDispatch.registerChainMessageHandler(
        msgType.name, receive, response);
  }

  ///注册接收消息的处理器
  void registerReceiver(Future<void> Function(ChainMessage) receiver) {
    receivers.add(receiver);
  }

  void registerResponsor(Future<void> Function(ChainMessage) responsor) {
    responsors.add(responsor);
  }

  void unregisterReceiver(Future<void> Function(ChainMessage) receiver) {
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
    return chainMessageHandler.prepareSend(data, msgType,
        connectAddress: connectAddress,
        connectPeerId: connectPeerId,
        targetPeerId: targetPeerId,
        topic: topic,
        targetClientId: targetClientId);
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
    var chainMessage_ = chainMessageHandler.merge(chainMessage);
    if (chainMessage_ != null && receivers.isNotEmpty) {
      await transferPayload(chainMessage_);
      for (var receiver in receivers) {
        await receiver(chainMessage_);
      }
    }
    return;
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
