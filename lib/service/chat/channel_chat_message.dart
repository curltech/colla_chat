import 'dart:async';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/linkman.dart';

class ChannelChatMessageService {
  ///获取所有的其他人的频道消息
  Future<List<ChatMessage>> findOthersByPeerId(
      {String? peerId, int? offset, int? limit}) async {
    var myselfPeerId = myself.peerId!;
    String where = 'messageType=? and receiverPeerId=?';
    List<Object> whereArgs = [ChatMessageType.channel.name, myselfPeerId];
    if (peerId != null) {
      where = '$where and senderPeerId=?';
      whereArgs.add(peerId);
    }
    return await chatMessageService.find(
        where: where,
        whereArgs: whereArgs,
        orderBy: 'sendTime desc',
        offset: offset,
        limit: limit);
  }

  Future<List<ChatMessage>> findOthersByGreaterId(
      {String? peerId, String? sendTime, int? limit}) async {
    var myselfPeerId = myself.peerId!;
    String where = 'messageType=? and receiverPeerId=?';
    List<Object> whereArgs = [ChatMessageType.channel.name, myselfPeerId];
    if (peerId != null) {
      where = '$where and senderPeerId=?';
      whereArgs.add(peerId);
    }
    if (sendTime != null) {
      where = '$where and sendTime>?';
      whereArgs.add(sendTime);
    }
    return await chatMessageService.find(
        where: where,
        whereArgs: whereArgs,
        orderBy: 'sendTime desc',
        limit: limit);
  }

  ///获取自己的频道消息
  Future<List<ChatMessage>> findMyselfByPeerId(
      {String? status, int? offset, int? limit}) async {
    var myselfPeerId = myself.peerId!;
    String where = 'messageType=? and senderPeerId=?';
    List<Object> whereArgs = [ChatMessageType.channel.name, myselfPeerId];
    if (status != null) {
      where = '$where and status=?';
      whereArgs.add(status);
    }
    return await chatMessageService.find(
        where: where,
        whereArgs: whereArgs,
        orderBy: 'sendTime desc',
        offset: offset,
        limit: limit);
  }

  Future<List<ChatMessage>> findMyselfByGreaterId(
      {String? status, String? sendTime, int? limit}) async {
    var myselfPeerId = myself.peerId!;
    String where = 'messageType=? and senderPeerId=?';
    List<Object> whereArgs = [ChatMessageType.channel.name, myselfPeerId];
    if (status != null) {
      where = '$where and status=?';
      whereArgs.add(status);
    }
    if (sendTime != null) {
      where = '$where and sendTime>?';
      whereArgs.add(sendTime);
    }
    return await chatMessageService.find(
        where: where,
        whereArgs: whereArgs,
        orderBy: 'sendTime desc',
        limit: limit);
  }

  ///发出更新频道消息的请求
  Future<ChatMessage?> getChannel(String peerId,
      {String? clientId,
      CryptoOption cryptoOption = CryptoOption.cryptography}) async {
    Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
    if (linkman == null) {
      return null;
    }
    if (linkman.subscriptStatus != LinkmanStatus.subscript.name) {
      return null;
    }
    List<ChatMessage> chatMessages =
        await findOthersByPeerId(peerId: peerId, limit: 1);
    String? sendTime;
    if (chatMessages.isNotEmpty) {
      sendTime = chatMessages[0].sendTime;
    }
    ChatMessage chatMessage = await chatMessageService.buildChatMessage(
      receiverPeerId: peerId,
      clientId: clientId,
      content: sendTime,
      messageType: ChatMessageType.system,
      subMessageType: ChatMessageSubType.getChannel,
    );
    return await chatMessageService.sendAndStore(chatMessage,
        cryptoOption: cryptoOption);
  }

  ///接收到更新频道消息的请求,发送发布的频道消息
  receiveGetChannel(ChatMessage chatMessage) async {
    var subMessageType = chatMessage.subMessageType;
    if (ChatMessageSubType.getChannel.name != subMessageType) {
      return;
    }
    String? sendTime = chatMessage.sendTime;
    List<ChatMessage> chatMessages = await findMyselfByGreaterId(
        status: MessageStatus.published.name, sendTime: sendTime);
    if (chatMessages.isNotEmpty) {
      for (var msg in chatMessages) {
        msg.receiverPeerId = chatMessage.senderPeerId;
        msg.receiverName = chatMessage.senderName;
        msg.senderClientId = chatMessage.senderClientId;
        await chatMessageService.send(msg);
      }
    }
  }
}

///频道消息相关的服务
final channelChatMessageService = ChannelChatMessageService();
