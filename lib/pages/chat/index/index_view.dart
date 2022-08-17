import 'package:colla_chat/pages/chat/chat/video_dialin_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../entity/chat/chat.dart';
import '../../../provider/app_data_provider.dart';
import '../../../widgets/style/platform_widget_factory.dart';
import '../login/loading.dart';
import 'bottom_bar.dart';
import 'index_widget.dart';

///影响全局的消息到来
class GlobalChatMessageController with ChangeNotifier {
  ChatMessage? _chatMessage;

  ChatMessage? get chatMessage {
    return _chatMessage;
  }

  set chatMessage(ChatMessage? chatMessage) {
    _chatMessage = chatMessage;
    notifyListeners();
  }
}

final GlobalChatMessageController globalChatMessageController =
    GlobalChatMessageController();

class IndexView extends StatefulWidget {
  final String title;

  const IndexView({Key? key, required this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _IndexViewState();
  }
}

class _IndexViewState extends State<IndexView>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    globalChatMessageController.addListener(_update);
  }

  _update() async {
    ChatMessage? chatMessage = globalChatMessageController.chatMessage;
    if (chatMessage != null) {
      //视频通话请求消息
      if (chatMessage.subMessageType == ChatSubMessageType.videoChat.name) {
        ChatReceiptType? chatReceiptType =
            await showModalBottomSheet<ChatReceiptType>(
                context: context, builder: _buildVideoDialIn);
        if (chatReceiptType == ChatReceiptType.agree) {
        } else if (chatReceiptType == ChatReceiptType.reject) {}
      }
    }
  }

  Widget _buildVideoDialIn(BuildContext context) {
    ChatMessage? chatMessage = globalChatMessageController.chatMessage;
    if (chatMessage != null) {
      globalChatMessageController.chatMessage;
      return VideoDialInWidget(chatMessage: chatMessage);
    }
    return Container();
  }

  Widget _createScaffold(
      BuildContext context, IndexWidgetProvider indexWidgetProvider) {
    var indexWidget = IndexWidget();
    var bottomNavigationBar = Offstage(
        offstage: !indexWidgetProvider.bottomBarVisible,
        child: const BottomBar());
    Scaffold scaffold = Scaffold(
        appBar: AppBar(toolbarHeight: 0.0, elevation: 0.0),
        body: SafeArea(
            child: Stack(children: <Widget>[
          Opacity(
            opacity: 1,
            child: loadingWidget,
          ),
          Center(
              child: platformWidgetFactory.buildSizedBox(
                  child: indexWidget,
                  height: appDataProvider.mobileSize.height,
                  width: appDataProvider.mobileSize.width))
        ])),
        //endDrawer: endDrawer,
        bottomNavigationBar: bottomNavigationBar);

    return scaffold;
  }

  @override
  Widget build(BuildContext context) {
    appDataProvider.changeSize(context);
    var provider = Consumer<IndexWidgetProvider>(
      builder: (context, indexWidgetProvider, child) =>
          _createScaffold(context, indexWidgetProvider),
    );
    return provider;
  }

  @override
  void dispose() {
    globalChatMessageController.removeListener(_update);
    super.dispose();
  }
}
