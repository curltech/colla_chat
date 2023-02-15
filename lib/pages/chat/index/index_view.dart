import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/pages/chat/index/bottom_bar.dart';
import 'package:colla_chat/pages/chat/index/global_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/index/index_widget.dart';
import 'package:colla_chat/pages/chat/login/loading.dart';
import 'package:colla_chat/pages/chat/video/video_dialin_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/widgets/special_text/custom_special_text_span_builder.dart';
import 'package:colla_chat/widgets/style/platform_widget_factory.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  final ValueNotifier<bool> videoChatVisible = ValueNotifier<bool>(false);
  final ValueNotifier<bool> chatMessageVisible = ValueNotifier<bool>(false);
  final CustomSpecialTextSpanBuilder customSpecialTextSpanBuilder =
      CustomSpecialTextSpanBuilder();

  @override
  void initState() {
    super.initState();
    globalChatMessageController.addListener(_updateGlobalChatMessage);
    myself.addListener(_update);
    appDataProvider.addListener(_update);
  }

  _onTap(ChatMessage chatMessage, MessageStatus chatReceiptType) {
    videoChatVisible.value = false;
  }

  Widget _buildVideoDialIn(BuildContext context, ChatMessage chatMessage) {
    Widget videoDialInWidget = Container(
        alignment: Alignment.topLeft,
        width: appDataProvider.totalSize.width,
        padding: const EdgeInsets.all(5.0),
        color: Colors.black.withOpacity(AppOpacity.mdOpacity),
        child: VideoDialInWidget(
          chatMessage: chatMessage,
          onTap: _onTap,
        ));
    return videoDialInWidget;
  }

  _buildVideoChatMessage(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: videoChatVisible,
      builder: (BuildContext context, bool value, Widget? child) {
        Widget videoDialIn = Container();
        if (value) {
          ChatMessage? chatMessage = globalChatMessageController.chatMessage;
          if (chatMessage != null) {
            //视频通话请求消息
            if (chatMessage.subMessageType ==
                ChatMessageSubType.videoChat.name) {
              videoDialIn = _buildVideoDialIn(context, chatMessage);
            }
          }
          //延时，移除 OverlayEntry
          Future.delayed(const Duration(seconds: 60)).then((value) {
            videoChatVisible.value = false;
          });
        }
        return Visibility(visible: videoChatVisible.value, child: videoDialIn);
      },
    );
  }

  _buildChatMessage(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: chatMessageVisible,
        builder: (BuildContext context, bool value, Widget? child) {
          Widget banner = Container();
          if (value) {
            ChatMessage? chatMessage = globalChatMessageController.chatMessage;
            if (chatMessage != null &&
                chatMessage.subMessageType == ChatMessageSubType.chat.name) {
              String? content = chatMessage.content;
              String? contentType = chatMessage.contentType;
              if (content != null &&
                  (contentType == null ||
                      contentType == ContentType.text.name)) {
                content = chatMessageService.recoverContent(content);
              } else {
                content = '';
              }
              String? title = chatMessage.title;
              title = title ?? '';
              var name = chatMessage.senderName;
              name = name ?? '';
              banner = Container(
                  height: 80,
                  width: appDataProvider.totalSize.width,
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(5.0),
                  color: Colors.black.withOpacity(AppOpacity.mdOpacity),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          myself.avatarImage!,
                          const SizedBox(
                            width: 15.0,
                          ),
                          Text(name,
                              style: const TextStyle(color: Colors.white)),
                          const SizedBox(
                            width: 15.0,
                          ),
                          Text(title,
                              style: const TextStyle(color: Colors.white)),
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
                        ),
                      ]));

              //延时
              Future.delayed(const Duration(seconds: 30)).then((value) {
                setState(() {
                  chatMessageVisible.value = false;
                });
              });
            }
          }
          return Visibility(visible: value, child: banner);
        });
  }

  _updateGlobalChatMessage() async {
    if (mounted) {
      ChatMessage? chatMessage = globalChatMessageController.chatMessage;
      if (chatMessage != null) {
        if (chatMessage.subMessageType == ChatMessageSubType.chat.name) {
          chatMessageVisible.value = true;
        } else if (chatMessage.subMessageType ==
            ChatMessageSubType.videoChat.name) {
          videoChatVisible.value = true;
        }
      }
    }
  }

  _update() async {
    if (mounted) {
      //setState(() {});
    }
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
                  height: appDataProvider.actualSize.height,
                  width: appDataProvider.actualSize.width)),
          Row(children: [
            _buildChatMessage(context),
            _buildVideoChatMessage(context)
          ]),
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
    globalChatMessageController.removeListener(_updateGlobalChatMessage);
    myself.removeListener(_update);
    appDataProvider.removeListener(_update);
    super.dispose();
  }
}
