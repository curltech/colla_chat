import 'package:bubble/bubble.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/pages/chat/chat/message/audio_message.dart';
import 'package:colla_chat/pages/chat/chat/message/file_message.dart';
import 'package:colla_chat/pages/chat/chat/message/image_message.dart';
import 'package:colla_chat/pages/chat/chat/message/name_card_message.dart';
import 'package:colla_chat/pages/chat/chat/message/rich_text_message.dart';
import 'package:colla_chat/pages/chat/chat/message/url_message.dart';
import 'package:colla_chat/pages/chat/chat/message/video_message.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:flutter/material.dart';

import '../../../entity/chat/chat.dart';
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
    String? title = chatMessage.title;
    String? content = chatMessage.content;
    List<int>? data;
    if (content != null) {
      data = CryptoUtil.decodeBase64(content);
      logger.i('chatMessage content data length: ${data.length}');
    }

    if (subMessageType == ChatSubMessageType.chat) {
      if (contentType == ContentType.text) {
        if (data != null) {
          content = CryptoUtil.utf8ToString(data);
        } else {
          content = '';
        }
        return ExtendedTextMessage(
          isMyself: isMyself,
          content: content,
        );
      }
      if (contentType == ContentType.audio) {
        return AudioMessage(
          data: data!,
          isMyself: isMyself,
        );
      }
      if (contentType == ContentType.video) {
        String? thumbnail = chatMessage.thumbnail;
        return VideoMessage(
          data: data!,
          isMyself: isMyself,
          thumbnail: thumbnail,
        );
      }
      if (contentType == ContentType.file) {
        String title = chatMessage.title!;
        String mimeType = chatMessage.mimeType!;
        return FileMessage(
          data: data!,
          isMyself: isMyself,
          title: title!,
          mimeType: mimeType,
        );
      }
      if (contentType == ContentType.image) {
        String title = chatMessage.title!;
        String mimeType = chatMessage.mimeType!;
        return ImageMessage(
          image: content!,
          isMyself: isMyself,
          mimeType: mimeType,
        );
      }
      if (contentType == ContentType.card) {
        return NameCardMessage(
          content: content!,
          isMyself: isMyself,
        );
      }
      if (contentType == ContentType.rich) {
        return RichTextMessage(
          content: content!,
          isMyself: isMyself,
        );
      }
      if (contentType == ContentType.link) {
        return UrlMessage(
          url: title!,
          isMyself: isMyself,
        );
      }
    }
    if (subMessageType == ChatSubMessageType.videoChat) {
      return ActionMessage(
        isMyself: isMyself,
        subMessageType: subMessageType,
      );
    }
    return null;
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
