import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:flutter/material.dart';

import '../../../entity/chat/chat.dart';
import '../../../l10n/localization.dart';
import '../../../provider/app_data_provider.dart';
import '../../../provider/data_list_controller.dart';
import '../../../widgets/common/widget_mixin.dart';
import 'chat_message_item.dart';

class ChatMessageController extends DataMoreController<ChatMessage> {
  ChatSummary? _chatSummary;

  ChatSummary? get chatSummary {
    return _chatSummary;
  }

  set chatSummary(ChatSummary? chatSummary) {
    _chatSummary = chatSummary;
    clear();
    more(defaultLimit);
  }

  @override
  void more(int index) {
    var chatSummary = _chatSummary;
    if (chatSummary == null) {
      clear();
      return;
    }
    if (chatSummary.peerId == null) {
      clear();
      return;
    }
    chatMessageService
        .findByPeerId(_chatSummary!.peerId!, offset: data.length, limit: index)
        .then((List<ChatMessage> chatMessages) {
      if (chatMessages.isNotEmpty) {
        addAll(chatMessages);
      }
    });
  }
}

/// 消息发送和接受展示的界面组件
/// 此界面展示特定的目标对象的收到的消息，并且可以发送消息
class ChatMessageWidget extends StatefulWidget with TileDataMixin {
  final ChatMessageController controller = ChatMessageController();

  ChatMessageWidget({Key? key}) : super(key: key);

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
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  ///发送命令
  void handleSubmit(String message) {
    textEditingController.clear();
    if (message.isEmpty || message == '') {
      return;
    }
    logger.i(message);
  }

  ///发送消息的输入框和按钮
  Widget textComposerWidget() {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(children: <Widget>[
          Flexible(
            child: TextFormField(
              decoration: const InputDecoration.collapsed(
                  hintText: 'Please input message'),
              controller: textEditingController,
              onFieldSubmitted: handleSubmit,
              focusNode: textFocusNode,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                handleSubmit(textEditingController.text);
              },
            ),
          )
        ]));
  }

  ///创建每一条消息
  Widget messageItem(BuildContext context, int index) {
    List<ChatMessage> messages = widget.controller.data;
    ChatMessage item = messages[index];
    // 创建消息动画控制器
    var animate =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    Widget chatMessageItem = ChatMessageItem(chatMessage: item);

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
        child: chatMessageItem,
      );
    }
    // 不添加动画消息组件
    return chatMessageItem;
  }

  ///创建消息显示面板，包含消息的输入框
  Widget _buildListView(BuildContext context) {
    ScrollController scrollController = ScrollController();
    return Column(children: <Widget>[
      Flexible(
        //使用列表渲染消息
        child: ListView.builder(
          controller: scrollController,
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
      textComposerWidget(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    var appBar = AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      centerTitle: true,
      title: Text(
        AppLocalizations.instance.text(widget.controller.chatSummary!.name!),
      ),
      actions: const [],
    );
    return Scaffold(appBar: appBar, body: _buildListView(context));
  }
}
