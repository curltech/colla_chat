import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/util.dart';
import 'package:uuid/uuid.dart';

import '../../constant/base.dart';
import '../../datastore/datastore.dart';
import '../../entity/base.dart';
import '../../entity/chat/chat.dart';
import '../../entity/chat/contact.dart';
import '../../entity/dht/myself.dart';
import '../../entity/p2p/security_context.dart';
import '../p2p/security_context.dart';

class ChatMessageService extends GeneralBaseService<ChatMessage> {
  ChatMessageService({
    required super.tableName,
    required super.fields,
    required super.indexFields,
    super.encryptFields = const ['content'],
  }) {
    post = (Map map) {
      return ChatMessage.fromJson(map);
    };
  }

  Future<List<ChatMessage>> load(String where,
      {List<Object>? whereArgs,
      String? orderBy,
      int? offset,
      int? limit}) async {
    List<dynamic> data = await find(
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      offset: offset,
      limit: limit,
    );
    List<ChatMessage> chatMessages = [];
    for (var d in data) {
      var chatMessage = d as ChatMessage;
      SecurityContext securityContext = SecurityContext();
      securityContext.needCompress = chatMessage.needCompress;
      securityContext.needEncrypt = chatMessage.needEncrypt;
      securityContext.payloadKey = chatMessage.payloadKey;
      var content = chatMessage.content;
      var thumbnail = chatMessage.thumbnail;
      if (content != null) {
        List<int>? data =
            await SecurityContextService.decrypt(content, securityContext);
        if (data != null) {
          chatMessage.content = CryptoUtil.uint8ListToStr(data);
        }
      }
      if (thumbnail != null) {
        var data =
            await SecurityContextService.decrypt(thumbnail, securityContext);
        if (data != null) {
          thumbnail = CryptoUtil.uint8ListToStr(data);
        }
        chatMessage.thumbnail = thumbnail;
      }
      chatMessages.add(chatMessage);
    }
    return chatMessages;
  }

  /// 批量保存聊天消息
  store(List<ChatMessage> chatMessages, dynamic parent) async {
    if (chatMessages.isEmpty) {
      return;
    }
    var peerProfile = myself.peerProfile;
    if (peerProfile != null && peerProfile.localDataCryptoSwitch) {
      SecurityContext securityContext = SecurityContext();
      securityContext.needCompress = true;
      securityContext.needEncrypt = true;
      for (var chatMessage in chatMessages) {
        var state = chatMessage.state;
        if (EntityState.delete.name == state) {
          continue;
        }
        securityContext.payloadKey = chatMessage.payloadKey;
        var content = chatMessage.content;
        if (content != null) {
          var result = await SecurityContextService.encrypt(
              content.codeUnits, securityContext);
          chatMessage.payloadKey = result.payloadKey;
          chatMessage.needCompress = result.needCompress;
          chatMessage.content = result.transportPayload;
          chatMessage.payloadHash = result.payloadHash;
        }
        var thumbnail = chatMessage.thumbnail;
        if (thumbnail != null) {
          var result = await SecurityContextService.encrypt(
              thumbnail.codeUnits, securityContext);
          chatMessage.thumbnail = result.transportPayload;
        }
      }
    }
    await save(chatMessages, [], parent);
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
    String where = '(senderPeerId=? or receiverPeerId=?)'; //
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
    }
    if (id != null) {
      where = '$where and id>?';
      whereArgs.add(id);
    }
    return find(
        where: where, whereArgs: whereArgs, orderBy: 'id desc', limit: limit);
  }

  Future<void> receiveChatMessage(ChatMessage chatMessage,
      {TransportType transportType = TransportType.webrtc,
      bool read = true,
      bool destroyed = false}) async {
    chatMessage.direct = ChatDirect.receive.name;
    chatMessage.receiveTime = DateUtil.currentDate();
    chatMessage.actualReceiveTime = DateUtil.currentDate();
    if (read) {
      chatMessage.readTime = DateUtil.currentDate();
    }
    chatMessage.id = null;
    await insert(chatMessage);
    await chatSummaryService.upsertByChatMessage(chatMessage);
  }

  //未填写的字段：transportType,senderAddress,receiverAddress,receiveTime,actualReceiveTime,readTime,destroyTime
  Future<ChatMessage> buildChatMessage(
    String peerId,
    List<int> data, {
    String? clientId,
    ContentType contentType = ContentType.text,
    String? name,
    String? groupPeerId,
    String? groupName,
    String? title,
    List<int>? thumbBody,
    List<int>? thumbnail,
  }) async {
    ChatMessage chatMessage = ChatMessage(myself.peerId!);
    var uuid = const Uuid();
    chatMessage.messageId = uuid.v4();
    chatMessage.messageType = MessageType.chat.name;
    chatMessage.subMessageType = ChatSubMessageType.chat.name;
    chatMessage.direct = ChatDirect.send.name; //对自己而言，消息是属于发送或者接受
    chatMessage.senderPeerId = myself.peerId!;
    chatMessage.senderClientId = myself.clientId;
    chatMessage.senderType = PartyType.linkman.name;
    chatMessage.senderName = myself.myselfPeer!.name;
    chatMessage.sendTime = DateUtil.currentDate();
    chatMessage.receiverPeerId = peerId;
    chatMessage.receiverClientId = clientId;
    chatMessage.receiverType = PartyType.linkman.name;
    chatMessage.receiverName = name;
    chatMessage.groupPeerId = groupPeerId;
    chatMessage.groupName = groupName;
    chatMessage.title = title;
    if (thumbBody != null) {
      chatMessage.thumbBody = CryptoUtil.encodeBase64(thumbBody);
    }
    if (thumbnail != null) {
      chatMessage.thumbnail = CryptoUtil.encodeBase64(thumbnail);
    }
    chatMessage.content = CryptoUtil.encodeBase64(data);
    chatMessage.contentType = contentType.name;

    await insert(chatMessage);
    await chatSummaryService.upsertByChatMessage(chatMessage);

    return chatMessage;
  }

  //未填写的字段：transportType,senderAddress,receiverAddress,receiveTime,actualReceiveTime,readTime,destroyTime
  Future<List<ChatMessage>> buildGroupChatMessage(
    String groupPeerId,
    List<int> data, {
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
          data,
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

  store(dynamic entity) async {
    List<MessageAttachment> attaches = entity.attaches;
    var peerProfile = myself.peerProfile;
    if (peerProfile != null && peerProfile.localDataCryptoSwitch) {
      SecurityContext securityContext = SecurityContext();
      securityContext.needCompress = true;
      securityContext.needEncrypt = true;
      for (var attach in attaches) {
        if (EntityState.delete.name == entity.state) {
          attach.state = EntityState.delete;
          continue;
        }
        var content = attach.content;
        if (content != null) {
          var result = await SecurityContextService.encrypt(
              content.codeUnits, securityContext);
          attach.payloadKey = result.payloadKey;
          attach.needCompress = result.needCompress;
          attach.needCompress = result.needEncrypt;
          attach.content = result.transportPayload;
          attach.payloadHash = result.payloadHash;
        }
      }
      await save(attaches, [], entity.attachs);
    } else {
      await save(attaches, [], entity.attachs);
    }
  }

  load(String attachBlockId, int? offset) async {
    var where = 'attachBlockId=? and ownerPeerId=?';
    var peerId = myself.peerId;
    if (peerId == null) {
      return;
    }
    List<Object> whereArgs = [attachBlockId, peerId];
    List<MessageAttachment> attaches = [];
    var data = await find(
      where: where,
      whereArgs: whereArgs,
    );
    SecurityContext securityContext = SecurityContext();
    securityContext.needCompress = true;
    securityContext.needEncrypt = true;
    for (var d in data) {
      var chatAttach = d as MessageAttachment;
      var payloadKey = chatAttach.payloadKey;
      if (payloadKey != null) {
        securityContext.payloadKey = payloadKey;
        var content = chatAttach.content;
        if (content != null) {
          List<int>? data =
              await SecurityContextService.decrypt(content, securityContext);
          //d.content = StringUtil.decodeURI(payload)
          if (data != null) {
            chatAttach.content = CryptoUtil.uint8ListToStr(data);
          }
        }
      }
      attaches.add(chatAttach);
    }
    return attaches;
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

  ChatSummaryService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
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
    var groupPeerId = chatMessage.groupPeerId;
    var senderPeerId = chatMessage.senderPeerId;
    var receiverPeerId = chatMessage.receiverPeerId;
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
