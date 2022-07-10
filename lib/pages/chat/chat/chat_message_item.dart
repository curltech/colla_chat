import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:flutter/material.dart';

import '../../../entity/chat/chat.dart';

/// 每条消息展示组件，我接收的消息展示在左边，我发送的消息展示在右边
class ChatMessageItem extends StatelessWidget {
  final ChatMessage chatMessage;

  const ChatMessageItem({Key? key, required this.chatMessage})
      : super(key: key);

  Widget _buildOther(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                  margin: const EdgeInsets.only(right: 16.0),
                  child: defaultImage),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('${chatMessage.id}'),
                    Container(
                      margin: const EdgeInsets.only(top: 5.0),
                      child: Text(chatMessage.content),
                    )
                  ]),
            ]));
  }

  Widget _buildMe(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
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
                    Container(
                      margin: const EdgeInsets.only(top: 5.0),
                      child: Text(chatMessage.content),
                    )
                  ]),
              Container(
                  margin: const EdgeInsets.only(left: 16.0),
                  child: myself.avatarImage)
            ]));
  }

  bool _isMeSent() {
    var direct = chatMessage.direct;
    var senderPeerId = chatMessage.senderPeerId;
    var peerId = myself.peerId;
    if (direct == ChatDirect.send.name &&
        (senderPeerId == null || senderPeerId == peerId)) {
      return true;
    }
    return false;
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
    bool isMe = _isMeSent();
    if (isMe) {
      return _buildMe(context);
    }
    return _buildOther(context);
  }
}
