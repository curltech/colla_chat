import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:uuid/uuid.dart';

import '../../constant/base.dart';
import '../../datastore/datastore.dart';
import '../../entity/chat/chat.dart';
import '../../entity/chat/contact.dart';
import '../../entity/dht/myself.dart';
import '../../entity/dht/peerclient.dart';
import '../../entity/p2p/security_context.dart';
import '../../plugin/logger.dart';
import '../../transport/webrtc/peer_connection_pool.dart';

class ChatMessageService extends GeneralBaseService<ChatMessage> {
  ChatMessageService({
    required super.tableName,
    required super.fields,
    required super.indexFields,
    super.encryptFields = const ['content', 'thumbBody', 'thumbnail', 'title'],
  }) {
    post = (Map map) {
      return ChatMessage.fromJson(map);
    };
  }

  Future<ChatMessage?> findByMessageId(String messageId) async {
    String where = 'messageId=?';
    List<Object> whereArgs = [messageId];
    return await findOne(
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<Pagination<ChatMessage>> findByMessageType(
    String messageType,
    String targetAddress,
    String subMessageType, {
    int limit = defaultLimit,
    int offset = defaultOffset,
  }) async {
    String where = 'messageType=? and targetAddress=? and subMessageType=?';
    List<Object> whereArgs = [messageType, targetAddress, subMessageType];
    var page = await findPage(
        where: where,
        whereArgs: whereArgs,
        orderBy: 'sendTime',
        offset: offset,
        limit: limit);

    return page;
  }

  Future<List<ChatMessage>> findByPeerId(
      {String? peerId,
      String? groupPeerId,
      String? direct,
      String? messageType,
      String? subMessageType,
      int? offset,
      int? limit}) async {
    String where = '1=1';
    List<Object> whereArgs = [];
    if (peerId != null) {
      where = '$where and (senderPeerId=? or receiverPeerId=?)';
      whereArgs.add(peerId);
      whereArgs.add(peerId);
    }
    //当通过群peerId查询群消息时，发送的群消息会拆分到个体的消息记录需要排除，否则重复显示
    if (groupPeerId != null) {
      where = '$where and groupPeerId=? and (direct!=? or receiverType!=?)';
      whereArgs.add(groupPeerId);
      whereArgs.add(ChatDirect.send.name);
      whereArgs.add(PartyType.linkman.name);
    }
    if (direct != null) {
      where = '$where and direct=?';
      whereArgs.add(direct);
    }
    if (messageType != null) {
      where = '$where and messageType=?';
      whereArgs.add(messageType);
    } else {
      where = '$where and messageType!=?';
      whereArgs.add(ChatMessageType.system.name);
    }
    if (subMessageType != null) {
      where = '$where and subMessageType=?';
      whereArgs.add(subMessageType);
    }
    return find(
        where: where,
        whereArgs: whereArgs,
        orderBy: 'id desc',
        offset: offset,
        limit: limit);
  }

  Future<List<ChatMessage>> findByGreaterId(
      {String? peerId,
      String? groupPeerId,
      String? direct,
      String? messageType,
      String? subMessageType,
      int? id,
      int? limit}) async {
    String where = '1=1';
    List<Object> whereArgs = [];
    if (peerId != null) {
      where = '$where and (senderPeerId=? or receiverPeerId=?)';
      whereArgs.add(peerId);
      whereArgs.add(peerId);
    }
    //当通过群peerId查询群消息时，发送的群消息会拆分到个体的消息记录需要排除，否则重复显示
    if (groupPeerId != null) {
      where = '$where and groupPeerId=? and (direct!=? or receiverType!=?)';
      whereArgs.add(groupPeerId);
      whereArgs.add(ChatDirect.send.name);
      whereArgs.add(PartyType.linkman.name);
    }
    if (messageType != null) {
      where = '$where and messageType=?';
      whereArgs.add(messageType);
    } else {
      where = '$where and messageType!=?';
      whereArgs.add(ChatMessageType.system.name);
    }
    if (subMessageType != null) {
      where = '$where and subMessageType=?';
      whereArgs.add(subMessageType);
    }
    if (id != null) {
      where = '$where and id>?';
      whereArgs.add(id);
    }
    return find(
        where: where, whereArgs: whereArgs, orderBy: 'id desc', limit: limit);
  }

  ///接受到普通消息或者回执
  Future<void> receiveChatMessage(ChatMessage chatMessage) async {
    String? subMessageType = chatMessage.subMessageType;
    //收到回执，更新原消息
    if (subMessageType == ChatSubMessageType.chatReceipt.name) {
      String? messageId = chatMessage.messageId;
      if (messageId == null) {
        logger.e('chatReceipt message must have messageId');
      }
      ChatMessage? msg = await findByMessageId(messageId!);
      if (msg == null) {
        logger.e('chatReceipt message has no chatMessage with same messageId');
        return;
      }
      msg.receiptContent = chatMessage.content;
      msg.receiptTime = chatMessage.receiptTime;
      msg.receiveTime = chatMessage.receiveTime;
      msg.status = chatMessage.status;
      msg.readTime = chatMessage.readTime;
      msg.deleteTime = chatMessage.deleteTime;
      await update(msg);
      await chatSummaryService.upsertByChatMessage(msg);
    } else {
      //收到一般消息，保存
      chatMessage.direct = ChatDirect.receive.name;
      chatMessage.receiveTime = DateUtil.currentDate();
      chatMessage.status = MessageStatus.received.name;
      chatMessage.id = null;
      await insert(chatMessage);
      await chatSummaryService.upsertByChatMessage(chatMessage);
    }
  }

  ///接受到普通消息，创建回执，subMessageType为chatReceipt
  Future<ChatMessage?> buildChatReceipt(
      ChatMessage chatMessage, MessageStatus receiptType,
      {List<int>? receiptContent}) async {
    chatMessage.receiptTime = DateUtil.currentDate();
    if (receiptType == MessageStatus.read) {
      chatMessage.readTime = DateUtil.currentDate();
    } else if (receiptType == MessageStatus.accepted) {
      chatMessage.status = MessageStatus.accepted.name;
    } else if (receiptType == MessageStatus.rejected) {
      chatMessage.status = MessageStatus.rejected.name;
    } else if (receiptType == MessageStatus.deleted) {
      chatMessage.deleteTime = chatMessage.deleteTime;
      chatMessage.status = MessageStatus.deleted.name;
    }
    await update(chatMessage);

    ChatMessage msg = ChatMessage();
    msg.messageId = chatMessage.messageId;
    msg.messageType = chatMessage.messageType;
    msg.subMessageType = ChatSubMessageType.chatReceipt.name;
    msg.direct = ChatDirect.send.name;
    msg.senderPeerId = myself.peerId!;
    msg.senderClientId = myself.clientId;
    msg.senderType = PartyType.linkman.name;
    msg.senderName = myself.myselfPeer!.name;
    msg.sendTime = DateUtil.currentDate();
    msg.receiverPeerId = chatMessage.senderPeerId;
    msg.receiverClientId = chatMessage.senderClientId;
    msg.receiverType = chatMessage.senderType;
    msg.title = chatMessage.subMessageType;
    String? receiverPeerId = chatMessage.senderPeerId;
    if (receiverPeerId == null) {
      logger.e('receiverPeerId is null');
      return null;
    }
    String? senderName = chatMessage.senderName;
    if (senderName == null) {
      PeerClient? peerClient =
          await peerClientService.findCachedOneByPeerId(receiverPeerId);
      if (peerClient != null) {
        senderName = peerClient.name;
      }
    }
    msg.receiverName = senderName;
    msg.receiptTime = chatMessage.receiptTime;
    msg.receiveTime = chatMessage.receiveTime;
    msg.status = chatMessage.status;
    msg.readTime = chatMessage.readTime;
    msg.deleteTime = chatMessage.deleteTime;
    if (receiptContent != null) {
      msg.receiptContent = CryptoUtil.encodeBase64(receiptContent);
    }

    return msg;
  }

  //未填写的字段：transportType,senderAddress,receiverAddress,receiveTime,actualReceiveTime,readTime,destroyTime
  Future<ChatMessage> buildChatMessage(
    String receiverPeerId, {
    List<int>? data,
    String? clientId,
    String? messageId,
    TransportType transportType = TransportType.webrtc,
    ChatMessageType messageType = ChatMessageType.chat,
    ChatSubMessageType subMessageType = ChatSubMessageType.chat,
    ContentType contentType = ContentType.text,
    String? mimeType,
    PartyType receiverType = PartyType.linkman,
    String? name,
    String? groupPeerId,
    String? groupName,
    String? title,
    List<int>? receiptContent,
    List<int>? thumbnail,
    String? status,
  }) async {
    ChatMessage chatMessage = ChatMessage();
    if (messageId == null) {
      var uuid = const Uuid();
      messageId = uuid.v4();
    }
    chatMessage.messageId = messageId;
    chatMessage.messageType = messageType.name;
    chatMessage.subMessageType = subMessageType.name;
    chatMessage.direct = ChatDirect.send.name; //对自己而言，消息是属于发送或者接受
    chatMessage.senderPeerId = myself.peerId!;
    chatMessage.senderClientId = myself.clientId;
    chatMessage.senderType = PartyType.linkman.name;
    chatMessage.senderName = myself.myselfPeer!.name;
    chatMessage.sendTime = DateUtil.currentDate();
    chatMessage.receiverPeerId = receiverPeerId;
    if (clientId == null) {
      PeerClient? peerClient =
          await peerClientService.findCachedOneByPeerId(receiverPeerId);
      if (peerClient != null) {
        clientId = peerClient.clientId;
        name = peerClient.name;
      }
    }
    chatMessage.receiverType = receiverType.name;
    chatMessage.receiverClientId = clientId;
    chatMessage.receiverName = name;
    chatMessage.groupPeerId = groupPeerId;
    chatMessage.groupName = groupName;
    chatMessage.title = title;
    if (receiptContent != null) {
      chatMessage.receiptContent = CryptoUtil.encodeBase64(receiptContent);
    }
    if (thumbnail != null) {
      chatMessage.thumbnail = CryptoUtil.encodeBase64(thumbnail);
    }
    if (data != null) {
      chatMessage.content = CryptoUtil.encodeBase64(data);
      chatMessage.contentType = contentType.name;
      chatMessage.mimeType = mimeType;
    }
    chatMessage.status = status ?? MessageStatus.sent.name;
    chatMessage.transportType = transportType.name;

    await insert(chatMessage);
    await chatSummaryService.upsertByChatMessage(chatMessage);

    return chatMessage;
  }

  //未填写的字段：transportType,senderAddress,receiverAddress,receiveTime,actualReceiveTime,readTime,destroyTime
  Future<List<ChatMessage>> buildGroupChatMessage(
    String groupPeerId, {
    List<int>? data,
    ChatMessageType messageType = ChatMessageType.chat,
    ChatSubMessageType subMessageType = ChatSubMessageType.chat,
    ContentType contentType = ContentType.text,
    String? mimeType,
    String? title,
    List<int>? receiptContent,
    List<int>? thumbnail,
  }) async {
    List<ChatMessage> chatMessages = [];
    Group? group = await groupService.findCachedOneByPeerId(groupPeerId);
    if (group != null) {
      var groupName = group.name;
      var groupChatMessage = await buildChatMessage(
        groupPeerId,
        data: data,
        messageType: messageType,
        subMessageType: subMessageType,
        contentType: contentType,
        mimeType: mimeType,
        receiverType: PartyType.group,
        name: groupName,
        groupPeerId: groupPeerId,
        groupName: groupName,
        title: title,
        receiptContent: receiptContent,
        thumbnail: thumbnail,
      );
      chatMessages.add(groupChatMessage);
      var messageId = groupChatMessage.messageId;
      List<GroupMember> groupMembers =
          await groupMemberService.findByGroupId(groupPeerId);
      List<Linkman> linkmen =
          await groupMemberService.findLinkmen(groupMembers);
      for (var linkman in linkmen) {
        var peerId = linkman.peerId;
        var name = linkman.name;
        ChatMessage chatMessage = await buildChatMessage(
          peerId,
          messageId: messageId,
          messageType: messageType,
          subMessageType: subMessageType,
          contentType: contentType,
          mimeType: mimeType,
          name: name,
          groupPeerId: groupPeerId,
          groupName: groupName,
        );
        chatMessage.title = groupChatMessage.title;
        chatMessage.content = groupChatMessage.content;
        chatMessage.receiptContent = groupChatMessage.receiptContent;
        chatMessage.thumbnail = groupChatMessage.thumbnail;
        chatMessages.add(chatMessage);
      }
    }
    return chatMessages;
  }

  send(ChatMessage chatMessage,
      {CryptoOption cryptoOption = CryptoOption.cryptography}) async {
    var peerId = chatMessage.receiverPeerId;
    var clientId = chatMessage.receiverClientId;
    if (peerId != null) {
      String json = JsonUtil.toJsonString(chatMessage);
      var data = CryptoUtil.stringToUtf8(json);
      await peerConnectionPool.send(peerId, Uint8List.fromList(data),
          clientId: clientId, cryptoOption: cryptoOption);
    }
  }
}

final chatMessageService = ChatMessageService(
    tableName: "chat_message",
    indexFields: [
      'ownerPeerId',
      'transportType',
      'messageId',
      'messageType',
      'subMessageType',
      'direct',
      'receiverPeerId',
      'receiverType',
      'receiverAddress',
      'senderPeerId',
      'senderType',
      'senderAddress',
      'createDate',
      'sendTime',
      'receiveTime',
      'receiptTime',
      'title',
    ],
    fields: ServiceLocator.buildFields(ChatMessage(), []));

class MergedMessageService extends GeneralBaseService<MergedMessage> {
  MergedMessageService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return MergedMessage.fromJson(map);
    };
  }
}

final mergedMessageService = MergedMessageService(
    tableName: "chat_mergedmessage",
    indexFields: ['ownerPeerId', 'mergedMessageId', 'messageId', 'createDate'],
    fields: ServiceLocator.buildFields(MergedMessage(), []));

class MessageAttachmentService extends GeneralBaseService<MessageAttachment> {
  MessageAttachmentService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return MessageAttachment.fromJson(map);
    };
  }
}

final messageAttachmentService = MessageAttachmentService(
    tableName: "chat_messageattachment",
    indexFields: ['ownerPeerId', 'messageId', 'createDate', 'targetPeerId'],
    fields: ServiceLocator.buildFields(MessageAttachment(), []));

class ReceiveService extends GeneralBaseService<Receive> {
  ReceiveService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return Receive.fromJson(map);
    };
  }
}

final receiveService = ReceiveService(
    tableName: "chat_receive",
    indexFields: [
      'ownerPeerId',
      'targetPeerId',
      'createDate',
      'targetType',
      'receiverPeerId',
      'messageType',
    ],
    fields: ServiceLocator.buildFields(Receive(), []));

class ChatSummaryService extends GeneralBaseService<ChatSummary> {
  Map<String, ChatSummary> chatSummaries = {};

  ChatSummaryService({
    required super.tableName,
    required super.fields,
    required super.indexFields,
    super.encryptFields = const ['content', 'thumbBody', 'thumbnail', 'title'],
  }) {
    post = (Map map) {
      return ChatSummary.fromJson(map);
    };
  }

  Future<List<ChatSummary>> findByPartyType(
    String partyType,
  ) async {
    String where = 'partyType=?';
    List<Object> whereArgs = [partyType];
    var chatSummary = await find(
      where: where,
      whereArgs: whereArgs,
      orderBy: 'sendReceiveTime',
    );

    return chatSummary;
  }

  Future<ChatSummary?> findByPeerId(
    String peerId,
  ) async {
    String where = 'peerId=?';
    List<Object> whereArgs = [peerId];
    var chatSummary = await findOne(
      where: where,
      whereArgs: whereArgs,
    );
    return chatSummary;
  }

  Future<ChatSummary?> findOneByPeerId(String peerId) async {
    var where = 'peerId = ?';
    var whereArgs = [peerId];
    var peer = await findOne(where: where, whereArgs: whereArgs);

    return peer;
  }

  Future<ChatSummary?> findCachedOneByPeerId(String peerId) async {
    if (chatSummaries.containsKey(peerId)) {
      return chatSummaries[peerId];
    }
    ChatSummary? chatSummary = await findOneByPeerId(peerId);
    if (chatSummary != null) {
      chatSummaries[peerId] = chatSummary;
    }
    return chatSummary;
  }

  upsertByLinkman(Linkman linkman) async {
    ChatSummary? chatSummary = await findCachedOneByPeerId(linkman.peerId);
    if (chatSummary == null) {
      chatSummary = ChatSummary();
      chatSummary.peerId = linkman.peerId;
      chatSummary.partyType = PartyType.linkman.name;
      chatSummary.status = linkman.status;
      chatSummary.name = linkman.name;
      chatSummary.avatar = linkman.avatar;
      await insert(chatSummary);
      chatSummaries[chatSummary.peerId!] = chatSummary;
    } else {
      chatSummary.name = linkman.name;
      chatSummary.avatar = linkman.avatar;
      await update(chatSummary);
    }
  }

  upsertByGroup(Group group) async {
    ChatSummary? chatSummary = await findCachedOneByPeerId(group.peerId);
    if (chatSummary == null) {
      chatSummary = ChatSummary();
      chatSummary.peerId = group.peerId;
      chatSummary.partyType = PartyType.group.name;
      chatSummary.subPartyType = group.groupType;
      chatSummary.name = group.name;
      chatSummary.avatar = group.avatar;
      await insert(chatSummary);
      chatSummaries[chatSummary.peerId!] = chatSummary;
    } else {
      chatSummary.name = group.name;
      chatSummary.avatar = group.avatar;
      await update(chatSummary);
    }
  }

  ///新的ChatMessage来了，更新ChatSummary
  upsertByChatMessage(ChatMessage chatMessage) async {
    if (chatMessage.messageType == ChatMessageType.system.name) {
      return;
    }
    var groupPeerId = chatMessage.groupPeerId;
    var senderPeerId = chatMessage.senderPeerId;
    var receiverPeerId = chatMessage.receiverPeerId;
    var senderClientId = chatMessage.senderClientId;
    var receiverClientId = chatMessage.receiverClientId;
    ChatSummary? chatSummary;
    if (groupPeerId != null) {
      chatSummary = await findCachedOneByPeerId(groupPeerId);
      if (chatSummary == null) {
        chatSummary = ChatSummary();
        chatSummary.peerId = groupPeerId;
        chatSummary.partyType = PartyType.group.name;
        chatSummary.sendReceiveTime = chatMessage.sendTime;
        Group? group = await groupService.findCachedOneByPeerId(groupPeerId);
        if (group != null) {
          chatSummary.name = group.name;
          chatSummary.avatar = group.avatar;
        }
      }
    } else {
      if (senderPeerId != null && senderPeerId != myself.peerId) {
        chatSummary = await findCachedOneByPeerId(senderPeerId);
        if (chatSummary == null) {
          chatSummary = ChatSummary();
          chatSummary.peerId = senderPeerId;
          chatSummary.clientId = senderClientId;
          chatSummary.partyType = PartyType.linkman.name;
          chatSummary.sendReceiveTime = chatMessage.sendTime;
          Linkman? linkman =
              await linkmanService.findCachedOneByPeerId(senderPeerId);
          if (linkman != null) {
            chatSummary.name = linkman.name;
            chatSummary.avatar = linkman.avatar;
          }
        }
      } else if (receiverPeerId != null && receiverPeerId != myself.peerId) {
        chatSummary = await findCachedOneByPeerId(receiverPeerId);
        if (chatSummary == null) {
          chatSummary = ChatSummary();
          chatSummary.peerId = receiverPeerId;
          chatSummary.clientId = receiverClientId;
          chatSummary.partyType = PartyType.linkman.name;
          chatSummary.sendReceiveTime = chatMessage.sendTime;
          Linkman? linkman =
              await linkmanService.findCachedOneByPeerId(receiverPeerId);
          if (linkman != null) {
            chatSummary.name = linkman.name;
            chatSummary.avatar = linkman.avatar;
          }
        }
      }
    }
    if (chatSummary != null) {
      chatSummary.messageId = chatMessage.messageId;
      chatSummary.messageType = chatMessage.messageType;
      chatSummary.subMessageType = chatMessage.subMessageType;
      chatSummary.title = chatMessage.title;
      chatSummary.receiptContent = chatMessage.receiptContent;
      chatSummary.thumbnail = chatMessage.thumbnail;
      chatSummary.content = chatMessage.content;
      chatSummary.contentType = chatMessage.contentType;
      chatSummary.unreadNumber = chatSummary.unreadNumber + 1;
      if (chatSummary.id == null) {
        insert(chatSummary);
        chatSummaries[chatSummary.peerId!] = chatSummary;
      } else {
        update(chatSummary);
      }
    }
  }
}

final chatSummaryService = ChatSummaryService(
    tableName: "chat_summary",
    indexFields: ['ownerPeerId', 'peerId', 'partyType', 'sendReceiveTime'],
    fields: ServiceLocator.buildFields(ChatSummary(), []));
