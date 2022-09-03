import 'package:colla_chat/pages/chat/chat/video_dialin_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../crypto/util.dart';
import '../../../entity/chat/chat.dart';
import '../../../plugin/logger.dart';
import '../../../provider/app_data_provider.dart';
import '../../../widgets/common/image_widget.dart';
import '../../../widgets/style/platform_widget_factory.dart';
import '../login/loading.dart';
import 'bottom_bar.dart';
import 'global_chat_message_controller.dart';
import 'index_widget.dart';

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
  OverlayEntry? videoChatOverlayEntry;
  OverlayEntry? chatMessageOverlayEntry;

  @override
  void initState() {
    super.initState();
    globalChatMessageController.addListener(_update);
  }

  _closeVideoChatOverlayEntry() {
    if (videoChatOverlayEntry != null) {
      videoChatOverlayEntry!.remove();
      videoChatOverlayEntry = null;
    }
  }

  _showVideoChatMessage(BuildContext context, ChatMessage chatMessage) {
    videoChatOverlayEntry = OverlayEntry(
        maintainState: true,
        builder: (context) {
          return Align(
            alignment: Alignment.topLeft,
            child: _buildVideoDialIn(context, chatMessage),
          );
        });
    Overlay.of(context)!.insert(videoChatOverlayEntry!);
  }

  _closeChatMessageOverlayEntry() {
    if (chatMessageOverlayEntry != null) {
      chatMessageOverlayEntry!.remove();
      chatMessageOverlayEntry = null;
    }
  }

  _showChatMessage(BuildContext context, ChatMessage chatMessage) {
    String? content = chatMessage.content;
    if (content != null) {
      var raw = CryptoUtil.decodeBase64(content);
      content = CryptoUtil.utf8ToString(raw);
    } else {
      content = '';
    }
    String? title = chatMessage.title;
    if (title != null) {
      var raw = CryptoUtil.decodeBase64(title);
      title = CryptoUtil.utf8ToString(raw);
    } else {
      title = '';
    }
    chatMessageOverlayEntry = OverlayEntry(
        maintainState: true,
        builder: (context) {
          var name = chatMessage.senderName;
          name = name ?? '';
          return Align(
              alignment: Alignment.topLeft,
              child: Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: Colors.black.withAlpha(128),
                  child: ListTile(
                    leading: const ImageWidget(image: ''),
                    title:
                        Text(name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(title!,
                        style: const TextStyle(color: Colors.white)),
                    trailing: Text(content!,
                        style: const TextStyle(color: Colors.white)),
                  )));
        });
    Overlay.of(context)!.insert(chatMessageOverlayEntry!);
    //延时，移除 OverlayEntry
    Future.delayed(const Duration(seconds: 10)).then((value) {
      _closeChatMessageOverlayEntry();
    });
  }

  _update() async {
    ChatMessage? chatMessage = globalChatMessageController.chatMessage;
    if (chatMessage != null) {
      //视频通话请求消息
      if (chatMessage.subMessageType == ChatSubMessageType.videoChat.name) {
        _showVideoChatMessage(context, chatMessage);
      } else if (chatMessage.subMessageType ==
          ChatSubMessageType.audioChat.name) {
        _showVideoChatMessage(context, chatMessage);
      } else {
        //_showChatMessage(context, chatMessage);
      }
    }
  }

  _onTap(ChatMessage chatMessage, ChatReceiptType chatReceiptType) {
    _closeVideoChatOverlayEntry();
    if (chatReceiptType == ChatReceiptType.agree) {
      //同意，发出本地流
      logger.i('ChatReceiptType agree');
    } else if (chatReceiptType == ChatReceiptType.reject) {
      //拒绝，关闭对话框
      logger.i('ChatReceiptType reject');
    }
  }

  Widget _buildVideoDialIn(BuildContext context, ChatMessage chatMessage) {
    return VideoDialInWidget(
      chatMessage: chatMessage,
      onTap: _onTap,
    );
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
