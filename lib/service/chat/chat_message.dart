import 'dart:async';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/p2p/chain/action/chat.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/nearby_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/websocket.dart';
import 'package:uuid/uuid.dart';

class ChatMessageService extends GeneralBaseService<ChatMessage> {
  Timer? timer;

  ChatMessageService({
    required super.tableName,
    required super.fields,
    required super.indexFields,
    super.encryptFields = const ['content', 'thumbBody', 'thumbnail', 'title'],
  }) {
    post = (Map map) {
      return ChatMessage.fromJson(map);
    };
    // timer = Timer.periodic(const Duration(seconds: 60), (timer) async {
    //   deleteTimeout();
    // });
  }

  Future<ChatMessage?> findByMessageId(String messageId,
      {String? receiverPeerId, String? senderPeerId}) async {
    String where = 'messageId=?';
    List<Object> whereArgs = [messageId];
    if (receiverPeerId != null) {
      where = '$where and receiverPeerId=?';
      whereArgs.add(receiverPeerId);
    }
    if (senderPeerId != null) {
      where = '$where and senderPeerId=?';
      whereArgs.add(senderPeerId);
    }
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
      String? status,
      int? offset,
      int? limit}) async {
    var myselfPeerId = myself.peerId!;
    String where = '1=1';
    List<Object> whereArgs = [];
    if (peerId != null) {
      where =
          '$where and groupPeerId is null and ((senderPeerId=? and receiverPeerId=?) or (senderPeerId=? and receiverPeerId=?))';
      whereArgs.add(peerId);
      whereArgs.add(myselfPeerId);
      whereArgs.add(myselfPeerId);
      whereArgs.add(peerId);
    }
    //当通过群peerId查询群消息时，发送的群消息会拆分到个体的消息记录需要排除，否则重复显示
    else if (groupPeerId != null) {
      where =
          '$where and groupPeerId=? and receiverType=? and receiverPeerId=?';
      whereArgs.add(groupPeerId);
      whereArgs.add(PartyType.linkman.name);
      whereArgs.add(myselfPeerId);
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
    if (status != null) {
      where = '$where and status=?';
      whereArgs.add(status);
    }
    return find(
        where: where,
        whereArgs: whereArgs,
        orderBy: 'sendTime desc',
        offset: offset,
        limit: limit);
  }

  Future<List<ChatMessage>> findByGreaterId(
      {String? peerId,
      String? groupPeerId,
      String? direct,
      String? messageType,
      String? subMessageType,
      String? status,
      String? sendTime,
      int? limit}) async {
    var myselfPeerId = myself.peerId!;
    String where = '1=1';
    List<Object> whereArgs = [];
    if (peerId != null) {
      where =
          '$where and groupPeerId is null and ((senderPeerId=? and receiverPeerId=?) or (senderPeerId=? and receiverPeerId=?))';
      whereArgs.add(peerId);
      whereArgs.add(myselfPeerId);
      whereArgs.add(myselfPeerId);
      whereArgs.add(peerId);
    }
    //当通过群peerId查询群消息时，发送的群消息会拆分到个体的消息记录需要排除，否则重复显示
    else if (groupPeerId != null) {
      where =
          '$where and groupPeerId=? and receiverType=? and receiverPeerId=?';
      whereArgs.add(groupPeerId);
      whereArgs.add(PartyType.linkman.name);
      whereArgs.add(myselfPeerId);
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
    if (status != null) {
      where = '$where and status=?';
      whereArgs.add(status);
    }
    if (sendTime != null) {
      where = '$where and sendTime>?';
      whereArgs.add(sendTime);
    }
    return find(
        where: where,
        whereArgs: whereArgs,
        orderBy: 'sendTime desc',
        limit: limit);
  }

  String recoverContent(String content) {
    if (StringUtil.isNotEmpty(content)) {
      content = CryptoUtil.utf8ToString(CryptoUtil.decodeBase64(content));
    }

    return content;
  }

  ///接受到普通消息或者回执，修改状态并保存
  Future<ChatMessage?> receiveChatMessage(ChatMessage chatMessage) async {
    String? subMessageType = chatMessage.subMessageType;
    //收到回执，更新原消息
    if (subMessageType == ChatMessageSubType.chatReceipt.name) {
      String? messageId = chatMessage.messageId;
      if (messageId == null) {
        logger.e('chatReceipt message must have messageId');
      }
      ChatMessage? originChatMessage = await findByMessageId(messageId!,
          receiverPeerId: chatMessage.senderPeerId!);
      if (originChatMessage == null) {
        logger.e('chatReceipt message has no chatMessage with same messageId');
        return null;
      }
      originChatMessage.receiptContent = chatMessage.content;
      originChatMessage.receiptTime = chatMessage.receiptTime;
      originChatMessage.receiveTime = chatMessage.receiveTime;
      originChatMessage.status = chatMessage.status;
      originChatMessage.deleteTime = chatMessage.deleteTime;
      await store(originChatMessage);

      return originChatMessage;
    } else {
      //收到一般消息，保存
      chatMessage.direct = ChatDirect.receive.name;
      chatMessage.receiveTime = DateUtil.currentDate();
      chatMessage.readTime = null;
      chatMessage.status = MessageStatus.received.name;
      chatMessage.id = null;
      await store(chatMessage);

      return chatMessage;
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
    await store(chatMessage, updateSummary: false);

    ChatMessage chatReceipt = ChatMessage();
    chatReceipt.messageId = chatMessage.messageId;
    chatReceipt.messageType = chatMessage.messageType;
    chatReceipt.subMessageType = ChatMessageSubType.chatReceipt.name;
    chatReceipt.direct = ChatDirect.send.name;
    chatReceipt.senderPeerId = myself.peerId!;
    chatReceipt.senderClientId = myself.clientId;
    chatReceipt.senderType = PartyType.linkman.name;
    chatReceipt.senderName = myself.myselfPeer!.name;
    chatReceipt.sendTime = DateUtil.currentDate();
    chatReceipt.receiverPeerId = chatMessage.senderPeerId;
    chatReceipt.receiverClientId = chatMessage.senderClientId;
    chatReceipt.receiverType = chatMessage.senderType;
    chatReceipt.title = chatMessage.subMessageType;
    chatReceipt.groupPeerId = chatMessage.groupPeerId;
    chatReceipt.groupName = chatMessage.groupName;
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
    chatReceipt.receiverName = senderName;
    chatReceipt.receiptTime = chatMessage.receiptTime;
    chatReceipt.receiveTime = chatMessage.receiveTime;
    chatReceipt.status = chatMessage.status;
    chatReceipt.readTime = chatMessage.readTime;
    chatReceipt.deleteTime = chatMessage.deleteTime;
    if (receiptContent != null) {
      chatReceipt.receiptContent = CryptoUtil.encodeBase64(receiptContent);
    }

    return chatReceipt;
  }

  ///content和receiptContent可以是任意对象，最终会是base64的字符串
  //未填写的字段：transportType,senderAddress,receiverAddress,receiveTime,actualReceiveTime,readTime,destroyTime
  Future<ChatMessage> buildChatMessage(
    String receiverPeerId, {
    dynamic content,
    String? clientId,
    String? messageId,
    TransportType transportType = TransportType.webrtc,
    ChatMessageType messageType = ChatMessageType.chat,
    ChatMessageSubType subMessageType = ChatMessageSubType.chat,
    ContentType contentType = ContentType.text,
    String? mimeType,
    PartyType receiverType = PartyType.linkman,
    String? receiverName,
    String? groupPeerId,
    String? groupName,
    String? title,
    dynamic receiptContent,
    List<int>? thumbnail,
    String? status,
    int deleteTime = 0,
    String? parentMessageId,
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
    Websocket? websocket = websocketPool.getDefault();
    if (websocket != null) {
      chatMessage.senderAddress = websocket.address;
    }
    var current = DateUtil.currentDate();
    chatMessage.sendTime = current;
    chatMessage.readTime = current;
    chatMessage.receiverPeerId = receiverPeerId;
    if (receiverName == null) {
      PeerClient? peerClient =
          await peerClientService.findCachedOneByPeerId(receiverPeerId);
      if (peerClient != null) {
        clientId = peerClient.clientId;
        receiverName = peerClient.name;
        chatMessage.receiverAddress = peerClient.connectAddress;
      }
    }
    chatMessage.receiverType = receiverType.name;
    chatMessage.receiverClientId = clientId;
    chatMessage.receiverName = receiverName;
    chatMessage.groupPeerId = groupPeerId;
    chatMessage.groupName = groupName;
    chatMessage.title = title;
    if (receiptContent != null) {
      List<int> data;
      if (receiptContent is List<int>) {
        data = receiptContent;
      } else if (receiptContent is String) {
        data = CryptoUtil.stringToUtf8(receiptContent);
      } else {
        var jsonStr = JsonUtil.toJsonString(receiptContent!);
        data = CryptoUtil.stringToUtf8(jsonStr);
      }
      chatMessage.receiptContent = CryptoUtil.encodeBase64(data);
    }
    if (thumbnail != null) {
      chatMessage.thumbnail = CryptoUtil.encodeBase64(thumbnail);
    }

    if (content != null) {
      List<int> data;
      if (content is List<int>) {
        data = content;
      } else if (content is String) {
        data = CryptoUtil.stringToUtf8(content);
      } else {
        var jsonStr = JsonUtil.toJsonString(content!);
        data = CryptoUtil.stringToUtf8(jsonStr);
      }
      chatMessage.content = CryptoUtil.encodeBase64(data);
    }
    chatMessage.contentType = contentType.name;
    chatMessage.mimeType = mimeType;
    chatMessage.status = status; // ?? MessageStatus.sent.name;
    chatMessage.transportType = transportType.name;
    chatMessage.deleteTime = deleteTime;
    chatMessage.parentMessageId = parentMessageId;

    chatMessage.id = null;

    return chatMessage;
  }

  //未填写的字段：transportType,senderAddress,receiverAddress,receiveTime,actualReceiveTime,readTime,destroyTime
  Future<List<ChatMessage>> buildGroupChatMessage(
    String groupPeerId, {
    dynamic content,
    ChatMessageType messageType = ChatMessageType.chat,
    ChatMessageSubType subMessageType = ChatMessageSubType.chat,
    ContentType contentType = ContentType.text,
    String? mimeType,
    String? title,
    String? messageId,
    dynamic receiptContent,
    List<int>? thumbnail,
    int deleteTime = 0,
    String? parentMessageId,
    List<String>? peerIds,
  }) async {
    List<ChatMessage> chatMessages = [];
    Group? group = await groupService.findCachedOneByPeerId(groupPeerId);
    if (group != null) {
      var groupName = group.name;
      var groupChatMessage = await buildChatMessage(groupPeerId,
          content: content,
          messageId: messageId,
          messageType: messageType,
          subMessageType: subMessageType,
          contentType: contentType,
          mimeType: mimeType,
          receiverType: PartyType.group,
          receiverName: groupName,
          groupPeerId: groupPeerId,
          groupName: groupName,
          title: title,
          receiptContent: receiptContent,
          thumbnail: thumbnail,
          deleteTime: deleteTime,
          parentMessageId: parentMessageId);
      chatMessages.add(groupChatMessage);
      messageId = groupChatMessage.messageId;
      List<GroupMember> groupMembers =
          await groupMemberService.findByGroupId(groupPeerId);
      List<Linkman> linkmen =
          await groupMemberService.findLinkmen(groupMembers);
      for (var linkman in linkmen) {
        var peerId = linkman.peerId;
        if (peerIds != null && !peerIds.contains(peerId)) {
          continue;
        }
        var receiverName = linkman.name;
        ChatMessage chatMessage = await buildChatMessage(
          peerId,
          messageId: messageId,
          messageType: messageType,
          subMessageType: subMessageType,
          contentType: contentType,
          mimeType: mimeType,
          receiverName: receiverName,
          groupPeerId: groupPeerId,
          groupName: groupName,
          deleteTime: deleteTime,
          parentMessageId: parentMessageId,
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

  ///发送消息并保存，如果是发送给自己的消息或者群消息，只保存不发送
  Future<ChatMessage> send(ChatMessage chatMessage,
      {CryptoOption cryptoOption = CryptoOption.cryptography}) async {
    var peerId = chatMessage.receiverPeerId;
    var receiverType = chatMessage.receiverType;
    if (peerId != null &&
        peerId != myself.peerId &&
        receiverType != PartyType.group.name) {
      var transportType = chatMessage.transportType;
      if (transportType == TransportType.webrtc.name) {
        bool success = await peerConnectionPool.send(peerId, chatMessage,
            cryptoOption: cryptoOption);
        if (!success) {
          transportType = TransportType.websocket.name;
          chatMessage.transportType = TransportType.websocket.name;
        } else {
          chatMessage.status = MessageStatus.sent.name;
        }
      }
      if (transportType == TransportType.nearby.name) {
        bool success = await nearbyConnectionPool.send(
            chatMessage.receiverPeerId!, chatMessage);
        if (success) {
          chatMessage.status = MessageStatus.sent.name;
        }
      }
      if (transportType == TransportType.websocket.name) {
        try {
          chatAction.chat(chatMessage, peerId,
              payloadType: PayloadType.chatMessage.name);
          chatMessage.status = MessageStatus.sent.name;
        } catch (err) {
          chatMessage.status = MessageStatus.unsent.name;
        }
      }
    } else {
      chatMessage.transportType = TransportType.none.name;
      chatMessage.status = MessageStatus.sent.name;
    }

    return chatMessage;
  }

  Future<ChatMessage> sendAndStore(ChatMessage chatMessage,
      {CryptoOption cryptoOption = CryptoOption.cryptography}) async {
    await send(chatMessage, cryptoOption: cryptoOption);
    await chatMessageService.store(chatMessage);

    return chatMessage;
  }

  ///转发消息
  Future<ChatMessage?> forward(ChatMessage chatMessage, String peerId,
      {CryptoOption cryptoOption = CryptoOption.cryptography}) async {
    String? title = chatMessage.title;
    String? messageId = chatMessage.messageId;
    dynamic content = chatMessage.content;
    content ??= await messageAttachmentService.findContent(messageId!, title);
    ChatMessageType? messageType = StringUtil.enumFromString(
        ChatMessageType.values, chatMessage.messageType);
    ChatMessageSubType? subMessageType = StringUtil.enumFromString(
        ChatMessageSubType.values, chatMessage.subMessageType);
    ContentType? contentType =
        StringUtil.enumFromString(ContentType.values, chatMessage.contentType);

    List<int>? thumbnail;
    if (chatMessage.thumbnail != null) {
      thumbnail = CryptoUtil.decodeBase64(chatMessage.thumbnail!);
    }
    Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
    if (linkman != null) {
      ChatMessage? message = await buildChatMessage(
        peerId,
        content: content,
        messageType: messageType!,
        subMessageType: subMessageType!,
        contentType: contentType!,
        mimeType: chatMessage.mimeType,
        receiverName: linkman.name,
        title: title,
        receiptContent: chatMessage.receiptContent,
        thumbnail: thumbnail,
      );
      return await sendAndStore(message, cryptoOption: cryptoOption);
    } else {
      Group? group = await groupService.findCachedOneByPeerId(peerId);
      if (group != null) {
        List<ChatMessage> messages = await buildGroupChatMessage(
          peerId,
          content: content,
          messageType: messageType!,
          subMessageType: subMessageType!,
          contentType: contentType!,
          mimeType: chatMessage.mimeType,
          title: title,
          receiptContent: chatMessage.receiptContent,
          thumbnail: thumbnail,
        );
        ChatMessage? msg;
        int i = 0;
        for (var message in messages) {
          if (i == 0) {
            msg = await sendAndStore(message, cryptoOption: cryptoOption);
          } else {
            await sendAndStore(message, cryptoOption: cryptoOption);
          }
          i++;
        }
        return msg;
      }
    }
    return null;
  }

  /// 保存消息，对于复杂消息，存储附件
  store(ChatMessage chatMessage, {bool updateSummary = true}) async {
    int? id = chatMessage.id;
    String? content = chatMessage.content;
    String? title = chatMessage.title;
    String? contentType = chatMessage.contentType;
    String? mimeType = chatMessage.mimeType;
    String? messageId;
    if (content != null) {
      if (contentType != null &&
          (contentType == ContentType.file.name ||
              contentType == ContentType.image.name ||
              contentType == ContentType.video.name ||
              contentType == ContentType.audio.name ||
              contentType == ContentType.rich.name)) {
        chatMessage.content = null;
        messageId = chatMessage.messageId;
      }
    }

    try {
      await upsert(chatMessage);
      if (messageId != null) {
        if (id == null) {
          await messageAttachmentService.store(
              chatMessage.id!, messageId, title, content!, EntityState.insert);
        } else {
          await messageAttachmentService.store(
              chatMessage.id!, messageId, title, content!, EntityState.update);
        }
      }
      if (updateSummary) {
        await chatSummaryService.upsertByChatMessage(chatMessage);
      }
    } catch (err) {
      logger.e(
          'chatMessage ${chatMessage.messageId} store fail,${err.toString()}');
    }
  }

  resend() async {
    List<ChatMessage> chatMessages =
        await findByPeerId(status: MessageStatus.unsent.name);
    for (var chatMessage in chatMessages) {
      send(chatMessage).then((ChatMessage value) {
        if (value.status != MessageStatus.unsent.name) {
          update({'status': value.status},
              where: 'id=?', whereArgs: [value.id!]);
        }
      });
    }
  }

  deleteTimeout() async {
    //所有已读且有销毁时间的记录
    String where = 'deleteTime>0 and readTime is not null';
    List<Object> whereArgs = [];
    var chatMessages = await find(
      where: where,
      whereArgs: whereArgs,
    );
    if (chatMessages.isEmpty) {
      return;
    }
    for (var chatMessage in chatMessages) {
      var deleteTime = chatMessage.deleteTime;
      if (deleteTime == 0) {
        continue;
      }
      var readTimeStr = chatMessage.readTime;
      if (StringUtil.isNotEmpty(readTimeStr)) {
        var readTime = DateUtil.toDateTime(readTimeStr!);
        DateTime now = DateTime.now();
        Duration duration = now.difference(readTime);
        int leftDeleteTime = deleteTime - duration.inSeconds;
        if (leftDeleteTime <= 0) {
          chatMessageService.delete(entity: chatMessage);
        }
      }
    }
  }

  ///删除linkman的消息
  removeByLinkman(String peerId) async {
    var myselfPeerId = myself.peerId!;
    await delete(
        where:
            'groupPeerId is null and ((senderPeerId=? and receiverPeerId=?) or (senderPeerId=? and receiverPeerId=?))',
        whereArgs: [peerId, myselfPeerId, myselfPeerId, peerId]);
  }

  ///删除group的消息
  removeByGroup(String peerId) async {
    await delete(where: 'groupPeerId=?', whereArgs: [peerId]);
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
      'readTime',
      'deleteTime',
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
