import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/message/message_widget.dart';
import 'package:flutter/material.dart';

class FullScreenWidget extends StatefulWidget {
  const FullScreenWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _FullScreenWidgetState();
  }
}

class _FullScreenWidgetState extends State<FullScreenWidget> {
  PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    chatMessageController.addListener(_update);
  }

  _update() {
    setState(() {
      pageController.jumpToPage(chatMessageController.currentIndex);
    });
  }

  Widget _buildMessageWidget(BuildContext context, int index) {
    ChatMessage chatMessage = chatMessageController.data[index];
    Widget? child;
    MessageWidget messageWidget = MessageWidget(chatMessage, index);
    child = messageWidget.buildMessageBody(context);
    child = child ?? Container();

    return child;
  }

  Widget _buildFullScreenWidget(BuildContext context) {
    return GestureDetector(
        onTap: () {
          chatMessageController.chatView = ChatView.text;
        },
        child: PageView.builder(
          itemBuilder: (BuildContext context, int index) {
            return Center(
                child: Container(
              //color: Colors.black,
              child: _buildMessageWidget(context, index),
            ));
          },
          itemCount: chatMessageController.length,
          controller: pageController,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return _buildFullScreenWidget(context);
  }

  @override
  void dispose() {
    chatMessageController.removeListener(_update);
    super.dispose();
  }
}
