import 'dart:async';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';

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
}

///频道消息相关的服务
final channelChatMessageService = ChannelChatMessageService();
