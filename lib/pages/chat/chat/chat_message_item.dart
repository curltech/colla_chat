import 'package:bubble/bubble.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/pages/chat/chat/message/message_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:flutter/material.dart';

/// 每条消息展示组件，我接收的消息展示在左边，我发送的消息展示在右边
class ChatMessageItem extends StatelessWidget {
  final ChatMessage chatMessage;
  final int index;

  late final bool isMyself;
  late final MessageWidget messageWidget;

  ChatMessageItem({Key? key, required this.chatMessage, required this.index})
      : super(key: key) {
    messageWidget = MessageWidget(chatMessage,index);
    isMyself = messageWidget.isMyself;
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
          child: messageWidget.buildMessageBody(context),
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
          child: messageWidget.buildMessageBody(context),
        )
      ], // aligns the chatitem to right end
    );
  }

  ///其他人的消息，从左到右，头像，时间，名称，消息容器
  Widget _buildOther(BuildContext context) {
    return FutureBuilder(
        future: _getImageWidget(context),
        builder: (BuildContext context, AsyncSnapshot<Widget?> image) {
          return Container(
              margin: const EdgeInsets.symmetric(vertical: 3.0),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                        margin: const EdgeInsets.only(right: 0.0),
                        child: image.data),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('${chatMessage.id}:${chatMessage.senderName}'),
                          _buildMessageBubble(context)
                        ]),
                  ]));
        });
  }

  ///我的消息，从右到左，头像，时间，名称，消息容器
  Widget _buildMe(BuildContext context) {
    return FutureBuilder(
        future: _getImageWidget(context),
        builder: (BuildContext context, AsyncSnapshot<Widget?> image) {
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
                        child: image.data)
                  ]));
        });
  }

  Future<Widget?> _getImageWidget(BuildContext context) async {
    var direct = chatMessage.direct;
    var senderPeerId = chatMessage.senderPeerId;
    var peerId = myself.peerId;
    if (direct == ChatDirect.send.name &&
        (senderPeerId == null || senderPeerId == peerId)) {
      return InkWell(
          onTap: () {
            indexWidgetProvider.push('personal_info');
          },
          child: myself.avatarImage);
    }
    if (senderPeerId != null) {
      var linkman = await linkmanService.findCachedOneByPeerId(senderPeerId);
      if (linkman != null) {
        return InkWell(
            onTap: () {
              linkmanController.replaceAll([linkman]);
              indexWidgetProvider.push('linkman_info');
            },
            child: linkman.avatarImage);
      }
    }

    return defaultImage;
  }

  @override
  Widget build(BuildContext context) {
    if (isMyself) {
      return _buildMe(context);
    }
    return _buildOther(context);
  }
}
