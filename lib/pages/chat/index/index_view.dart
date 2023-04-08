import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/video_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/index/bottom_bar.dart';
import 'package:colla_chat/pages/chat/index/global_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/index/index_widget.dart';
import 'package:colla_chat/pages/chat/login/loading.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/transport/webrtc/remote_video_render_controller.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/special_text/custom_special_text_span_builder.dart';
import 'package:colla_chat/widgets/style/platform_widget_factory.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
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
  VideoChatMessageController? videoChatMessageController;
  BlueFireAudioPlayer? audioPlayer;

  //JustAudioPlayer audioPlayer = JustAudioPlayer();
  Widget bannerAvatarImage = AppImage.mdAppImage;

  @override
  void initState() {
    super.initState();
    try {
      audioPlayer = BlueFireAudioPlayer();
    } catch (e) {
      logger.e('BlueFireAudioPlayer create error:$e');
    }
    globalChatMessageController.addListener(_updateGlobalChatMessage);
    myself.addListener(_update);
    appDataProvider.addListener(_update);
  }

  ///myself和appDataProvider发生变化后刷新整个界面
  _update() async {
    if (mounted) {
      setState(() {});
    }
  }

  _play() {
    audioPlayer?.setLoopMode(true);
    audioPlayer?.play('assets/medias/invitation.mp3');
  }

  _stop() {
    audioPlayer?.stop();
  }

  ///有新消息到来的时候，一般消息直接显示
  _updateGlobalChatMessage() async {
    ChatMessage? chatMessage = globalChatMessageController.chatMessage;
    if (chatMessage != null) {
      String senderPeerId = chatMessage.senderPeerId!;
      Linkman? linkman =
          await linkmanService.findCachedOneByPeerId(senderPeerId);
      if (linkman != null) {
        bannerAvatarImage = linkman.avatarImage ?? AppImage.mdAppImage;
      }
      if (chatMessage.subMessageType == ChatMessageSubType.chat.name) {
        chatMessageVisible.value = true;
      }
      //新的视频邀请消息到来，创建新的视频消息控制器，原来的如果存在，新的将被忽视，占线
      if (chatMessage.subMessageType == ChatMessageSubType.videoChat.name) {
        if (videoChatMessageController == null) {
          videoChatMessageController = VideoChatMessageController();
          await videoChatMessageController!.setChatMessage(chatMessage);
          videoChatMessageVisible.value = true;
        } else {
          var videoChatMessageController = VideoChatMessageController();
          await videoChatMessageController.setChatMessage(chatMessage);
          await videoChatMessageController
              .sendChatReceipt(MessageReceiptType.busy);
        }
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
              List<Widget> children = <Widget>[];
              var name = chatMessage.senderName;
              if (name != null) {
                children.add(
                  CommonAutoSizeText(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                );
              }
              String? title = chatMessage.title;
              if (title != null) {
                children.add(
                  CommonAutoSizeText(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400)),
                );
              }
              String? content = chatMessage.content;
              String? contentType = chatMessage.contentType;
              if (content != null &&
                  (contentType == null ||
                      contentType == ChatMessageContentType.text.name)) {
                content = chatMessageService.recoverContent(content);
                children.add(Expanded(
                    child: ExtendedText(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    //fontSize: 16.0,
                  ),
                  specialTextSpanBuilder: customSpecialTextSpanBuilder,
                )));
              }

              banner = InkWell(
                  onTap: () {
                    chatMessageVisible.value = false;
                  },
                  child: Container(
                      height: appDataProvider.toolbarHeight,
                      width: appDataProvider.totalSize.width,
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.all(5.0),
                      color: Colors.black.withOpacity(AppOpacity.mdOpacity),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            bannerAvatarImage,
                            const SizedBox(
                              width: 15.0,
                            ),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: children),
                          ])));

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
    var rejectedButton = CircleTextButton(
        onPressed: () async {
          videoChatMessageVisible.value = false;
          _stop();
          await videoChatMessageController!
              .sendChatReceipt(MessageReceiptType.rejected);
          videoChatMessageController = null;
        },
        backgroundColor: Colors.red,
        child: const Icon(color: Colors.white, size: 16, Icons.call_end));
    var holdButton = CircleTextButton(
        onPressed: () async {
          videoChatMessageVisible.value = false;
          _stop();
          await videoChatMessageController!
              .sendChatReceipt(MessageReceiptType.hold);
          videoChatMessageController = null;
        },
        backgroundColor: Colors.amber,
        child: const Icon(color: Colors.white, size: 16, Icons.add_call));
    var acceptedButton = CircleTextButton(
        onPressed: () async {
          videoChatMessageVisible.value = false;
          _stop();
          await videoChatMessageController!
              .sendChatReceipt(MessageReceiptType.accepted);
          videoChatMessageController = null;
        },
        backgroundColor: Colors.green,
        child: const Icon(color: Colors.white, size: 16, Icons.call));
    List<Widget> buttons = <Widget>[];
    buttons.add(rejectedButton);
    buttons.add(holdButton);
    //立即接听按钮只有当前不在会议中，而且是个人或者群模式才可以
    if (videoConferenceRenderPool.conferenceId == null &&
        chatMessage.groupType != PartyType.conference.name) {
      buttons.add(acceptedButton);
    }
    return Container(
        alignment: Alignment.topLeft,
        width: appDataProvider.totalSize.width,
        padding: const EdgeInsets.all(5.0),
        color: Colors.black.withOpacity(AppOpacity.mdOpacity),
        child: ListTile(
            leading: bannerAvatarImage,
            isThreeLine: false,
            title: CommonAutoSizeText(name,
                style: const TextStyle(color: Colors.white)),
            subtitle: CommonAutoSizeText(
                AppLocalizations.t('Inviting you $title chat ') +
                    videoChatMessageController!.conference!.name,
                style: const TextStyle(color: Colors.white)),
            trailing: SizedBox(
              width: 200,
              child: Row(children: buttons),
            )));
  }

  _buildVideoChatMessageBanner(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: videoChatMessageVisible,
      builder: (BuildContext context, bool value, Widget? child) {
        Widget videoChatMessageWidget = Container();
        if (value) {
          _play();
          ChatMessage? chatMessage = videoChatMessageController!.chatMessage;
          if (chatMessage != null) {
            //视频通话请求消息
            if (chatMessage.subMessageType ==
                ChatMessageSubType.videoChat.name) {
              videoChatMessageWidget =
                  _buildVideoChatMessageWidget(context, chatMessage);
              //延时60秒后视频邀请消息消失，发送ignored回执
              Future.delayed(const Duration(seconds: 60)).then((value) async {
                _stop();
                if (videoChatMessageVisible.value) {
                  videoChatMessageVisible.value = false;
                  await videoChatMessageController!
                      .sendChatReceipt(MessageReceiptType.ignored);
                  videoChatMessageController?.dispose();
                  videoChatMessageController = null;
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
    Widget? bottomNavigationBar =
        indexWidgetProvider.bottomBarVisible ? const BottomBar() : null;
    double bottomBarHeight = indexWidgetProvider.bottomBarVisible
        ? appDataProvider.bottomBarHeight
        : 0.0;
    Scaffold scaffold = Scaffold(
        backgroundColor: myself.primary,
        resizeToAvoidBottomInset: true,
        primary: true,
        body: KeyboardDismissOnTap(
            dismissOnCapturedTaps: false,
            child: SafeArea(
                child: Stack(children: <Widget>[
              Opacity(
                opacity: 1,
                child: loadingWidget,
              ),
              Center(
                  child: platformWidgetFactory.buildSizedBox(
                      child: widget.indexWidget,
                      height:
                          appDataProvider.actualSize.height - bottomBarHeight,
                      width: appDataProvider.actualSize.width)),
              Row(children: [
                _buildChatMessageBanner(context),
                _buildVideoChatMessageBanner(context)
              ]),
            ]))),
        //endDrawer: endDrawer,
        bottomNavigationBar: bottomNavigationBar);

    return scaffold;
  }

  @override
  Widget build(BuildContext context) {
    appDataProvider.changeSize(context);
    var provider = Consumer3<AppDataProvider, IndexWidgetProvider, Myself>(
      builder: (context, appDataProvider, indexWidgetProvider, myself, child) =>
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
