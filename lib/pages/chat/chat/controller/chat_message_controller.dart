import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/chat/peer_party.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:get/get.dart';
import 'package:synchronized/synchronized.dart';

///好友或者群的消息控制器，包含某个连接的所有消息
class ChatMessageController extends DataMoreController<ChatMessage> {
  final Rx<ChatSummary?> _chatSummary = Rx<ChatSummary?>(null);

  //发送方式
  final Rx<TransportType> transportType =
      Rx<TransportType>(TransportType.webrtc);

  //调度删除时间
  final RxInt _deleteTime = 0.obs;

  //引用的消息
  final Rx<String?> _parentMessageId = Rx<String?>(null);

  final Lock _lock = Lock();

  ChatSummary? get chatSummary {
    return _chatSummary.value;
  }

  ///更新chatSummary，清空原数据，查询新数据
  set chatSummary(ChatSummary? chatSummary) {
    if (_chatSummary.value != chatSummary) {
      _chatSummary(chatSummary);
      clear(notify: false);
      previous(limit: defaultLimit);
    }
  }

  Rx<ChatSummary?> getChatSummary() {
    return _chatSummary;
  }

  int get deleteTime {
    return _deleteTime.value;
  }

  set deleteTime(int deleteTime) {
    _deleteTime(deleteTime);
  }

  String? get parentMessageId {
    return _parentMessageId.value;
  }

  set parentMessageId(String? parentMessageId) {
    _parentMessageId(parentMessageId);
  }

  ///访问数据库获取比当前数据更老的消息，如果当前数据为空，从最新的开始
  @override
  Future<int> previous({int? limit}) async {
    return _lock.synchronized(() async {
      ChatSummary? chatSummary = _chatSummary.value;
      if (chatSummary == null) {
        clear(notify: false);
        return 0;
      }
      if (chatSummary.peerId == null) {
        clear(notify: false);
        return 0;
      }
      List<ChatMessage>? chatMessages;
      if (chatSummary.partyType == PartyType.linkman.name) {
        int start = DateTime.now().millisecondsSinceEpoch;
        chatMessages = await chatMessageService.findByPeerId(
            peerId: chatSummary.peerId!,
            messageType: ChatMessageType.chat.name,
            offset: data.length,
            limit: limit);
        int end = DateTime.now().millisecondsSinceEpoch;
        logger.i('chatMessageService.findByPeerId time:${end - start}');
      } else if (chatSummary.partyType == PartyType.group.name) {
        chatMessages = await chatMessageService.findByPeerId(
            groupId: chatSummary.peerId!,
            messageType: ChatMessageType.chat.name,
            offset: data.length,
            limit: limit);
      } else if (chatSummary.partyType == PartyType.conference.name) {
        chatMessages = await chatMessageService.findByPeerId(
            groupId: chatSummary.peerId!,
            messageType: ChatMessageType.chat.name,
            offset: data.length,
            limit: limit);
      }
      if (chatMessages != null && chatMessages.isNotEmpty) {
        addAll(chatMessages);

        return chatMessages.length;
      }

      return 0;
    });
  }

  ///访问数据库获取比当前的最新的消息更新的消息
  @override
  Future<int> latest({int? limit}) async {
    return _lock.synchronized(() async {
      var chatSummary = this.chatSummary;
      if (chatSummary == null) {
        clear(notify: false);
        return 0;
      }
      if (chatSummary.peerId == null) {
        clear(notify: false);
        return 0;
      }
      String? sendTime;
      if (data.isNotEmpty) {
        sendTime = data[0].sendTime;
      }
      List<ChatMessage>? chatMessages;
      if (chatSummary.partyType == PartyType.linkman.name) {
        chatMessages = await chatMessageService.findByGreaterId(
            peerId: chatSummary.peerId!,
            messageType: ChatMessageType.chat.name,
            sendTime: sendTime,
            limit: limit);
      } else if (chatSummary.partyType == PartyType.group.name) {
        chatMessages = await chatMessageService.findByGreaterId(
            groupId: chatSummary.peerId!,
            messageType: ChatMessageType.chat.name,
            sendTime: sendTime,
            limit: limit);
      } else if (chatSummary.partyType == PartyType.conference.name) {
        chatMessages = await chatMessageService.findByGreaterId(
            groupId: chatSummary.peerId!,
            messageType: ChatMessageType.chat.name,
            sendTime: sendTime,
            limit: limit);
      }
      if (chatMessages != null && chatMessages.isNotEmpty) {
        data.insertAll(0, chatMessages);

        return chatMessages.length;
      }

      return 0;
    });
  }

  ///发送文本消息,发送命令消息目标可以是linkman，也可以是群，取决于当前chatSummary
  Future<ChatMessage?> sendText(
      {String? title,
      String? message,
      ChatMessageContentType contentType = ChatMessageContentType.text,
      String? mimeType,
      ChatMessageType messageType = ChatMessageType.chat,
      ChatMessageSubType subMessageType = ChatMessageSubType.chat,
      List<String>? peerIds}) async {
    return await send(
        title: title,
        content: message,
        contentType: contentType,
        mimeType: mimeType,
        messageType: messageType,
        subMessageType: subMessageType,
        peerIds: peerIds);
  }

  ///发送文本消息,发送命令消息目标可以是linkman，也可以是群，也可以是会议，取决于当前chatSummary
  ///先通过网络发送消息，然后保存在本地数据库
  Future<ChatMessage?> send(
      {String? title,
      dynamic content,
      String? thumbnail,
      ChatMessageContentType contentType = ChatMessageContentType.text,
      String? mimeType,
      String? messageId,
      ChatMessageType messageType = ChatMessageType.chat,
      ChatMessageSubType subMessageType = ChatMessageSubType.chat,
      List<String>? peerIds}) async {
    var chatSummary = this.chatSummary;
    if (chatSummary == null) {
      return null;
    }
    String peerId = chatSummary.peerId!;
    String partyType = chatSummary.partyType!;
    PartyType? type = StringUtil.enumFromString(PartyType.values, partyType);
    if (type == null) {
      if (peerIds == null) {
        type = PartyType.linkman;
      } else {
        type = PartyType.group;
      }
    }
    ChatMessage? returnChatMessage;
    if (type == PartyType.linkman) {
      ChatMessage chatMessage = await chatMessageService.buildChatMessage(
          receiverPeerId: peerId,
          title: title,
          content: content,
          thumbnail: thumbnail,
          contentType: contentType,
          mimeType: mimeType,
          messageId: messageId,
          messageType: messageType,
          subMessageType: subMessageType,
          transportType: transportType.value,
          deleteTime: _deleteTime.value,
          parentMessageId: _parentMessageId.value);

      List<ChatMessage> returnChatMessages =
          await chatMessageService.sendAndStore(chatMessage, peerIds: peerIds);
      latest();
      returnChatMessage = returnChatMessages.firstOrNull;
    } else {
      ChatMessage chatMessage = await chatMessageService.buildGroupChatMessage(
          peerId, type,
          title: title,
          content: content,
          contentType: contentType,
          mimeType: mimeType,
          messageId: messageId,
          messageType: messageType,
          subMessageType: subMessageType,
          transportType: transportType.value,
          deleteTime: _deleteTime.value,
          parentMessageId: _parentMessageId.value);
      List<ChatMessage> returnChatMessages =
          await chatMessageService.sendAndStore(chatMessage,
              cryptoOption: CryptoOption.group, peerIds: peerIds);
      latest();
      returnChatMessage = returnChatMessages.firstOrNull;
    }
    _deleteTime(0);
    _parentMessageId(null);
    transportType(TransportType.webrtc);

    return returnChatMessage;
  }

  Future<void> sendNameCard(List<String> peerIds) async {
    List<PeerParty> peers = [];
    String mimeType = PartyType.linkman.name;
    for (String peerId in peerIds) {
      Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
      if (linkman != null) {
        peers.add(linkman);
      } else {
        Group? group = await groupService.findCachedOneByPeerId(peerId);
        if (group != null) {
          peers.add(group);
          mimeType = PartyType.group.name;
        }
      }
    }
    await send(
        content: peers,
        contentType: ChatMessageContentType.card,
        mimeType: mimeType);
  }
}

///好友或者群的消息控制器，包含某个连接的所有消息
final ChatMessageController chatMessageController = ChatMessageController();
