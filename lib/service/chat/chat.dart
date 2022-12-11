import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/p2p/chain/action/p2pchat.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/nearby_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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

  String decodeText(String content) {
    if (StringUtil.isNotEmpty(content)) {
      content = CryptoUtil.utf8ToString(CryptoUtil.decodeBase64(content));
    }

    return content;
  }

  String encodeText(String content) {
    if (StringUtil.isNotEmpty(content)) {
      content = CryptoUtil.encodeBase64(CryptoUtil.stringToUtf8(content));
    }

    return content;
  }

  ///接受到普通消息或者回执
  Future<void> receiveChatMessage(ChatMessage chatMessage) async {
    String? subMessageType = chatMessage.subMessageType;
    //收到回执，更新原消息
    if (subMessageType == ChatMessageSubType.chatReceipt.name) {
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
      msg.deleteTime = chatMessage.deleteTime;
      await store(msg);
    } else {
      //收到一般消息，保存
      chatMessage.direct = ChatDirect.receive.name;
      chatMessage.receiveTime = DateUtil.currentDate();
      chatMessage.readTime = null;
      chatMessage.status = MessageStatus.received.name;
      chatMessage.id = null;
      await store(chatMessage);
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

    ChatMessage msg = ChatMessage();
    msg.messageId = chatMessage.messageId;
    msg.messageType = chatMessage.messageType;
    msg.subMessageType = ChatMessageSubType.chatReceipt.name;
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
    ChatMessageSubType subMessageType = ChatMessageSubType.chat,
    ContentType contentType = ContentType.text,
    String? mimeType,
    PartyType receiverType = PartyType.linkman,
    String? receiverName,
    String? groupPeerId,
    String? groupName,
    String? title,
    List<int>? receiptContent,
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
      }
    }
    chatMessage.receiverType = receiverType.name;
    chatMessage.receiverClientId = clientId;
    chatMessage.receiverName = receiverName;
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
    }
    chatMessage.contentType = contentType.name;
    chatMessage.mimeType = mimeType;
    chatMessage.status = status ?? MessageStatus.sent.name;
    chatMessage.transportType = transportType.name;
    chatMessage.deleteTime = deleteTime;
    chatMessage.parentMessageId = parentMessageId;

    chatMessage.id = null;

    return chatMessage;
  }

  //未填写的字段：transportType,senderAddress,receiverAddress,receiveTime,actualReceiveTime,readTime,destroyTime
  Future<List<ChatMessage>> buildGroupChatMessage(
    String groupPeerId, {
    List<int>? data,
    ChatMessageType messageType = ChatMessageType.chat,
    ChatMessageSubType subMessageType = ChatMessageSubType.chat,
    ContentType contentType = ContentType.text,
    String? mimeType,
    String? title,
    List<int>? receiptContent,
    List<int>? thumbnail,
    int deleteTime = 0,
    String? parentMessageId,
  }) async {
    List<ChatMessage> chatMessages = [];
    Group? group = await groupService.findCachedOneByPeerId(groupPeerId);
    if (group != null) {
      var groupName = group.name;
      var groupChatMessage = await buildChatMessage(groupPeerId,
          data: data,
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
      var messageId = groupChatMessage.messageId;
      List<GroupMember> groupMembers =
          await groupMemberService.findByGroupId(groupPeerId);
      List<Linkman> linkmen =
          await groupMemberService.findLinkmen(groupMembers);
      for (var linkman in linkmen) {
        var peerId = linkman.peerId;
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

  Future<ChatMessage> sendAndStore(ChatMessage chatMessage,
      {CryptoOption cryptoOption = CryptoOption.cryptography}) async {
    var peerId = chatMessage.receiverPeerId;
    var clientId = chatMessage.receiverClientId;
    if (peerId != null) {
      String json = JsonUtil.toJsonString(chatMessage);
      var data = CryptoUtil.stringToUtf8(json);
      var transportType = chatMessage.transportType;
      if (transportType == TransportType.webrtc.name) {
        bool success = await peerConnectionPool.send(
            peerId, Uint8List.fromList(data),
            clientId: clientId, cryptoOption: cryptoOption);
        if (!success) {
          chatMessage.transportType = TransportType.websocket.name;
        }
      }
      if (transportType == TransportType.nearby.name) {
        nearbyConnectionPool.send(chatMessage.receiverPeerId!, data);
      }
      if (transportType == TransportType.websocket.name) {
        p2pChatAction.chat(Uint8List.fromList(data), peerId);
      }
    }
    await chatMessageService.store(chatMessage);

    return chatMessage;
  }

  Future<ChatMessage?> forward(ChatMessage chatMessage, String peerId,
      {CryptoOption cryptoOption = CryptoOption.cryptography}) async {
    String? title = chatMessage.title;
    String? messageId = chatMessage.messageId;
    String? content = chatMessage.content;
    List<int>? data;
    if (content != null) {
      data = CryptoUtil.stringToUtf8(content);
    } else {
      data = await messageAttachmentService.findContent(messageId!, title);
    }
    ChatMessageType? messageType = StringUtil.enumFromString(
        ChatMessageType.values, chatMessage.messageType);
    ChatMessageSubType? subMessageType = StringUtil.enumFromString(
        ChatMessageSubType.values, chatMessage.subMessageType);
    ContentType? contentType =
        StringUtil.enumFromString(ContentType.values, chatMessage.contentType);
    List<int>? receiptContent;
    if (chatMessage.receiptContent != null) {
      receiptContent = CryptoUtil.stringToUtf8(chatMessage.receiptContent!);
    }
    List<int>? thumbnail;
    if (chatMessage.thumbnail != null) {
      thumbnail = CryptoUtil.stringToUtf8(chatMessage.thumbnail!);
    }
    Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
    if (linkman != null) {
      ChatMessage? message = await buildChatMessage(
        peerId,
        data: data,
        messageType: messageType!,
        subMessageType: subMessageType!,
        contentType: contentType!,
        mimeType: chatMessage.mimeType,
        receiverName: linkman.name,
        title: title,
        receiptContent: receiptContent,
        thumbnail: thumbnail,
      );
      return await sendAndStore(message, cryptoOption: cryptoOption);
    } else {
      Group? group = await groupService.findCachedOneByPeerId(peerId);
      if (group != null) {
        List<ChatMessage> messages = await buildGroupChatMessage(
          peerId,
          data: data,
          messageType: messageType!,
          subMessageType: subMessageType!,
          contentType: contentType!,
          mimeType: chatMessage.mimeType,
          title: title,
          receiptContent: receiptContent,
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
    if (id == null) {
      await insert(chatMessage);
    } else {
      await update(chatMessage);
    }
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

class MessageAttachmentService extends GeneralBaseService<MessageAttachment> {
  late String contentPath;

  MessageAttachmentService({
    required super.tableName,
    required super.fields,
    required super.indexFields,
    super.encryptFields = const ['content'],
  }) {
    getApplicationDocumentsDirectory().then((contentPath) {
      this.contentPath = p.join(contentPath.path, 'content');
    });
    post = (Map map) {
      return MessageAttachment.fromJson(map);
    };
  }

  ///获取加密的数据在content路径下附件的文件名称，
  Future<String?> getEncryptFilename(String messageId, String? title) async {
    String? filename;
    if (!platformParams.web) {
      if (title != null) {
        filename = p.join(contentPath, '${messageId}_$title');
      } else {
        filename = p.join(contentPath, messageId);
      }
      return filename;
    }

    return filename;
  }

  ///获取获取的解密数据在临时目录下附件的文件名称，
  Future<String?> getDecryptFilename(String messageId, String? title) async {
    String? filename;
    if (title != null) {
      filename = '${messageId}_$title';
    } else {
      filename = messageId;
    }
    if (!platformParams.web) {
      Uint8List? data = await FileUtil.readFile(p.join(contentPath, filename));
      if (data != null) {
        data = await decryptContent(data);
        if (data != null) {
          filename = await FileUtil.writeTempFile(data, filename: filename);
          return filename;
        }
      }
    } else {
      MessageAttachment? attachment =
          await findOne(where: 'messageId=?', whereArgs: [messageId]);
      if (attachment != null) {
        var content = attachment.content;
        if (content != null) {
          var data = CryptoUtil.decodeBase64(content);
          filename = await FileUtil.writeTempFile(data, filename: filename);
          return filename;
        }
      }
    }

    return filename;
  }

  /// 解密的内容
  Future<Uint8List?> findContent(String messageId, String? title) async {
    if (!platformParams.web) {
      final filename = await getEncryptFilename(messageId, title);
      if (filename != null) {
        Uint8List? data = await FileUtil.readFile(filename);
        if (data != null) {
          data = await decryptContent(data);
          if (data != null) {
            return data;
          }
        }
      }
    } else {
      MessageAttachment? attachment =
          await findOne(where: 'messageId=?', whereArgs: [messageId]);
      if (attachment != null) {
        var content = attachment.content;
        if (content != null) {
          return CryptoUtil.decodeBase64(content);
        }
      }
    }
    return null;
  }

  Future<Uint8List?> encryptContent(
    Uint8List data,
  ) async {
    SecurityContext securityContext = SecurityContext();
    securityContext.payload = data;
    var result =
        await cryptographySecurityContextService.encrypt(securityContext);
    if (result) {
      var encrypted = securityContext.payload;
      return encrypted;
    }

    return null;
  }

  Future<Uint8List?> decryptContent(
    Uint8List data,
  ) async {
    SecurityContext securityContext = SecurityContext();
    securityContext.payload = data;
    var result =
        await cryptographySecurityContextService.decrypt(securityContext);
    if (result) {
      var decrypted = securityContext.payload;
      return decrypted;
    }

    return null;
  }

  ///把加密的内容写入文件，或者附件记录
  Future<void> store(int id, String messageId, String? title, String content,
      EntityState state) async {
    if (!platformParams.web) {
      final filename = await getEncryptFilename(messageId, title);
      Uint8List? data = CryptoUtil.decodeBase64(content);
      if (filename != null) {
        data = await encryptContent(data);
        if (data != null) {
          await FileUtil.writeFile(data, filename);
          logger.i('message attachment writeFile filename:$filename');
        }
      }
    } else {
      MessageAttachment attachment = MessageAttachment();
      attachment.id = id;
      attachment.messageId = messageId;
      attachment.title = title;
      attachment.content = content;
      if (state == EntityState.insert) {
        await messageAttachmentService.insert(attachment);
      } else if (state == EntityState.update) {
        await messageAttachmentService.update(attachment);
      }
    }
  }
}

final messageAttachmentService = MessageAttachmentService(
    tableName: "chat_messageattachment",
    indexFields: ['ownerPeerId', 'messageId', 'createDate'],
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
      await insert(chatSummary);
      chatSummaries[chatSummary.peerId!] = chatSummary;
    } else {
      chatSummary.name = linkman.name;
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
      await insert(chatSummary);
      chatSummaries[chatSummary.peerId!] = chatSummary;
    } else {
      chatSummary.name = group.name;
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
