import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/dht/myself.dart';
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
  Widget? buildMessageBody(BuildContext context,
      {String? content,
      ContentType contentType = ContentType.text,
      ChatSubMessageType subMessageType = ChatSubMessageType.chat}) {
    if (subMessageType == ChatSubMessageType.chat) {
      if (contentType == ContentType.text) {
        return ExtendedTextMessage(
          isMyself: isMyself,
          content: content ?? '',
        );
      }
    }
    if (subMessageType == ChatSubMessageType.videoChat) {
      Color color = appDataProvider.themeData!.colorScheme.primary;

      return ActionMessage(
        isMyself: isMyself,
        content: content ?? '视频通话邀请',
        icon: Icon(
          Icons.video_call,
          color: isMyself ? Colors.white : color,
        ),
      );
    }
    return null;
  }

  ///消息容器，内包消息体
  Row buildMessageContainer(BuildContext context,
      {String? content,
      ContentType contentType = ContentType.text,
      ChatSubMessageType subMessageType = ChatSubMessageType.chat}) {
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
                ? appDataProvider.themeData!.colorScheme.primary
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
          child: buildMessageBody(context,
              content: content,
              contentType: contentType,
              subMessageType: subMessageType),
        )
      ], // aligns the chatitem to right end
    );
  }

  ///其他人的消息，从左到右，头像，时间，名称，消息容器
  Widget _buildOther(BuildContext context) {
    String? content = chatMessage.content;
    if (content != null) {
      var raw = CryptoUtil.decodeBase64(content);
      content = CryptoUtil.utf8ToString(raw);
    }
    ContentType contentType = ContentType.text;
    if (chatMessage.contentType != null) {
      contentType = StringUtil.enumFromString(
          ContentType.values, chatMessage.contentType!);
    }
    ChatSubMessageType subMessageType = ChatSubMessageType.chat;
    if (chatMessage.subMessageType != null) {
      subMessageType = StringUtil.enumFromString(
          ChatSubMessageType.values, chatMessage.subMessageType!);
    }
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
                    Text('${chatMessage.id}'),
                    buildMessageContainer(context,
                        content: content,
                        contentType: contentType,
                        subMessageType: subMessageType)
                  ]),
            ]));
  }

  ///我的消息，从右到左，头像，时间，名称，消息容器
  Widget _buildMe(BuildContext context) {
    String? content = chatMessage.content;
    if (content != null) {
      var raw = CryptoUtil.decodeBase64(content);
      content = CryptoUtil.utf8ToString(raw);
    }
    ContentType contentType = ContentType.text;
    if (chatMessage.contentType != null) {
      contentType = StringUtil.enumFromString(
          ContentType.values, chatMessage.contentType!);
    }
    ChatSubMessageType subMessageType = ChatSubMessageType.chat;
    if (chatMessage.subMessageType != null) {
      subMessageType = StringUtil.enumFromString(
          ChatSubMessageType.values, chatMessage.subMessageType!);
    }
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Container(),
              ),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('${chatMessage.id}'),
                    buildMessageContainer(context,
                        content: content,
                        contentType: contentType,
                        subMessageType: subMessageType)
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
