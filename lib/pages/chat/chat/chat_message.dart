import 'package:colla_chat/entity/dht/myself.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../entity/chat/chat.dart';
import '../../../provider/app_data_provider.dart';
import '../../../provider/chat_message_provider.dart';
import 'chat_me_message.dart';
import 'chat_other_message.dart';

/// 消息发送和接受展示的界面组件
/// 此界面展示特定的目标对象的收到的消息，并且可以发送消息
class ChatMessagePage extends StatefulWidget {
  final String title;

  const ChatMessagePage({Key? key, required this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChatMessagePageState();
  }
}

class _ChatMessagePageState extends State<ChatMessagePage>
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
    List<ChatMessage> messages =
        Provider.of<ChatMessageProvider>(context).chatMessages;
    ChatMessage item = messages[index];
    // 创建消息动画控制器
    var animate =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    Widget chatMessageWidget = ChatOtherMessage(message: item);
    // 读取自己的用户id，判断是否是发送给自己的
    var myselfPeer = myself.myselfPeer;
    if (myselfPeer != null) {
      String? peerId = myselfPeer.peerId;
      if (peerId == item.targetPeerId) {
        // 创建消息组件
        chatMessageWidget = ChatMeMessage(message: item);
      } else {
        // 创建消息组件
        chatMessageWidget = ChatOtherMessage(message: item);
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
        child: chatMessageWidget,
      );
    }
    // 不添加动画消息组件
    return chatMessageWidget;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      //使用Consumer来获取WebSocketProvider对象
      Consumer<ChatMessageProvider>(builder: (BuildContext context,
          ChatMessageProvider chatMessageDataProvider, Widget? child) {
        //获取消息列表数据
        var messages = chatMessageDataProvider.chatMessages;
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
