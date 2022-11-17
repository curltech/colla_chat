import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FullScreenWidget extends StatefulWidget {
  const FullScreenWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _FullScreenWidgetState();
  }
}

class _FullScreenWidgetState extends State<FullScreenWidget> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    chatMessageController.addListener(_update);
    _pageController = PageController(
      initialPage: 0,
    );
  }

  _update() {
    setState(() {});
  }

  Widget _buildFullScreenWidget(BuildContext context, Widget child) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (int index) {},
      itemBuilder: (BuildContext ctx, int index) {
        return Center(
            child: Container(
          color: Colors.black,
          child: child,
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ChatMessage? chatMessage = chatMessageController.current;
    return _buildFullScreenWidget(context, Container());
  }

  @override
  void dispose() {
    chatMessageController.removeListener(_update);
    super.dispose();
  }
}
