import 'package:flutter/material.dart';

import '../../../entity/chat/chat.dart';
import '../../../provider/app_data_provider.dart';
import '../../../provider/data_list_controller.dart';
import '../../../widgets/common/widget_mixin.dart';
import 'chat_message_item.dart';

/// 消息发送和接受展示的界面组件
/// 此界面展示特定的目标对象的收到的消息，并且可以发送消息
class ChatMessageWidget extends StatefulWidget with TileDataMixin {
  final String subtitle;

  final DataListController<ChatMessage> controller =
      DataListController<ChatMessage>();

   ChatMessageWidget(
      {Key? key, required this.subtitle})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChatMessageWidgetState();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'chat_message';

  @override
  Icon get icon => const Icon(Icons.chat);

  @override
  String get title => 'ChatMessage';
}

class _ChatMessageWidgetState extends State<ChatMessageWidget>
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
    List<ChatMessage> messages = widget.controller.data;
    ChatMessage item = messages[index];
    // 创建消息动画控制器
    var animate =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    Widget chatMessageWidget = ChatMessageItem(chatMessage: item);

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
      Flexible(
        //使用列表渲染消息
        child: ListView.builder(
          padding: const EdgeInsets.all(8.0),
          reverse: true,
          //消息组件渲染
          itemBuilder: messageItem,
          //消息条目数
          itemCount: widget.controller.data.length,
        ),
      ),
      const Divider(
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
