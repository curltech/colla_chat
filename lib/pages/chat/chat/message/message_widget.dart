import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/pages/chat/chat/message/action_message.dart';
import 'package:colla_chat/pages/chat/chat/message/audio_message.dart';
import 'package:colla_chat/pages/chat/chat/message/extended_text_message.dart';
import 'package:colla_chat/pages/chat/chat/message/file_message.dart';
import 'package:colla_chat/pages/chat/chat/message/image_message.dart';
import 'package:colla_chat/pages/chat/chat/message/name_card_message.dart';
import 'package:colla_chat/pages/chat/chat/message/rich_text_message.dart';
import 'package:colla_chat/pages/chat/chat/message/url_message.dart';
import 'package:colla_chat/pages/chat/chat/message/video_message.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:flutter/material.dart';

class MessageWidget {
  final ChatMessage chatMessage;
  bool? _isMyself;

  MessageWidget(this.chatMessage);

  bool get isMyself {
    if (_isMyself != null) {
      return _isMyself!;
    }
    var direct = chatMessage.direct;
    var senderPeerId = chatMessage.senderPeerId;
    var peerId = myself.peerId;
    if (direct == ChatDirect.send.name &&
        (senderPeerId == null || senderPeerId == peerId)) {
      _isMyself = true;
    } else {
      _isMyself = false;
    }
    return _isMyself!;
  }

  ///消息体：扩展文本，图像，声音，视频，页面，复合文本，文件，名片，位置，收藏等种类
  ///每种消息体一个类
  Widget? buildMessageBody(BuildContext context) {
    ContentType? contentType;
    if (chatMessage.contentType != null) {
      contentType = StringUtil.enumFromString(
          ContentType.values, chatMessage.contentType!);
    }
    contentType = contentType ?? ContentType.text;
    ChatSubMessageType? subMessageType;
    subMessageType = StringUtil.enumFromString(
        ChatSubMessageType.values, chatMessage.subMessageType!);
    if (subMessageType == ChatSubMessageType.chat) {
      switch (contentType) {
        case ContentType.text:
          return buildExtendedTextMessageWidget(context);
        case ContentType.audio:
          return buildAudioMessageWidget(context);
        case ContentType.video:
          return buildVideoMessageWidget(context);
        case ContentType.file:
          return buildFileMessageWidget(context);
        case ContentType.image:
          return buildImageMessageWidget(context);
        case ContentType.card:
          return buildNameCardMessageWidget(context);
        case ContentType.rich:
          return buildRichTextMessageWidget(context);
        case ContentType.link:
          return buildUrlMessageWidget(context);
        default:
          break;
      }
    } else if (subMessageType == ChatSubMessageType.videoChat) {
      return buildActionMessageWidget(context, subMessageType!);
    } else if (subMessageType == ChatSubMessageType.addFriend) {
      return buildActionMessageWidget(context, subMessageType!);
    }
    return null;
  }

  ExtendedTextMessage buildExtendedTextMessageWidget(BuildContext context) {
    String? content = chatMessage.content;
    List<int>? data;
    if (content != null) {
      data = CryptoUtil.decodeBase64(content);
      content = CryptoUtil.utf8ToString(data);
    }
    return ExtendedTextMessage(
      isMyself: isMyself,
      content: content!,
    );
  }

  ActionMessage buildActionMessageWidget(
      BuildContext context, ChatSubMessageType subMessageType) {
    return ActionMessage(
      isMyself: isMyself,
      subMessageType: subMessageType,
    );
  }

  UrlMessage buildUrlMessageWidget(BuildContext context) {
    String? title = chatMessage.title;
    return UrlMessage(
      url: title!,
      isMyself: isMyself,
    );
  }

  RichTextMessage buildRichTextMessageWidget(BuildContext context) {
    String? messageId = chatMessage.messageId;
    return RichTextMessage(
      messageId: messageId!,
      isMyself: isMyself,
    );
  }

  NameCardMessage buildNameCardMessageWidget(BuildContext context) {
    String? content = chatMessage.content;
    List<int>? data;
    if (content != null) {
      data = CryptoUtil.decodeBase64(content);
      content = CryptoUtil.utf8ToString(data);
    }
    return NameCardMessage(
      content: content!,
      isMyself: isMyself,
    );
  }

  ImageMessage buildImageMessageWidget(BuildContext context) {
    String? messageId = chatMessage.messageId;
    String? thumbnail = chatMessage.thumbnail;
    String mimeType = chatMessage.mimeType!;
    return ImageMessage(
      messageId: messageId!,
      image: thumbnail,
      isMyself: isMyself,
      mimeType: mimeType,
    );
  }

  VideoMessage buildVideoMessageWidget(BuildContext context) {
    int? id = chatMessage.id;
    String? messageId = chatMessage.messageId;
    String? thumbnail = chatMessage.thumbnail;
    return VideoMessage(
      id: id!,
      messageId: messageId!,
      isMyself: isMyself,
      thumbnail: thumbnail,
    );
  }

  AudioMessage buildAudioMessageWidget(BuildContext context) {
    int? id = chatMessage.id;
    String? messageId = chatMessage.messageId;
    return AudioMessage(
      id: id!,
      messageId: messageId!,
      isMyself: isMyself,
    );
  }

  Widget buildFileMessageWidget(BuildContext context) {
    String? messageId = chatMessage.messageId;
    String? title = chatMessage.title;
    String? mimeType = chatMessage.mimeType;
    mimeType = mimeType ?? 'text/plain';
    if (mimeType.startsWith('image')) {
      return buildImageMessageWidget(context);
    } else if (mimeType.startsWith('audio')) {
      return buildAudioMessageWidget(context);
    } else if (mimeType.startsWith('video')) {
      return buildVideoMessageWidget(context);
    }
    return FileMessage(
      messageId: messageId!,
      isMyself: isMyself,
      title: title!,
      mimeType: mimeType,
    );
  }
}
