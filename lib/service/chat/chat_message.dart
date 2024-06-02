import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/p2p/chain/action/chat.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/tool/video_util.dart';
import 'package:colla_chat/transport/smsclient.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/websocket/universal_websocket.dart';
import 'package:uuid/uuid.dart';

class ChatMessageService extends GeneralBaseService<ChatMessage> {
  Timer? timer;

  ChatMessageService({
    required super.tableName,
    required super.fields,
    required super.indexFields,
    super.encryptFields = const [
      'content',
      'thumbBody',
      'thumbnail',
      'title',
    ],
  }) {
    post = (Map map) {
      return ChatMessage.fromJson(map);
    };
    // timer = Timer.periodic(const Duration(seconds: 60), (timer) async {
    //   deleteTimeout();
    //   deleteSystem();
    // });
  }

  ///查询消息号相同的所有消息
  Future<List<ChatMessage>> findByMessageId(String messageId,
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
    return await find(
      where: where,
      whereArgs: whereArgs,
    );
  }

  ///查询消息号的唯一原始消息
  Future<ChatMessage?> findOriginByMessageId(String messageId,
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
      orderBy: 'id',
    );
  }

  Future<List<ChatMessage>> findByMessageType(
    String messageType, {
    String? targetAddress,
    String? subMessageType,
    String? contentType,
    String? mimeType,
    String? sendTime,
    int limit = defaultLimit,
    int offset = defaultOffset,
  }) async {
    String where = 'messageType=?';
    List<Object> whereArgs = [messageType];
    if (subMessageType != null) {
      where = '$where and subMessageType=?';
      whereArgs.add(subMessageType);
    }
    if (targetAddress != null) {
      where = '$where and targetAddress=?';
      whereArgs.add(targetAddress);
    }
    if (contentType != null) {
      where = '$where and contentType=?';
      whereArgs.add(contentType);
    }
    if (mimeType != null) {
      where = '$where and mimeType=?';
      whereArgs.add(mimeType);
    }
    if (sendTime != null) {
      where = '$where and sendTime>?';
      whereArgs.add(sendTime);
    }
    var chatMessages = await find(
        where: where,
        whereArgs: whereArgs,
        orderBy: sendTime == null ? 'id desc' : 'sendTime desc',
        offset: offset,
        limit: limit);

    return chatMessages;
  }

  Future<List<ChatMessage>> findByPeerId(
      {String? peerId,
      String? groupId,
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
          '$where and groupId is null and subMessageType!=? and ((senderPeerId=? and receiverPeerId=?) or (senderPeerId=? and receiverPeerId=?))';
      whereArgs.add(ChatMessageSubType.chatReceipt.name);
      whereArgs.add(peerId);
      whereArgs.add(myselfPeerId);
      whereArgs.add(myselfPeerId);
      whereArgs.add(peerId);
    }
    //当通过群peerId查询群消息时，发送的群消息会拆分到个体的消息记录需要排除，否则重复显示
    else if (groupId != null) {
      where =
          '$where and groupId=? and subMessageType!=? and ((senderPeerId=? and receiverPeerId=?) or receiverPeerId=?)';
      whereArgs.add(groupId);
      whereArgs.add(ChatMessageSubType.chatReceipt.name);
      whereArgs.add(myselfPeerId);
      whereArgs.add(groupId);
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
      String? groupId,
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
          '$where and groupId is null and subMessageType!=? and ((senderPeerId=? and receiverPeerId=?) or (senderPeerId=? and receiverPeerId=?))';
      whereArgs.add(ChatMessageSubType.chatReceipt.name);
      whereArgs.add(peerId);
      whereArgs.add(myselfPeerId);
      whereArgs.add(myselfPeerId);
      whereArgs.add(peerId);
    }
    //当通过群peerId查询群消息时，发送的群消息会拆分到个体的消息记录需要排除，否则重复显示
    else if (groupId != null) {
      where =
          '$where and groupId=? and subMessageType!=? and ((senderPeerId=? and receiverPeerId=?) or receiverPeerId=?)';
      whereArgs.add(groupId);
      whereArgs.add(ChatMessageSubType.chatReceipt.name);
      whereArgs.add(myselfPeerId);
      whereArgs.add(groupId);
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

  ///根据senderPeerId，receiverPeerId，groupId或者messageId查找匹配的视频邀请消息
  ///如果全部为空，则返回最新的视频邀请消息
  Future<ChatMessage?> findVideoChatMessage(
      {String? messageId,
      String? groupId,
      String? receiverPeerId,
      String? senderPeerId}) async {
    String where = 'messageType=? and subMessageType=?';
    List<Object> whereArgs = [
      ChatMessageType.chat.name,
      ChatMessageSubType.videoChat.name,
    ];
    if (messageId != null) {
      where = '$where and messageId=? and (senderPeerId=? or receiverPeerId=?)';
      whereArgs.add(messageId);
      whereArgs.add(myself.peerId!);
      whereArgs.add(myself.peerId!);
    } else if (groupId != null) {
      where = '$where and groupId=? and (senderPeerId=? or receiverPeerId=?)';
      whereArgs.add(groupId);
      whereArgs.add(myself.peerId!);
      whereArgs.add(myself.peerId!);
    } else if (senderPeerId != null) {
      where = '$where and senderPeerId=? and receiverPeerId=?';
      whereArgs.add(senderPeerId);
      whereArgs.add(myself.peerId!);
    } else if (receiverPeerId != null) {
      where = '$where and senderPeerId=? and receiverPeerId=?';
      whereArgs.add(myself.peerId!);
      whereArgs.add(receiverPeerId);
    } else {
      where = '$where and (senderPeerId=? or receiverPeerId=?)';
      whereArgs.add(myself.peerId!);
      whereArgs.add(myself.peerId!);
    }
    var chatMessages =
        await find(where: where, whereArgs: whereArgs, orderBy: 'id');

    return chatMessages.firstOrNull;
  }

  ///字符串变成utf8,然后base64
  String processContent(String content) {
    if (StringUtil.isNotEmpty(content)) {
      content = CryptoUtil.encodeBase64(CryptoUtil.stringToUtf8(content));
    }

    return content;
  }

  ///字符串base64解码,然后变成utf8字符串
  String recoverContent(String content) {
    if (StringUtil.isNotEmpty(content)) {
      content = CryptoUtil.utf8ToString(CryptoUtil.decodeBase64(content));
    }

    return content;
  }

  ///content和receiptContent可以是任意对象，最终会是base64的字符串
  ///如果content是字符串,则先转成utf8,然后base64
  Future<ChatMessage> buildChatMessage({
    String? receiverPeerId,
    dynamic content,
    String? clientId,
    String? messageId,
    TransportType transportType = TransportType.webrtc,
    ChatMessageType messageType = ChatMessageType.chat,
    ChatMessageSubType subMessageType = ChatMessageSubType.chat,
    ChatMessageContentType contentType = ChatMessageContentType.text,
    String? mimeType,
    PartyType? receiverType,
    String? receiverName,
    String? groupId,
    String? groupName,
    PartyType? groupType,
    String? title,
    String? receiptType,
    String? thumbnail, // CryptoUtil.encodeBase64
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
    chatMessage.senderName = myself.myselfPeer.name;
    UniversalWebsocket? websocket = websocketPool.getDefault();
    if (websocket != null) {
      chatMessage.senderAddress = websocket.address;
    }
    var current = DateUtil.currentDate();
    chatMessage.sendTime = current;
    chatMessage.readTime = current;
    chatMessage.receiverPeerId = receiverPeerId;
    if (receiverName == null && receiverPeerId != null) {
      PeerClient? peerClient =
          await peerClientService.findCachedOneByPeerId(receiverPeerId);
      if (peerClient != null) {
        clientId = peerClient.clientId;
        receiverName = peerClient.name;
        chatMessage.receiverAddress = peerClient.connectAddress;
      }
    }
    chatMessage.receiverType = receiverType?.name;
    chatMessage.receiverClientId = clientId;
    chatMessage.receiverName = receiverName;
    if (groupId != null) {
      chatMessage.groupId = groupId;
      chatMessage.groupName = groupName;
      groupType = groupType ?? PartyType.group;
      chatMessage.groupType = groupType.name;
    }
    chatMessage.title = title;
    chatMessage.receiptType = receiptType;
    chatMessage.thumbnail = thumbnail;

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
    chatMessage.status = status ?? MessageStatus.sent.name;
    chatMessage.transportType = transportType.name;
    chatMessage.deleteTime = deleteTime;
    chatMessage.parentMessageId = parentMessageId;

    chatMessage.id = null;

    return chatMessage;
  }

  ///创建群和会议消息，填写消息的群字段
  ///接收者5个字段不填写，保证分拆的每个消息完全一样
  Future<ChatMessage> buildGroupChatMessage(
    String groupId,
    PartyType groupType, {
    String? groupName,
    dynamic content,
    ChatMessageType messageType = ChatMessageType.chat,
    ChatMessageSubType subMessageType = ChatMessageSubType.chat,
    ChatMessageContentType contentType = ChatMessageContentType.text,
    String? mimeType,
    String? title,
    String? messageId,
    TransportType transportType = TransportType.webrtc,
    String? receiptType,
    String? thumbnail,
    int deleteTime = 0,
    String? parentMessageId,
  }) async {
    if (groupName == null) {
      if (groupType == PartyType.group) {
        Group? group = await groupService.findCachedOneByPeerId(groupId);
        if (group != null) {
          groupName = group.name;
        }
      }
      if (groupType == PartyType.conference) {
        Conference? conference =
            await conferenceService.findCachedOneByConferenceId(groupId);
        if (conference != null) {
          groupName = conference.name;
        }
      }
    }

    var groupChatMessage = await buildChatMessage(
        content: content,
        messageId: messageId,
        messageType: messageType,
        subMessageType: subMessageType,
        contentType: contentType,
        mimeType: mimeType,
        transportType: transportType,
        groupId: groupId,
        groupName: groupName,
        groupType: groupType,
        title: title,
        receiptType: receiptType,
        thumbnail: thumbnail,
        deleteTime: deleteTime,
        parentMessageId: parentMessageId);

    return groupChatMessage;
  }

  /// 创建SFU会议的消息，加上自己，每个参与者一条消息
  Future<List<ChatMessage>> sendSfuConferenceMessage(
      Conference conference, List<String> participants,
      {bool store = true}) async {
    List<dynamic>? tokens = conference.sfuToken;
    String? sfuUri = conference.sfuUri;
    Map<String, dynamic> conferenceMap = JsonUtil.toJson(conference);
    List<ChatMessage> chatMessages = [];
    int i = 0;
    for (String participant in participants) {
      String token = tokens![i];
      Conference conf = Conference.fromJson(conferenceMap);
      conf.sfuUri = sfuUri;
      conf.sfuToken = [token];

      /// 分为群中创建的会议和单独创建的会议，单独的会议中消息的群信息为会议信息
      PartyType? partyType =
          StringUtil.enumFromString(PartyType.values, conf.groupType);
      ChatMessage chatMessage = await chatMessageService.buildChatMessage(
        receiverPeerId: participant,
        groupId: conf.groupId ?? conf.conferenceId,
        groupName: conf.groupName ?? conf.name,
        groupType: partyType ?? PartyType.conference,
        title: conf.video
            ? ChatMessageContentType.video.name
            : ChatMessageContentType.audio.name,
        content: conf,
        messageId: conf.conferenceId,
        subMessageType: ChatMessageSubType.videoChat,
      );
      if (store) {
        await chatMessageService.sendAndStore(chatMessage);
      } else {
        await chatMessageService.send(chatMessage);
      }
      chatMessages.add(chatMessage);
      i++;
    }

    return chatMessages;
  }

  ///收到消息后填写接收者字段，状态字段，接收时间
  _writeReceiveChatMessage(ChatMessage chatMessage) {
    chatMessage.receiverPeerId = myself.peerId;
    chatMessage.receiverClientId = myself.clientId;
    chatMessage.receiverType = PartyType.linkman.name;
    chatMessage.receiverName = myself.name;
    chatMessage.direct = ChatDirect.receive.name;
    chatMessage.receiveTime = DateUtil.currentDate();
    chatMessage.readTime = null;
    chatMessage.status = MessageStatus.received.name;
  }

  ///接受到普通消息或者回执，修改状态并保存
  ///对回执的处理一般都是直接更新原消息的状态，但是对群回执需要单独保存，
  ///特别的是对群视频邀请的回执是需要群发的，也需要单独保存
  Future<ChatMessage?> receiveChatMessage(ChatMessage chatMessage) async {
    String? subMessageType = chatMessage.subMessageType;
    String? groupType = chatMessage.groupType;
    String? messageId = chatMessage.messageId;

    ///收到回执，更新原消息
    if (subMessageType == ChatMessageSubType.chatReceipt.name) {
      if (groupType == null) {
        if (messageId == null) {
          logger.e('chatReceipt message must have messageId');
        }
        ChatMessage? originChatMessage = await findOriginByMessageId(messageId!,
            receiverPeerId: chatMessage.senderPeerId!);
        if (originChatMessage == null) {
          logger
              .e('chatReceipt message has no chatMessage with same messageId');
          return null;
        }
        originChatMessage.receiptType = chatMessage.receiptType;
        originChatMessage.receiptTime = chatMessage.receiptTime;
        originChatMessage.receiveTime = DateUtil.currentDate();
        originChatMessage.status = MessageStatus.received.name;
        originChatMessage.deleteTime = chatMessage.deleteTime;
        await store(originChatMessage);

        return originChatMessage;
      } else {
        //如果是对群消息的回复，直接保存
        _writeReceiveChatMessage(chatMessage);
        chatMessage.id = null;
        await store(chatMessage);

        return chatMessage;
      }
    } else {
      //收到一般消息，保存
      _writeReceiveChatMessage(chatMessage);
      chatMessage.id = null;
      await store(chatMessage, unreadNumber: true);

      return chatMessage;
    }
  }

  ///创建消息回执，不填充接收者相关的信息
  ///可以用于群消息的群回复
  ///一般的命令回执只发送给发送人，群发的消息回执也是各自回复发送人
  ///群视频邀请命令的回执是需要两两发送的，也就是每个人都需要知道其他人的回复
  Future<ChatMessage> buildGroupChatReceipt(
      ChatMessage chatMessage, MessageReceiptType receiptType) async {
    //创建回执消息
    ChatMessageType? messageType = StringUtil.enumFromString(
        ChatMessageType.values, chatMessage.messageType);
    PartyType? groupType;
    if (chatMessage.groupType != null) {
      groupType =
          StringUtil.enumFromString(PartyType.values, chatMessage.groupType);
    }
    PartyType? receiverType;
    if (chatMessage.senderType != null) {
      receiverType =
          StringUtil.enumFromString(PartyType.values, chatMessage.senderType);
    }
    ChatMessage chatReceipt = await buildChatMessage(
      messageId: chatMessage.messageId,
      messageType: messageType!,
      subMessageType: ChatMessageSubType.chatReceipt,
      groupId: chatMessage.groupId,
      groupName: chatMessage.groupName,
      groupType: groupType,
      title: chatMessage.title,
      receiverType: receiverType!,
      receiptType: receiptType.name,
    );
    var currentDate = DateUtil.currentDate();
    chatReceipt.receiptTime = currentDate;
    chatReceipt.receiveTime = chatMessage.receiveTime;
    chatReceipt.readTime = currentDate;
    chatReceipt.deleteTime = chatMessage.deleteTime;

    return chatReceipt;
  }

  ///接受到普通消息，创建回执，subMessageType为chatReceipt
  ///一般只有对一些特殊命令才需要发送回执并保存，或者发送者明确要求回执
  Future<ChatMessage> buildLinkmanChatReceipt(
      ChatMessage chatMessage, MessageReceiptType receiptType,
      {String? receiverPeerId, String? clientId, String? receiverName}) async {
    //创建回执消息
    ChatMessageType? messageType = StringUtil.enumFromString(
        ChatMessageType.values, chatMessage.messageType);
    PartyType? groupType;
    if (chatMessage.groupType != null) {
      groupType =
          StringUtil.enumFromString(PartyType.values, chatMessage.groupType);
    }
    PartyType? receiverType;
    if (chatMessage.senderType != null) {
      receiverType =
          StringUtil.enumFromString(PartyType.values, chatMessage.senderType);
    }
    receiverPeerId = receiverPeerId ?? chatMessage.senderPeerId!;
    clientId = clientId ?? chatMessage.senderClientId;
    receiverName = receiverName ?? chatMessage.senderName;
    ChatMessage chatReceipt = await buildChatMessage(
      receiverPeerId: receiverPeerId,
      clientId: clientId,
      receiverName: receiverName,
      messageId: chatMessage.messageId,
      messageType: messageType!,
      subMessageType: ChatMessageSubType.chatReceipt,
      groupId: chatMessage.groupId,
      groupName: chatMessage.groupName,
      groupType: groupType,
      title: chatMessage.title,
      receiverType: receiverType!,
      receiptType: receiptType.name,
    );
    var currentDate = DateUtil.currentDate();
    chatReceipt.receiverAddress ??= chatMessage.senderAddress;
    chatReceipt.receiptTime = currentDate;
    chatReceipt.receiveTime = chatMessage.receiveTime;
    chatReceipt.readTime = currentDate;
    chatReceipt.deleteTime = chatMessage.deleteTime;

    return chatReceipt;
  }

  ///发送回执消息的时候，更新收到的消息的状态
  Future<void> updateReceiptType(
      ChatMessage chatMessage, MessageReceiptType receiptType) async {
    chatMessage.receiptType = receiptType.name;
    await update(
        {
          'receiptType': chatMessage.receiptType,
        },
        where: 'id=?',
        whereArgs: [chatMessage.id!]);
  }

  ///发送回执消息的时候，更新收到的消息的状态
  Future<void> updateMessageStatus(
      ChatMessage chatMessage, MessageStatus messageStatus) async {
    if (messageStatus == MessageStatus.read) {
      chatMessage.readTime = DateUtil.currentDate();
      chatMessage.status = MessageStatus.read.name;
    } else if (messageStatus == MessageStatus.received) {
      chatMessage.receiptTime = DateUtil.currentDate();
      chatMessage.status = MessageStatus.received.name;
    } else if (messageStatus == MessageStatus.sent) {
      chatMessage.sendTime = DateUtil.currentDate();
      chatMessage.status = MessageStatus.sent.name;
    } else if (messageStatus == MessageStatus.deleted) {
      chatMessage.deleteTime = chatMessage.deleteTime;
      chatMessage.status = MessageStatus.deleted.name;
    }
    await update(
        {
          'status': chatMessage.status,
          'sendTime': chatMessage.sendTime,
          'receiptTime': chatMessage.receiptTime,
          'readTime': chatMessage.readTime,
          'deleteTime': chatMessage.deleteTime,
        },
        where: 'id=?',
        whereArgs: [chatMessage.id!]);
  }

  ///加密消息，要么对非组的消息或者拆分后的群消息进行linkman方式加密，
  ///要么对组消息进行加密，返回可发送的多条消息
  Future<Map<String, List<int>>> encrypt(ChatMessage chatMessage,
      {CryptoOption? cryptoOption, List<String>? peerIds}) async {
    Map<String, List<int>> encryptData = {};
    if (cryptoOption == null) {
      if (chatMessage.groupId == null) {
        cryptoOption = CryptoOption.linkman;
      } else {
        cryptoOption = CryptoOption.group;
      }
    }
    var jsonStr = JsonUtil.toJsonString(chatMessage);
    List<int> data = CryptoUtil.stringToUtf8(jsonStr);
    int cryptOptionIndex = cryptoOption.index;
    SecurityContextService? securityContextService =
        ServiceLocator.securityContextServices[cryptOptionIndex];
    securityContextService =
        securityContextService ?? linkmanCryptographySecurityContextService;
    SecurityContext securityContext = SecurityContext();
    securityContext.payload = data;
    if (cryptOptionIndex == CryptoOption.linkman.index) {
      logger
          .i('this is linkman chatMessage, will be encrypted by linkman mode');
      if (chatMessage.receiverPeerId != myself.peerId) {
        securityContext.targetPeerId = chatMessage.receiverPeerId;
        securityContext.targetClientId = chatMessage.receiverClientId;
        bool result = await securityContextService.encrypt(securityContext);
        if (result) {
          data = CryptoUtil.concat(
              securityContext.payload, [CryptoOption.linkman.index]);
          encryptData[chatMessage.receiverPeerId!] = data;

          return encryptData;
        }
      }
    } else if (cryptOptionIndex == CryptoOption.group.index) {
      ///再根据群进行消息的复制成多条进行处理
      if (peerIds == null || peerIds.isEmpty) {
        String groupId = chatMessage.groupId!;
        peerIds = await groupMemberService.findPeerIdsByGroupId(groupId);
      }
      if (peerIds.isEmpty) {
        peerIds.add(chatMessage.receiverPeerId!);
      }
      if (peerIds.isNotEmpty) {
        for (var peerId in peerIds) {
          if (securityContext.secretKey != null) {
            securityContext.needSign = false;
            securityContext.needCompress = false;
          }
          Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
          if (linkman != null && linkman.peerId != myself.peerId) {
            securityContext.targetPeerId = linkman.peerId;
            securityContext.targetClientId = linkman.clientId;
            bool result = await securityContextService.encrypt(securityContext);
            if (result) {
              ///对群加密来说，返回的是通用的加密后数据
              List<int> encryptedKey =
                  CryptoUtil.decodeBase64(securityContext.payloadKey!);
              encryptedKey =
                  CryptoUtil.concat(encryptedKey, [CryptoOption.group.index]);
              data = CryptoUtil.concat(securityContext.payload, encryptedKey);
              encryptData[peerId] = data;
            }
          }
        }
      }
    }

    return encryptData;
  }

  Future<ChatMessage?> decrypt(List<int> data) async {
    ///数据的最后一位是加密方式，还有32位的加密的密钥
    int cryptOption = data[data.length - 1];
    SecurityContextService? securityContextService =
        ServiceLocator.securityContextServices[cryptOption];
    securityContextService =
        securityContextService ?? noneSecurityContextService;
    SecurityContext securityContext = SecurityContext();
    if (cryptOption == CryptoOption.linkman.index) {
      securityContext.payload = data.sublist(0, data.length - 1);
    }
    if (cryptOption == CryptoOption.group.index) {
      int payloadKeyLength = CryptoGraphy.randomBytesLength + 60;
      List<int> payloadKey =
          data.sublist(data.length - payloadKeyLength - 1, data.length - 1);
      securityContext.payloadKey = CryptoUtil.encodeBase64(payloadKey);
      securityContext.payload =
          data.sublist(0, data.length - payloadKeyLength - 1);
    }
    bool result = await securityContextService.decrypt(securityContext);
    if (result) {
      String jsonStr = CryptoUtil.utf8ToString(securityContext.payload);
      var json = JsonUtil.toJson(jsonStr);
      ChatMessage chatMessage = ChatMessage.fromJson(json);

      return chatMessage;
    }
    return null;
  }

  ///对单条消息和对应的加密数据进行发送
  ///对webrtc和websocket来说是发送已经加密的数据，因为单发和群发的加密方式不一样
  ///对sms来说是发送文本内容，也是自己进行加密，加密的时机不一样
  Future<void> _send(ChatMessage chatMessage, List<int> data) async {
    String? peerId = chatMessage.receiverPeerId;

    ///未被分拆的群消息或者发送给自己的消息取消发送
    if (peerId == null || peerId == myself.peerId) {
      chatMessage.transportType = TransportType.none.name;
      chatMessage.status = MessageStatus.sent.name;
      return;
    }
    var transportType = chatMessage.transportType;
    String? factTransportType;
    if (transportType == TransportType.webrtc.name) {
      List<AdvancedPeerConnection>? advancedPeerConnections =
          peerConnectionPool.getConnected(peerId);
      if (advancedPeerConnections.isNotEmpty) {
        bool success = await peerConnectionPool.send(peerId, data);
        logger.w('webrtc send data result:$success');
        if (success) {
          factTransportType = TransportType.webrtc.name;
        } else {
          transportType = TransportType.websocket.name;
        }
      } else {
        transportType = TransportType.websocket.name;
      }
    }
    if (factTransportType == null &&
        transportType == TransportType.websocket.name) {
      try {
        ///chatMessage已经加密，所以chatAction无需加密
        bool success = await chatAction.chat(data, peerId,
            payloadType: PayloadType.list, needEncrypt: false);
        logger.w('websocket send data result:$success');

        ///另一种做法是不加密，由chatAction加密
        // bool success = await chatAction.chat(chatMessage, peerId,
        //     payloadType: PayloadType.chatMessage, needEncrypt: true);
        if (success) {
          factTransportType = TransportType.websocket.name;
        }
      } catch (err) {
        logger.e('chatAction chat failure:$err');
      }
    }
    if (factTransportType == null && transportType == TransportType.sms.name) {
      bool success = await smsClient.sendMessage(chatMessage.content,
          chatMessage.receiverPeerId!, chatMessage.receiverClientId!);
      logger.w('sms send data result:$success');
      if (success) {
        factTransportType = TransportType.sms.name;
      }
    }
    if (factTransportType != null) {
      chatMessage.transportType = factTransportType;
      chatMessage.status = MessageStatus.sent.name;
    } else {
      chatMessage.status = MessageStatus.unsent.name;
    }
  }

  Future<List<ChatMessage>> findByStatusAndReceiverPeer(String status,
      {String? receiverPeerId}) async {
    var where = 'status = ?';
    var whereArgs = [status];
    if (receiverPeerId != null) {
      where = '$where and receiverPeerId=?';
      whereArgs.add(receiverPeerId);
    }
    var es = await find(where: where, whereArgs: whereArgs);

    return es;
  }

  ///对发送失败的消息重新发送
  sendUnsent({String? receiverPeerId}) async {
    logger.i('resent unsent chat message:$receiverPeerId');
    List<ChatMessage> chatMessages = await findByStatusAndReceiverPeer(
        MessageStatus.unsent.name,
        receiverPeerId: receiverPeerId);
    if (chatMessages.isNotEmpty) {
      for (var chatMessage in chatMessages) {
        await sendAndStore(chatMessage);
      }
    }
  }

  ///转发消息
  Future<List<ChatMessage>?> forward(ChatMessage chatMessage, String peerId,
      {CryptoOption cryptoOption = CryptoOption.linkman}) async {
    String? title = chatMessage.title;
    String? messageId = chatMessage.messageId;
    dynamic content = chatMessage.content;
    content ??= await messageAttachmentService.findContent(messageId!, title);
    ChatMessageType? messageType = StringUtil.enumFromString(
        ChatMessageType.values, chatMessage.messageType);
    ChatMessageSubType? subMessageType = StringUtil.enumFromString(
        ChatMessageSubType.values, chatMessage.subMessageType);
    ChatMessageContentType? contentType = StringUtil.enumFromString(
        ChatMessageContentType.values, chatMessage.contentType);

    String? thumbnail = chatMessage.thumbnail!;
    Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
    if (linkman != null) {
      ChatMessage? message = await buildChatMessage(
        receiverPeerId: peerId,
        content: content,
        messageType: messageType!,
        subMessageType: subMessageType!,
        contentType: contentType!,
        mimeType: chatMessage.mimeType,
        receiverName: linkman.name,
        title: title,
        receiptType: chatMessage.receiptType,
        thumbnail: thumbnail,
      );
      return await sendAndStore(message, cryptoOption: cryptoOption);
    } else {
      Group? group = await groupService.findCachedOneByPeerId(peerId);
      if (group != null) {
        ChatMessage groupMessage = await buildGroupChatMessage(
          peerId,
          PartyType.group,
          content: content,
          messageType: messageType!,
          subMessageType: subMessageType!,
          contentType: contentType!,
          mimeType: chatMessage.mimeType,
          title: title,
          receiptType: chatMessage.receiptType,
          thumbnail: thumbnail,
        );
        return await sendAndStore(groupMessage, cryptoOption: cryptoOption);
      }
    }

    return null;
  }

  /// 如果是群消息，拆分多条消息，拆分后的接收者信息被填充
  /// 拆分的群消息数目是peerIds的数目加一
  /// 如果是非群消息或者拆分过的群消息返回单条消息的数组
  Future<List<ChatMessage>> _buildGroupChatMessages(ChatMessage chatMessage,
      {List<String>? peerIds}) async {
    List<ChatMessage> chatMessages = [];

    ///对组消息进行拆分
    if (chatMessage.groupId != null && chatMessage.receiverPeerId == null) {
      ///再根据群进行消息的复制成多条进行处理
      if (peerIds == null || peerIds.isEmpty) {
        String groupId = chatMessage.groupId!;
        peerIds = await groupMemberService.findPeerIdsByGroupId(groupId);
      }
      if (peerIds.isNotEmpty) {
        for (var peerId in peerIds) {
          Map<String, dynamic> map = JsonUtil.toJson(chatMessage);
          ChatMessage msg = ChatMessage.fromJson(map);
          msg.receiverPeerId = peerId;
          Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
          if (linkman != null) {
            msg.receiverName = linkman.name;
            msg.receiverClientId = linkman.clientId;
            msg.receiverType = PartyType.linkman.name;
            msg.receiverAddress = linkman.address;
          }
          chatMessages.add(msg);
        }
      }
    } else {
      chatMessages.add(chatMessage);
    }
    return chatMessages;
  }

  ///发送单个的消息到个人或者群（加密方式为群加密），并保存本地，由于是先发送后保存，所以新消息的id，createDate等字段是空的
  ///如果chatMessage的groupType不为空，则是群消息，支持群发
  ///群发的时候peerIds不为空，有值
  Future<List<ChatMessage>> sendAndStore(ChatMessage chatMessage,
      {CryptoOption? cryptoOption,
      List<String>? peerIds,
      bool updateSummary = true,
      bool unreadNumber = false}) async {
    if (chatMessage.receiverPeerId == myself.peerId) {
      chatMessage.transportType = TransportType.none.name;
      await chatMessageService.store(chatMessage,
          updateSummary: updateSummary, unreadNumber: unreadNumber);

      return [chatMessage];
    }
    List<ChatMessage> chatMessages =
        await send(chatMessage, cryptoOption: cryptoOption, peerIds: peerIds);
    if (chatMessages.isNotEmpty) {
      for (var msg in chatMessages) {
        if (msg.receiverPeerId == myself.peerId) {
          msg.transportType = TransportType.none.name;
        }
        await chatMessageService.store(msg,
            updateSummary: updateSummary, unreadNumber: unreadNumber);
      }
    }
    return chatMessages;
  }

  ///发送消息，并更新发送状态字段，如果chatMessage的groupType不为空，则是群消息，支持群发
  ///群发的时候peerIds不为空，有值
  ///以特定的发送方式发送数据，返回实际成功的发送方式
  Future<List<ChatMessage>> send(ChatMessage chatMessage,
      {CryptoOption? cryptoOption, List<String>? peerIds}) async {
    ///对消息进行分拆和加密
    List<ChatMessage> chatMessages =
        await _buildGroupChatMessages(chatMessage, peerIds: peerIds);
    Map<String, List<int>> encryptData = await encrypt(chatMessage,
        cryptoOption: cryptoOption, peerIds: peerIds);
    for (var chatMessage in chatMessages) {
      String? peerId = chatMessage.receiverPeerId;
      if (peerId == null || peerId == myself.peerId) {
        chatMessage.transportType = TransportType.none.name;
        continue;
      }
      List<int>? data = encryptData[peerId];
      if (data == null) {
        chatMessage.transportType = TransportType.none.name;
        continue;
      }
      await _send(chatMessage, data);
    }

    return chatMessages;
  }

  bool hasAttachment(String contentType) {
    return (contentType == ChatMessageContentType.file.name ||
        contentType == ChatMessageContentType.media.name ||
        contentType == ChatMessageContentType.image.name ||
        contentType == ChatMessageContentType.video.name ||
        contentType == ChatMessageContentType.audio.name ||
        contentType == ChatMessageContentType.rich.name);
  }

  /// 保存单条消息，对于复杂消息，存储附件
  /// 如果content为空，不用考虑附件，有可能title就是文件名
  store(ChatMessage chatMessage,
      {bool updateSummary = true, bool unreadNumber = false}) async {
    if (chatMessage.receiverPeerId == myself.peerId) {
      chatMessage.status = MessageStatus.sent.name;
    }

    String subMessageType = chatMessage.subMessageType;
    //signal消息暂时不保存
    if (subMessageType == ChatMessageSubType.signal.name) {
      return;
    }
    int? id = chatMessage.id;
    String? content = chatMessage.content;
    String? title = chatMessage.title;
    String? contentType = chatMessage.contentType;
    String? mimeType = chatMessage.mimeType;
    String? messageId;
    // 内容是否需要以附件形式保存
    bool attachment = false;
    if (content != null) {
      if (contentType != null && hasAttachment(contentType)) {
        if (chatMessage.thumbnail == null &&
            contentType == ChatMessageContentType.image.name) {
          Uint8List image = CryptoUtil.decodeBase64(content);
          mimeType = FileUtil.subMimeType(mimeType!);
          Uint8List? data = await ImageUtil.compressThumbnail(
              image: image, extension: mimeType);
          if (data != null) {
            String base64 = CryptoUtil.encodeBase64(data);
            chatMessage.thumbnail = ImageUtil.base64Img(base64);
          }
        }
        //保存的时候，设置内容为空
        chatMessage.content = null;
        attachment = true;
        messageId = chatMessage.messageId;
      }
    }

    try {
      await upsert(chatMessage);
      //作为附件存储内容
      String? filename;
      if (messageId != null && attachment) {
        if (id == null) {
          filename = await messageAttachmentService.store(
              chatMessage.id!, messageId, title, content!, EntityState.insert);
        } else {
          filename = await messageAttachmentService.store(
              chatMessage.id!, messageId, title, content!, EntityState.update);
        }
        //恢复内容
        chatMessage.content = content;
        if (filename != null) {
          if (chatMessage.thumbnail == null &&
              (contentType == ChatMessageContentType.video.name)) {
            Uint8List? data =
                await VideoUtil.getByteThumbnail(videoFile: filename);
            if (data != null) {
              String base64 = CryptoUtil.encodeBase64(data);
              chatMessage.thumbnail = ImageUtil.base64Img(base64);
              update({'thumbnail': base64},
                  where: 'id=?', whereArgs: [chatMessage.id!]);
            }
          }
        }
      }
      if (updateSummary) {
        await chatSummaryService.upsertByChatMessage(chatMessage,
            unreadNumber: unreadNumber);
      }
    } catch (err) {
      logger.e(
          'chatMessage ${chatMessage.messageId} store fail,${err.toString()}');
    }
  }

  Future<int> remove(ChatMessage chatMessage) async {
    String? content = chatMessage.content;
    String? title = chatMessage.title;
    String? contentType = chatMessage.contentType;
    String? messageId = chatMessage.messageId;
    if (contentType != null &&
        (contentType == ChatMessageContentType.file.name ||
            contentType == ChatMessageContentType.image.name ||
            contentType == ChatMessageContentType.video.name ||
            contentType == ChatMessageContentType.audio.name ||
            contentType == ChatMessageContentType.rich.name)) {
      if (!platformParams.web) {
        final filename =
            await messageAttachmentService.remove(messageId!, title);
      }
    }
    int count = super.delete(where: 'id=?', whereArgs: [chatMessage.id!]);

    return Future.value(count);
  }

  /// 收藏
  Future<ChatMessage> collect(ChatMessage chatMessage) async {
    Map<String, dynamic> map = JsonUtil.toJson(chatMessage);
    ChatMessage collectChatMessage = ChatMessage.fromJson(map);
    var uuid = const Uuid();
    String messageId = uuid.v4();
    collectChatMessage.messageId = messageId;
    collectChatMessage.id = null;
    collectChatMessage.messageType = ChatMessageType.collection.name;
    String? contentType = chatMessage.contentType;
    if (contentType != null &&
        (contentType == ChatMessageContentType.file.name ||
            contentType == ChatMessageContentType.image.name ||
            contentType == ChatMessageContentType.video.name ||
            contentType == ChatMessageContentType.audio.name ||
            contentType == ChatMessageContentType.rich.name)) {
      Uint8List? data = await messageAttachmentService.findContent(
          chatMessage.messageId!, chatMessage.title);
      if (data != null) {
        String content = CryptoUtil.encodeBase64(data);
        collectChatMessage.content = content;
      }
    }
    await store(collectChatMessage);

    return collectChatMessage;
  }

  resend() async {
    List<ChatMessage> chatMessages =
        await findByPeerId(status: MessageStatus.unsent.name);
    for (var chatMessage in chatMessages) {
      if (chatMessage.receiverPeerId != null) {
        List<ChatMessage> chatMessages = await send(chatMessage);
        for (var chatMessage in chatMessages) {
          if (chatMessage.status != MessageStatus.unsent.name) {
            update({'status': chatMessage.status},
                where: 'id=?', whereArgs: [chatMessage.id!]);
          }
        }
      }
    }
  }

  /// 删除所有已读且有销毁时间的记录
  /// 删除一天前的系统记录
  deleteTimeout() async {
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
          chatMessageService.remove(chatMessage);
        }
      }
    }
  }

  /// 删除linkman的消息
  removeByLinkman(String peerId) {
    var myselfPeerId = myself.peerId!;
    delete(
        where:
            'groupId is null and ((senderPeerId=? and receiverPeerId=?) or (senderPeerId=? and receiverPeerId=?))',
        whereArgs: [peerId, myselfPeerId, myselfPeerId, peerId]);
  }

  /// 删除group的消息
  removeByGroup(String peerId) {
    delete(where: 'groupId=?', whereArgs: [peerId]);
  }

  /// 删除过期的系统消息
  deleteSystem() {
    String yesterday =
        DateTime.now().toUtc().add(const Duration(days: -1)).toIso8601String();
    delete(
        where: 'messageType=? and createDate<?',
        whereArgs: [ChatMessageType.system.name, yesterday]);
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
      'receiverPeerId',
      'senderPeerId',
      'sendTime',
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
