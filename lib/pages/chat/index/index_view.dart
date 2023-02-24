import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/video_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/index/bottom_bar.dart';
import 'package:colla_chat/pages/chat/index/global_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/index/index_widget.dart';
import 'package:colla_chat/pages/chat/login/loading.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
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
  final ValueNotifier<bool> videoChatMessageVisible =
      ValueNotifier<bool>(false);
  final ValueNotifier<bool> chatMessageVisible = ValueNotifier<bool>(false);
  final CustomSpecialTextSpanBuilder customSpecialTextSpanBuilder =
      CustomSpecialTextSpanBuilder();
  VideoChatMessageController videoChatMessageController =
      VideoChatMessageController();
  BlueFireAudioPlayer audioPlayer = BlueFireAudioPlayer();

  //JustAudioPlayer audioPlayer = JustAudioPlayer();

  @override
  void initState() {
    super.initState();
    globalChatMessageController.addListener(_updateGlobalChatMessage);
    myself.addListener(_update);
    appDataProvider.addListener(_update);
  }

  ///myself和appDataProvider发生变化后刷新整个界面
  _update() async {
    if (mounted) {
      //setState(() {});
    }
  }

  _play() {
    audioPlayer.setLoopMode(true);
    audioPlayer.play('assets/medias/mediaInvitation.mp3');
  }

  _stop() {
    audioPlayer.stop();
  }

  ///有新消息到来的时候，一般消息直接显示，视频邀请消息显示带按钮选择接受还是拒绝
  _updateGlobalChatMessage() async {
    ChatMessage? chatMessage = globalChatMessageController.chatMessage;
    if (chatMessage != null) {
      if (chatMessage.subMessageType == ChatMessageSubType.chat.name) {
        chatMessageVisible.value = true;
      } else if (chatMessage.subMessageType ==
          ChatMessageSubType.videoChat.name) {
        await videoChatMessageController.setChatMessage(chatMessage);
        videoChatMessageVisible.value = true;
      }
    }
  }

  ///显示一般消息
  _buildChatMessageBanner(BuildContext context) {
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
                          myself.avatarImage ?? AppImage.mdAppImage,
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

              //延时30秒后一般消息消失
              Future.delayed(const Duration(seconds: 30)).then((value) {
                chatMessageVisible.value = false;
              });
            }
          }
          return Visibility(visible: value, child: banner);
        });
  }

  ///显示视频邀请消息组件
  Widget _buildVideoChatMessageWidget(
      BuildContext context, ChatMessage chatMessage) {
    var name = chatMessage.senderName;
    name = name ?? '';
    var title = chatMessage.title;
    title = title ?? '';
    return Container(
        alignment: Alignment.topLeft,
        width: appDataProvider.totalSize.width,
        padding: const EdgeInsets.all(5.0),
        color: Colors.black.withOpacity(AppOpacity.mdOpacity),
        child: ListTile(
            leading: myself.avatarImage,
            isThreeLine: true,
            title: Text(name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
                AppLocalizations.t('Inviting you $title chat, ') +
                    AppLocalizations.t('conference name ') +
                    videoChatMessageController.conference!.name,
                style: const TextStyle(color: Colors.white)),
            trailing: SizedBox(
              width: 130,
              child: Row(children: [
                WidgetUtil.buildCircleButton(
                    onPressed: () {
                      videoChatMessageVisible.value = false;
                      _stop();
                      videoChatMessageController
                          .sendChatReceipt(MessageStatus.rejected);
                    },
                    child: const Icon(
                        color: Colors.white, size: 16, Icons.call_end),
                    backgroundColor: Colors.red),
                WidgetUtil.buildCircleButton(
                    onPressed: () {
                      videoChatMessageVisible.value = false;
                      _stop();
                      videoChatMessageController
                          .sendChatReceipt(MessageStatus.accepted);
                    },
                    child: const Icon(
                        color: Colors.white, size: 16, Icons.video_call),
                    backgroundColor: Colors.green),
              ]),
            )));
  }

  _buildVideoChatMessageBanner(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: videoChatMessageVisible,
      builder: (BuildContext context, bool value, Widget? child) {
        Widget videoChatMessageWidget = Container();
        if (value) {
          _play();
          ChatMessage? chatMessage = globalChatMessageController.chatMessage;
          if (chatMessage != null) {
            //视频通话请求消息
            if (chatMessage.subMessageType ==
                ChatMessageSubType.videoChat.name) {
              videoChatMessageWidget =
                  _buildVideoChatMessageWidget(context, chatMessage);
              //延时60秒后一般消息消失
              Future.delayed(const Duration(seconds: 60)).then((value) {
                _stop();
                if (videoChatMessageVisible.value) {
                  videoChatMessageVisible.value = false;
                  ChatMessage? chatMessage =
                      videoChatMessageController.chatMessage;
                  if (chatMessage != null && chatMessage.groupType != null) {
                    videoChatMessageController
                        .sendChatReceipt(MessageStatus.accepted);
                  }
                }
              });
            }
          }
        }
        return Visibility(
            visible: videoChatMessageVisible.value,
            child: videoChatMessageWidget);
      },
    );
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
            _buildChatMessageBanner(context),
            _buildVideoChatMessageBanner(context)
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
