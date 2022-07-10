import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:flutter/material.dart';

import '../../../entity/chat/chat.dart';

/// 每条消息展示组件，我接收的消息展示在左边，我发送的消息展示在右边
class ChatMessageItem extends StatelessWidget {
  final ChatMessage chatMessage;
  late bool isMyself;

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

  Widget? buildMessageBody(
      BuildContext context, String content, ContentType contentType) {
    if (contentType == ContentType.text) {
      return Text(
        content,
        style: TextStyle(
          color: isMyself ? Colors.white : Colors.black,
          //fontSize: 16.0,
        ),
      );
    }
    return null;
  }

  Row buildMessageContainer(
      BuildContext context, String content, ContentType contentType) {
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
              border: Border.all(color: Colors.grey)),
          margin: EdgeInsets.only(
              right: isMyself ? 5.0 : 0, left: isMyself ? 0 : 5.0),
          child: buildMessageBody(context, content, contentType),
        )
      ], // aligns the chatitem to right end
    );
  }

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
                    Text('${chatMessage.id}'),
                    buildMessageContainer(
                        context, chatMessage.content, ContentType.text)
                  ]),
            ]));
  }

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('${chatMessage.id}'),
                    buildMessageContainer(
                        context, chatMessage.content, ContentType.text)
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
