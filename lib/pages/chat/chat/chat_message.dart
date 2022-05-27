import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/pages/chat/chat/chat_me_message.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app.dart';
import '../websocket_provider.dart';

/// 消息发送和接受展示的界面组件
/// 此界面展示特定的目标对象的收到的消息，并且可以发送消息
class ChatMessage extends StatefulWidget {
  final String title;

  const ChatMessage({Key? key, required this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChatMessageState();
  }
}

class _ChatMessageState extends State<ChatMessage>
    with TickerProviderStateMixin {
  final TextEditingController textEditingController = TextEditingController();
  FocusNode textFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void handleSubmit(String message) {
    textEditingController.clear();
    if (message.isEmpty || message == '') {
      return;
    }
    logger.i(message);
  }

  Widget textComposerWidget() {
    return IconTheme(
        data: IconThemeData(color: Colors.lightBlue),
        child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(children: <Widget>[
              Flexible(
                child: TextField(
                  decoration: InputDecoration.collapsed(hintText: '请输入消息'),
                  controller: textEditingController,
                  onSubmitted: handleSubmit,
                  focusNode: textFocusNode,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 8.0),
                child: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    handleSubmit(textEditingController.text);
                  },
                ),
              )
            ])));
  }

  Widget messageItem(BuildContext context, int index) {
    // 通过websocket获取消息
    List<ChatMessageData> messages =
        Provider.of<WebsocketProvider>(context).messages;
    ChatMessageData item = messages[index];
    // 创建消息动画控制器
    var animate =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    // 创建消息组件
    ChatMeMessage message = ChatMeMessage(message: item);
    // 读取自己的用户id，判断是否是发送给自己的
    var myselfPeer = myself.myselfPeer;
    if (myselfPeer != null) {
      String peerId = myselfPeer.peerId;
      if (peerId == item.peerId) {
        item.isMe = true;
      } else {
        item.isMe = false;
      }
    }
    // index=0执行动画，对最新的消息执行动画
    if (index == 0) {
      // 开始动画
      animate.forward();
      // 大小变化动画组件
      return SizeTransition(
        // 指定非线性动画类型
        sizeFactor: CurvedAnimation(parent: animate, curve: Curves.easeInOut),
        axisAlignment: 0.0,
        // 指定为当前消息组件
        child: message,
      );
    }
    // 不添加动画消息组件
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      //使用Consumer来获取WebSocketProvider对象
      Consumer<WebsocketProvider>(builder: (BuildContext context,
          WebsocketProvider websocketProvider, Widget? child) {
        //获取消息列表数据
        var messages = websocketProvider.messages;
        return Flexible(
          //使用列表渲染消息
          child: ListView.builder(
            padding: EdgeInsets.all(8.0),
            reverse: true,
            //消息组件渲染
            itemBuilder: messageItem,
            //消息条目数
            itemCount: messages.length,
          ),
        );
      }),
      Divider(
        height: 1.0,
      ),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
        ),
        child: textComposerWidget(),
      )
    ]);
  }
}
