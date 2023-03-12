import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';

class ChatSummaryService extends GeneralBaseService<ChatSummary> {
  Map<String, ChatSummary> chatSummaries = {};

  ChatSummaryService({
    required super.tableName,
    required super.fields,
    required super.indexFields,
    super.encryptFields = const [
      'content',
      'thumbBody',
      'thumbnail',
      'title',
      'receiptContent'
    ],
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
      orderBy: 'sendReceiveTime desc',
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

  Future<ChatSummary> upsertByLinkman(Linkman linkman) async {
    ChatSummary? chatSummary = await findCachedOneByPeerId(linkman.peerId);
    if (chatSummary == null) {
      chatSummary = ChatSummary();
      chatSummary.peerId = linkman.peerId;
      chatSummary.partyType = PartyType.linkman.name;
      chatSummary.status = linkman.status;
      chatSummary.name = linkman.name;
      if (myself.id == null) {
        chatSummary.ownerPeerId = linkman.ownerPeerId;
      }
      await insert(chatSummary);
      chatSummaries[chatSummary.peerId!] = chatSummary;
    } else {
      chatSummary.name = linkman.name;
      await upsert(chatSummary);
    }

    return chatSummary;
  }

  Future<ChatSummary> upsertByGroup(Group group) async {
    ChatSummary? chatSummary = await findCachedOneByPeerId(group.peerId);
    if (chatSummary == null) {
      chatSummary = ChatSummary();
      chatSummary.peerId = group.peerId;
      chatSummary.partyType = PartyType.group.name;
      chatSummary.subPartyType = group.groupType;
      chatSummary.status = group.status;
      chatSummary.name = group.name;
      await insert(chatSummary);
      chatSummaries[chatSummary.peerId!] = chatSummary;
    } else {
      chatSummary.name = group.name;
      await upsert(chatSummary);
    }
    return chatSummary;
  }

  Future<ChatSummary> upsertByConference(Conference conference) async {
    ChatSummary? chatSummary =
        await findCachedOneByPeerId(conference.conferenceId);
    if (chatSummary == null) {
      chatSummary = ChatSummary();
      chatSummary.peerId = conference.conferenceId;
      chatSummary.partyType = PartyType.conference.name;
      chatSummary.subPartyType = conference.topic;
      chatSummary.status = conference.status;
      chatSummary.name = conference.name;
      await insert(chatSummary);
      chatSummaries[chatSummary.peerId!] = chatSummary;
    } else {
      chatSummary.name = conference.name;
      chatSummary.subPartyType = conference.topic;
      await upsert(chatSummary);
    }
    return chatSummary;
  }

  ///新的ChatMessage来了，更新ChatSummary
  Future<ChatSummary?> upsertByChatMessage(ChatMessage chatMessage) async {
    if (chatMessage.messageType == ChatMessageType.system.name ||
        chatMessage.messageType == ChatMessageType.channel.name ||
        chatMessage.messageType == ChatMessageType.collection.name) {
      return null;
    }
    if (chatMessage.subMessageType == ChatMessageSubType.chatReceipt.name ||
        chatMessage.subMessageType == ChatMessageSubType.signal.name ||
        chatMessage.subMessageType == ChatMessageSubType.preKeyBundle.name) {
      return null;
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
        chatSummary.partyType = chatMessage.groupType;
        chatSummary.name = chatMessage.groupName;
        chatSummary.sendReceiveTime = chatMessage.sendTime;
      }
    } else {
      if (senderPeerId != null && senderPeerId != myself.peerId) {
        chatSummary = await findCachedOneByPeerId(senderPeerId);
        if (chatSummary == null) {
          chatSummary = ChatSummary();
          chatSummary.peerId = senderPeerId;
          chatSummary.partyType = PartyType.linkman.name;
          chatSummary.sendReceiveTime = chatMessage.sendTime;
          Linkman? linkman =
              await linkmanService.findCachedOneByPeerId(senderPeerId);
          if (linkman != null) {
            chatSummary.name = linkman.name;
          }
        }
      } else if (receiverPeerId != null && receiverPeerId != myself.peerId) {
        chatSummary = await findCachedOneByPeerId(receiverPeerId);
        if (chatSummary == null) {
          chatSummary = ChatSummary();
          chatSummary.peerId = receiverPeerId;
          chatSummary.partyType = PartyType.linkman.name;
          chatSummary.sendReceiveTime = chatMessage.sendTime;
          Linkman? linkman =
              await linkmanService.findCachedOneByPeerId(receiverPeerId);
          if (linkman != null) {
            chatSummary.name = linkman.name;
          }
        }
      }
    }
    if (chatSummary != null) {
      chatSummary.messageId = chatMessage.messageId;
      chatSummary.messageType = chatMessage.messageType;
      chatSummary.subMessageType = chatMessage.subMessageType;
      chatSummary.title = chatMessage.title;
      chatSummary.receiptContent = chatMessage.receiptType;
      chatSummary.thumbnail = chatMessage.thumbnail;
      chatSummary.content = chatMessage.content;
      chatSummary.contentType = chatMessage.contentType;
      chatSummary.sendReceiveTime = chatMessage.sendTime;
      chatSummary.unreadNumber = chatSummary.unreadNumber + 1;
      chatSummary.status = chatMessage.status;
      await upsert(chatSummary);
      chatSummaries[chatSummary.peerId!] = chatSummary;
    }
    return chatSummary;
  }

  removeChatSummary(String peerId) async {
    await delete(where: 'peerId=?', whereArgs: [peerId]);
  }
}

final chatSummaryService = ChatSummaryService(
    tableName: "chat_summary",
    indexFields: ['ownerPeerId', 'peerId', 'partyType', 'sendReceiveTime'],
    fields: ServiceLocator.buildFields(ChatSummary(), []));
