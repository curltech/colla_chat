import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/pages/chat/chat/widget/msg_avatar.dart';
import 'package:colla_chat/pages/chat/chat/widget/text_item_container.dart';
import 'package:colla_chat/provider/chat_message_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

///文本消息显示组件，由一个头像和一个文本组件组成，头像根据是否是自己发出的消息显示在文本的左边或者右边
class TextMsg extends StatelessWidget {
  final String text;
  final ChatMessage chatMessage;

  TextMsg(this.text, this.chatMessage);

  @override
  Widget build(BuildContext context) {
    final chatMessageDataProvider =
        Provider.of<ChatMessageDataProvider>(context);
    var body = <Widget>[
      new MsgAvatar(model: chatMessage),
      new TextItemContainer(
        text: text ?? '文字为空',
        action: '',
        isMyself: chatMessage.targetPeerId != myself.peerId,
      ),
      new Spacer(),
    ];
    if (chatMessage.targetPeerId != myself.peerId) {
      body = body.reversed.toList();
    } else {
      body = body;
    }
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5.0),
      child: new Row(children: body),
    );
  }
}
