import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';

import '../../constant/base.dart';
import '../../datastore/datastore.dart';
import '../../entity/chat/chat.dart';
import '../../entity/dht/myself.dart';
import '../../entity/p2p/security_context.dart';
import '../p2p/security_context.dart';

class ChatMessageService extends GeneralBaseService<ChatMessage> {
  ChatMessageService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
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
        if (EntityState.Deleted.name == state) {
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
        if (EntityState.Deleted.name == entity.state) {
          attach.state = EntityState.Deleted.name;
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
}

final chatSummaryService = ChatSummaryService(
    tableName: "chat_summary",
    indexFields: ['ownerPeerId', 'peerId', 'partyType', 'sendReceiveTime'],
    fields: ServiceLocator.buildFields(ChatSummary(''), []));
