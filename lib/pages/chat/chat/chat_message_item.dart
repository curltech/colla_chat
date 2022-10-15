import 'package:bubble/bubble.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/pages/chat/chat/message/audio_message.dart';
import 'package:colla_chat/pages/chat/chat/message/file_message.dart';
import 'package:colla_chat/pages/chat/chat/message/image_message.dart';
import 'package:colla_chat/pages/chat/chat/message/name_card_message.dart';
import 'package:colla_chat/pages/chat/chat/message/rich_text_message.dart';
import 'package:colla_chat/pages/chat/chat/message/url_message.dart';
import 'package:colla_chat/pages/chat/chat/message/video_message.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:flutter/material.dart';

import 'message/action_message.dart';
import 'message/extended_text_message.dart';

/// 每条消息展示组件，我接收的消息展示在左边，我发送的消息展示在右边
class ChatMessageItem extends StatelessWidget {
  final ChatMessage chatMessage;
  late final bool isMyself;

  ChatMessageItem({Key? key, required this.chatMessage}) : super(key: key) {
    isMyself = _isMyself();
  }

  bool _isMyself() {
    var direct = chatMessage.direct;
    var senderPeerId = chatMessage.senderPeerId;
    var peerId = myself.peerId;
    if (direct == ChatDirect.send.name &&
        (senderPeerId == null || senderPeerId == peerId)) {
      return true;
    }
    return false;
  }

  ///消息体：扩展文本，图像，声音，视频，页面，复合文本，文件，名片，位置，收藏等种类
  ///每种消息体一个类
  Widget? _buildMessageBody(BuildContext context) {
    ContentType? contentType;
    if (chatMessage.contentType != null) {
      contentType = StringUtil.enumFromString(
          ContentType.values, chatMessage.contentType!);
    }
    contentType = contentType ?? ContentType.text;
    ChatSubMessageType? subMessageType;
    if (chatMessage.subMessageType != null) {
      subMessageType = StringUtil.enumFromString(
          ChatSubMessageType.values, chatMessage.subMessageType!);
    }
    subMessageType = subMessageType ?? ChatSubMessageType.chat;
    if (subMessageType == ChatSubMessageType.chat) {
      switch (contentType) {
        case ContentType.text:
          return _buildExtendedTextMessageWidget(context);
        case ContentType.audio:
          return _buildAudioMessageWidget(context);
        case ContentType.video:
          return _buildVideoMessageWidget(context);
        case ContentType.file:
          return _buildFileMessageWidget(context);
        case ContentType.image:
          return _buildImageMessageWidget(context);
        case ContentType.card:
          return _buildNameCardMessageWidget(context);
        case ContentType.rich:
          return _buildRichTextMessageWidget(context);
        case ContentType.link:
          return _buildUrlMessageWidget(context);
        default:
          break;
      }
    } else if (subMessageType == ChatSubMessageType.videoChat) {
      return _buildActionMessageWidget(context, subMessageType);
    }
    return null;
  }

  ExtendedTextMessage _buildExtendedTextMessageWidget(BuildContext context) {
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

  ActionMessage _buildActionMessageWidget(
      BuildContext context, ChatSubMessageType subMessageType) {
    return ActionMessage(
      isMyself: isMyself,
      subMessageType: subMessageType,
    );
  }

  UrlMessage _buildUrlMessageWidget(BuildContext context) {
    String? title = chatMessage.title;
    return UrlMessage(
      url: title!,
      isMyself: isMyself,
    );
  }

  RichTextMessage _buildRichTextMessageWidget(BuildContext context) {
    String? messageId = chatMessage.messageId;
    return RichTextMessage(
      messageId: messageId!,
      isMyself: isMyself,
    );
  }

  NameCardMessage _buildNameCardMessageWidget(BuildContext context) {
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

  ImageMessage _buildImageMessageWidget(BuildContext context) {
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

  VideoMessage _buildVideoMessageWidget(BuildContext context) {
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

  AudioMessage _buildAudioMessageWidget(BuildContext context) {
    int? id = chatMessage.id;
    String? messageId = chatMessage.messageId;
    return AudioMessage(
      id: id!,
      messageId: messageId!,
      isMyself: isMyself,
    );
  }

  StatelessWidget _buildFileMessageWidget(BuildContext context) {
    String? messageId = chatMessage.messageId;
    String? title = chatMessage.title;
    String? mimeType = chatMessage.mimeType;
    mimeType = mimeType ?? 'text/plain';
    if (mimeType.startsWith('image')) {
      return _buildImageMessageWidget(context);
    } else if (mimeType.startsWith('audio')) {
      return _buildAudioMessageWidget(context);
    } else if (mimeType.startsWith('video')) {
      return _buildVideoMessageWidget(context);
    }
    return FileMessage(
      messageId: messageId!,
      isMyself: isMyself,
      title: title!,
      mimeType: mimeType,
    );
  }

  ///气泡消息容器，内包消息体
  Widget _buildMessageBubble(BuildContext context) {
    return Container(
        constraints: const BoxConstraints(minWidth: 0, maxWidth: 300),
        child: Bubble(
          elevation: 0.0,
          stick: true,
          margin: const BubbleEdges.only(top: 1),
          nip: isMyself ? BubbleNip.rightTop : BubbleNip.leftTop,
          color: isMyself
              ? appDataProvider.themeData.colorScheme.primary
              : Colors.white,
          child: _buildMessageBody(context),
        ));
  }

  ///矩形消息容器，内包消息体
  Widget _buildMessageContainer(BuildContext context) {
    double lrEdgeInsets = 15.0;
    double tbEdgeInsets = 10.0;

    return Row(
      mainAxisAlignment:
          isMyself ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(
              lrEdgeInsets, tbEdgeInsets, lrEdgeInsets, tbEdgeInsets),
          constraints: const BoxConstraints(maxWidth: 300.0),
          decoration: BoxDecoration(
            color: isMyself
                ? appDataProvider.themeData.colorScheme.primary
                : Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: const Radius.circular(8.0),
              bottomRight: const Radius.circular(8.0),
              topLeft: isMyself ? const Radius.circular(8.0) : Radius.zero,
              topRight: isMyself ? Radius.zero : const Radius.circular(8.0),
            ),
            //border: Border.all(color: Colors.white, width: 0.0),
          ),
          margin: EdgeInsets.only(
              right: isMyself ? 5.0 : 0, left: isMyself ? 0 : 5.0),
          child: _buildMessageBody(context),
        )
      ], // aligns the chatitem to right end
    );
  }

  ///其他人的消息，从左到右，头像，时间，名称，消息容器
  Widget _buildOther(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                  margin: const EdgeInsets.only(right: 0.0),
                  child: defaultImage),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('${chatMessage.id}:${chatMessage.senderName}'),
                    _buildMessageBubble(context)
                  ]),
            ]));
  }

  ///我的消息，从右到左，头像，时间，名称，消息容器
  Widget _buildMe(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Container(),
              ),
              Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text('${chatMessage.id}:${chatMessage.receiverName}'),
                    _buildMessageBubble(context)
                  ]),
              Container(
                  margin: const EdgeInsets.only(left: 0.0),
                  child: myself.avatarImage)
            ]));
  }

  Future<Widget?> _getImageWidget() async {
    var direct = chatMessage.direct;
    var senderPeerId = chatMessage.senderPeerId;
    var peerId = myself.peerId;
    if (direct == ChatDirect.send.name &&
        (senderPeerId == null || senderPeerId == peerId)) {
      return myself.avatarImage;
    }
    if (senderPeerId != null) {
      var linkman = await linkmanService.findCachedOneByPeerId(senderPeerId);
      if (linkman != null) {
        return linkman.avatarImage;
      }
    }

    return defaultImage;
  }

  @override
  Widget build(BuildContext context) {
    bool isMe = _isMyself();
    if (isMe) {
      return _buildMe(context);
    }
    return _buildOther(context);
  }
}
