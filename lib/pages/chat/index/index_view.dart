import 'package:colla_chat/pages/chat/chat/video/video_dialin_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../crypto/util.dart';
import '../../../entity/chat/chat.dart';
import '../../../provider/app_data_provider.dart';
import '../../../widgets/common/image_widget.dart';
import '../../../widgets/special_text/custom_special_text_span_builder.dart';
import '../../../widgets/style/platform_widget_factory.dart';
import '../login/loading.dart';
import 'bottom_bar.dart';
import 'global_chat_message_controller.dart';
import 'index_widget.dart';

class IndexView extends StatefulWidget {
  final String title;
  final indexWidget = IndexWidget();

  IndexView({Key? key, required this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _IndexViewState();
  }
}

class _IndexViewState extends State<IndexView>
    with SingleTickerProviderStateMixin {
  bool videoChatVisible = false;
  bool chatMessageVisible = false;
  final CustomSpecialTextSpanBuilder customSpecialTextSpanBuilder =
      CustomSpecialTextSpanBuilder();

  @override
  void initState() {
    super.initState();
    globalChatMessageController.addListener(_update);
  }

  _buildVideoChatMessage(BuildContext context) {
    Widget videoDialIn = Container();
    if (videoChatVisible) {
      ChatMessage? chatMessage = globalChatMessageController.chatMessage;
      if (chatMessage != null) {
        //视频通话请求消息
        if (chatMessage.subMessageType == ChatSubMessageType.videoChat.name) {
          videoDialIn = _buildVideoDialIn(context, chatMessage);
        }
      }
      //延时，移除 OverlayEntry
      Future.delayed(const Duration(seconds: 20)).then((value) {
        setState(() {
          videoChatVisible = false;
        });
      });
    }
    return Visibility(visible: videoChatVisible, child: videoDialIn);
  }

  _buildChatMessage(BuildContext context) {
    Widget card = Container();
    if (chatMessageVisible) {
      ChatMessage? chatMessage = globalChatMessageController.chatMessage;
      if (chatMessage != null &&
          chatMessage.subMessageType == ChatSubMessageType.chat.name) {
        String? content = chatMessage.content;
        String? contentType = chatMessage.contentType;
        if (content != null) {
          var raw = CryptoUtil.decodeBase64(content);
          if (contentType == null || contentType == ContentType.text.name) {
            content = CryptoUtil.utf8ToString(raw);
          }
        } else {
          content = '';
        }
        String? title = chatMessage.title;
        var name = chatMessage.senderName;
        name = name ?? '';
        card = Container(
            height: 80,
            padding: const EdgeInsets.all(5.0),
            color: Colors.black.withOpacity(0.5),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const ImageWidget(image: ''),
                const SizedBox(
                  width: 15.0,
                ),
                Text(name, style: const TextStyle(color: Colors.white)),
                const SizedBox(
                  width: 15.0,
                ),
                Text(title!, style: const TextStyle(color: Colors.white)),
              ]),
              const SizedBox(
                height: 15.0,
              ),
              ExtendedText(
                content,
                style: const TextStyle(
                  color: Colors.white,
                  //fontSize: 16.0,
                ),
                specialTextSpanBuilder: customSpecialTextSpanBuilder,
                onSpecialTextTap: (dynamic value) {
                  if (value.toString().startsWith('\$')) {
                    launchUrl(Uri(
                        scheme: 'https',
                        host: 'github.com',
                        path: 'fluttercandies'));
                  } else if (value.toString().startsWith('@')) {
                    launchUrl(Uri(
                      scheme: 'mailto',
                      path: 'zmtzawqlp@live.com',
                    ));
                  }
                },
              ),
            ]));

        //延时
        Future.delayed(const Duration(seconds: 10)).then((value) {
          setState(() {
            chatMessageVisible = false;
          });
        });
      }
    }
    return Visibility(
        visible: chatMessageVisible,
        child: Align(alignment: Alignment.topLeft, child: card));
  }

  _update() async {
    ChatMessage? chatMessage = globalChatMessageController.chatMessage;
    if (chatMessage != null) {
      if (chatMessage.subMessageType == ChatSubMessageType.chat.name) {
        setState(() {
          chatMessageVisible = true;
        });
      } else if (chatMessage.subMessageType ==
          ChatSubMessageType.videoChat.name) {
        setState(() {
          videoChatVisible = true;
        });
      }
    }
  }

  _onTap(ChatMessage chatMessage, MessageStatus chatReceiptType) {
    setState(() {
      videoChatVisible = false;
    });
  }

  Widget _buildVideoDialIn(BuildContext context, ChatMessage chatMessage) {
    Widget videoDialInWidget;
    videoDialInWidget = VideoDialInWidget(
      chatMessage: chatMessage,
      onTap: _onTap,
    );
    return Align(alignment: Alignment.topLeft, child: videoDialInWidget);
  }

  Widget _createScaffold(
      BuildContext context, IndexWidgetProvider indexWidgetProvider) {
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
                  child: widget.indexWidget,
                  height: appDataProvider.mobileSize.height,
                  width: appDataProvider.mobileSize.width)),
          _buildChatMessage(context),
          _buildVideoChatMessage(context)
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
