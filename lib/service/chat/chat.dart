import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/util.dart';
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

  Future<List<ChatMessage>> findByPeerId(String peerId,
      {String? direct,
      String? messageType,
      String? subMessageType,
      int? offset,
      int? limit}) async {
    String where = '(senderPeerId=? or receiverPeerId=?)';
    List<Object> whereArgs = [peerId, peerId];
    if (direct != null) {
      where = '$where and direct=?';
      whereArgs.add(direct);
    }
    if (messageType != null) {
      where = '$where and messageType=?';
      whereArgs.add(messageType);
    }
    if (subMessageType != null) {
      where = '$where and subMessageType=?';
      whereArgs.add(subMessageType);
    } else {
      where = '$where and subMessageType!=?';
      whereArgs.add(ChatSubMessageType.preKeyBundle.name);
    }
    return find(
        where: where,
        whereArgs: whereArgs,
        orderBy: 'id desc',
        offset: offset,
        limit: limit);
  }

  Future<List<ChatMessage>> findByGreaterId(String peerId,
      {String? direct,
      String? messageType,
      String? subMessageType,
      int? id,
      int? limit}) async {
    String where = '(senderPeerId=? or receiverPeerId=?)';
    List<Object> whereArgs = [peerId, peerId];
    if (direct != null) {
      where = '$where and direct=?';
      whereArgs.add(direct);
    }
    if (messageType != null) {
      where = '$where and messageType=?';
      whereArgs.add(messageType);
    }
    if (subMessageType != null) {
      where = '$where and subMessageType=?';
      whereArgs.add(subMessageType);
    } else {
      where = '$where and subMessageType!=?';
      whereArgs.add(ChatSubMessageType.preKeyBundle.name);
    }
    if (id != null) {
      where = '$where and id>?';
      whereArgs.add(id);
    }
    return find(
        where: where, whereArgs: whereArgs, orderBy: 'id desc', limit: limit);
  }

  Future<void> receiveChatMessage(ChatMessage chatMessage) async {
    String? subMessageType = chatMessage.subMessageType;
    //回执
    if (subMessageType == ChatSubMessageType.chatReceipt.name) {
      String? messageId = chatMessage.messageId;
      if (messageId == null) {
        logger.e('chatReceipt message must have messageId');
      }
      ChatMessage? msg = await findByMessageId(messageId!);
      if (msg == null) {
        logger.e('chatReceipt message has no chatMessage with same messageId');
      }
      String? title = msg!.title;
      if (title == ChatReceiptType.received.name) {
        msg.actualReceiveTime = chatMessage.actualReceiveTime;
        msg.receiveTime = DateUtil.currentDate();
        msg.status = MessageStatus.received.name;
      } else if (title == ChatReceiptType.read.name) {
        msg.readTime = DateUtil.currentDate();
        msg.status = MessageStatus.read.name;
      } else if (title == ChatReceiptType.agree.name) {
        msg.status = MessageStatus.agree.name;
      } else if (title == ChatReceiptType.reject.name) {
        msg.status = MessageStatus.reject.name;
      } else if (title == ChatReceiptType.deleted.name) {
        msg.deleteTime = chatMessage.deleteTime;
        msg.status = MessageStatus.deleted.name;
      }
      await update(msg);
      await chatSummaryService.upsertByChatMessage(msg);
    } else {
      //一般消息
      chatMessage.direct = ChatDirect.receive.name;
      chatMessage.receiveTime = DateUtil.currentDate();
      chatMessage.actualReceiveTime = DateUtil.currentDate();
      chatMessage.status = MessageStatus.received.name;
      chatMessage.id = null;
      await insert(chatMessage);
      await chatSummaryService.upsertByChatMessage(chatMessage);
    }
  }

  //创建回执，subMessageType为chatReceipt，title为
  Future<ChatMessage?> buildChatReceipt(
      ChatMessage chatMessage, ChatReceiptType receiptType) async {
    ChatMessage msg = ChatMessage(myself.peerId!);
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
    msg.receiverType = chatMessage.subMessageType;
    String? receiverPeerId = chatMessage.senderPeerId;
    if (receiverPeerId == null) {
      logger.e('receiverPeerId is null');
      return null;
    }
    String? senderName = chatMessage.senderName;
    if (senderName == null) {
      PeerClient? peerClient =
          await peerClientService.findCachedOneByPeerId(receiverPeerId!);
      if (peerClient != null) {
        senderName = peerClient.name;
      }
    }
    msg.receiverName = senderName;
    if (receiptType == ChatReceiptType.received) {
      msg.actualReceiveTime = DateUtil.currentDate();
      msg.receiveTime = DateUtil.currentDate();
      msg.title = ChatReceiptType.received.name;
    } else if (receiptType == ChatReceiptType.read) {
      msg.readTime = DateUtil.currentDate();
      msg.title = ChatReceiptType.read.name;
    } else if (receiptType == ChatReceiptType.agree) {
      msg.title = ChatReceiptType.agree.name;
    } else if (receiptType == ChatReceiptType.reject) {
      msg.title = ChatReceiptType.reject.name;
    } else if (receiptType == ChatReceiptType.deleted) {
      msg.deleteTime = chatMessage.deleteTime;
      msg.title = ChatReceiptType.deleted.name;
    }
    await insert(msg);

    return msg;
  }

  //未填写的字段：transportType,senderAddress,receiverAddress,receiveTime,actualReceiveTime,readTime,destroyTime
  Future<ChatMessage> buildChatMessage(
    String peerId, {
    List<int>? data,
    String? clientId,
    MessageType messageType = MessageType.chat,
    ChatSubMessageType subMessageType = ChatSubMessageType.chat,
    ContentType contentType = ContentType.text,
    String? name,
    String? groupPeerId,
    String? groupName,
    String? title,
    List<int>? thumbBody,
    List<int>? thumbnail,
    String? status,
  }) async {
    ChatMessage chatMessage = ChatMessage(myself.peerId!);
    var uuid = const Uuid();
    chatMessage.messageId = uuid.v4();
    chatMessage.messageType = messageType.name;
    chatMessage.subMessageType = subMessageType.name;
    chatMessage.direct = ChatDirect.send.name; //对自己而言，消息是属于发送或者接受
    chatMessage.senderPeerId = myself.peerId!;
    chatMessage.senderClientId = myself.clientId;
    chatMessage.senderType = PartyType.linkman.name;
    chatMessage.senderName = myself.myselfPeer!.name;
    chatMessage.sendTime = DateUtil.currentDate();
    chatMessage.receiverPeerId = peerId;
    chatMessage.receiverClientId = clientId;
    chatMessage.receiverType = PartyType.linkman.name;
    if (name == null) {
      PeerClient? peerClient =
          await peerClientService.findCachedOneByPeerId(peerId);
      if (peerClient != null) {
        name = peerClient.name;
      }
    }
    chatMessage.receiverName = name;
    chatMessage.groupPeerId = groupPeerId;
    chatMessage.groupName = groupName;
    if (thumbBody != null) {
      chatMessage.thumbBody = CryptoUtil.encodeBase64(thumbBody);
    }
    if (thumbnail != null) {
      chatMessage.thumbnail = CryptoUtil.encodeBase64(thumbnail);
    }
    if (data != null) {
      chatMessage.content = CryptoUtil.encodeBase64(data);
      chatMessage.contentType = contentType.name;
    }
    status = MessageStatus.sent.name;

    await insert(chatMessage);
    await chatSummaryService.upsertByChatMessage(chatMessage);

    return chatMessage;
  }

  //未填写的字段：transportType,senderAddress,receiverAddress,receiveTime,actualReceiveTime,readTime,destroyTime
  Future<List<ChatMessage>> buildGroupChatMessage(
    String groupPeerId, {
    List<int>? data,
    MessageType messageType = MessageType.chat,
    ChatSubMessageType subMessageType = ChatSubMessageType.chat,
    ContentType contentType = ContentType.text,
    String? title,
    List<int>? thumbBody,
    List<int>? thumbnail,
  }) async {
    List<ChatMessage> chatMessages = [];
    Group? group = await groupService.findCachedOneByPeerId(groupPeerId);
    if (group != null) {
      var groupName = group.name;
      List<GroupMember> groupMembers =
          await groupMemberService.findByGroupId(groupPeerId);
      List<Linkman> linkmen =
          await groupMemberService.findLinkmen(groupMembers);
      for (var linkman in linkmen) {
        var peerId = linkman.peerId;
        var name = linkman.name;
        ChatMessage chatMessage = await buildChatMessage(
          peerId,
          data: data,
          messageType: messageType,
          subMessageType: subMessageType,
          contentType: contentType,
          name: name,
          groupPeerId: groupPeerId,
          groupName: groupName,
          title: title,
          thumbBody: thumbBody,
          thumbnail: thumbnail,
        );
        chatMessages.add(chatMessage);
      }
    }
    return chatMessages;
  }

  send(ChatMessage chatMessage,
      {CryptoOption cryptoOption = CryptoOption.signal}) async {
    var peerId = chatMessage.receiverPeerId;
    var clientId = chatMessage.receiverClientId;
    if (peerId != null) {
      String json = JsonUtil.toJsonString(chatMessage);
      var data = CryptoUtil.stringToUtf8(json);
      await peerConnectionPool.send(peerId, data,
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
      'actualReceiveTime',
      'title',
    ],
    fields: ServiceLocator.buildFields(ChatMessage(''), []));

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
      chatSummary = ChatSummary(myself.peerId!);
      chatSummary.peerId = linkman.peerId;
      chatSummary.partyType = PartyType.linkman.name;
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
      chatSummary = ChatSummary(myself.peerId!);
      chatSummary.peerId = group.peerId;
      chatSummary.partyType = PartyType.linkman.name;
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
    if (chatMessage.subMessageType == ChatSubMessageType.preKeyBundle.name) {
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
        chatSummary = ChatSummary(myself.peerId!);
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
          chatSummary = ChatSummary(myself.peerId!);
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
          chatSummary = ChatSummary(myself.peerId!);
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
      chatSummary.thumbBody = chatMessage.thumbBody;
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
    fields: ServiceLocator.buildFields(ChatSummary(''), []));
