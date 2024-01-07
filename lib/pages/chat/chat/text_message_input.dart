import 'dart:async';
import 'dart:io';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/extended_text_message_input.dart';
import 'package:colla_chat/pages/chat/chat/message/message_widget.dart';
import 'package:colla_chat/pages/chat/index/global_chat_message.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/menu_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/openai/openai_chat_gpt.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/media/audio/recorder/platform_audio_recorder.dart';
import 'package:colla_chat/widgets/media/audio/recorder/record_audio_recorder.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

///发送文本消息的输入框和按钮，
///包括声音按钮，扩展文本输入框，emoji按钮，其他多种格式输入按钮和发送按钮
class TextMessageInputWidget extends StatefulWidget {
  final TextEditingController textEditingController;
  final Future<void> Function()? onSendPressed;
  final void Function()? onEmojiPressed;
  final void Function()? onMorePressed;

  const TextMessageInputWidget({
    super.key,
    required this.textEditingController,
    this.onSendPressed,
    this.onEmojiPressed,
    this.onMorePressed,
  });

  @override
  State<StatefulWidget> createState() {
    return _TextMessageInputWidgetState();
  }
}

class _TextMessageInputWidgetState extends State<TextMessageInputWidget> {
  bool voiceVisible = true;
  bool sendVisible = false;
  bool moreVisible = false;
  bool voiceRecording = false;

  // ValueNotifier<ChatGPTAction> chatGPTAction =
  //     ValueNotifier<ChatGPTAction>(ChatGPTAction.chat);

  @override
  void initState() {
    super.initState();
    widget.textEditingController.addListener(_update);
    chatMessageController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  ///停止录音，把录音数据作为消息发送
  _onStop(String filename) async {
    if (StringUtil.isNotEmpty(filename)) {
      List<int>? data = await FileUtil.readFileAsBytes(filename);
      if (data == null) {
        return;
      }
      logger.i('record audio file: $filename length: ${data.length}');
      String? mimeType = FileUtil.mimeType(filename);
      await chatMessageController.send(
          content: data,
          title: FileUtil.filename(filename),
          contentType: ChatMessageContentType.audio,
          mimeType: mimeType,
          subMessageType: ChatMessageSubType.chat);
      // 发送保存结束后删除录音文件
      File file = File(filename);
      file.deleteSync();
    }
  }

  ///文本录入按钮
  Widget _buildExtendedTextField(context) {
    return ExtendedTextMessageInputWidget(
      textEditingController: widget.textEditingController,
    );
  }

  ///语音录音按钮
  Widget _buildVoiceRecordButton(context) {
    RecordAudioRecorderController audioRecorderController =
        globalRecordAudioRecorderController;
    audioRecorderController.encoder = AudioEncoder.aacLc;
    PlatformAudioRecorder platformAudioRecorder = PlatformAudioRecorder(
      onStop: _onStop,
      audioRecorderController: audioRecorderController,
    );

    return platformAudioRecorder;
  }

  bool _hasValue() {
    var value = widget.textEditingController.value.text;
    return StringUtil.isNotEmpty(value);
  }

  List<ActionData> _buildChatGPTSendAction() {
    ChatGPTAction chatGPTAction = chatMessageController.chatGPTAction;
    final List<ActionData> chatGPTPopActions = [
      ActionData(
          label: ChatGPTAction.chat.name,
          tooltip: 'Chat message',
          icon: Icon(
            Icons.chat,
            color: ChatGPTAction.chat == chatGPTAction
                ? myself.primary
                : myself.secondary,
          )),
      ActionData(
          label: ChatGPTAction.translate.name,
          tooltip: 'Translate message',
          icon: Icon(
            Icons.translate,
            color: ChatGPTAction.translate == chatGPTAction
                ? myself.primary
                : myself.secondary,
          )),
      ActionData(
          label: ChatGPTAction.extract.name,
          tooltip: 'Extract message',
          icon: Icon(
            Icons.summarize_outlined,
            color: ChatGPTAction.extract == chatGPTAction
                ? myself.primary
                : myself.secondary,
          )),
      ActionData(
        label: ChatGPTAction.image.name,
        tooltip: 'Create image',
        icon: Icon(
          Icons.image_outlined,
          color: ChatGPTAction.image == chatGPTAction
              ? myself.primary
              : myself.secondary,
        ),
      ),
      ActionData(
        label: ChatGPTAction.audio.name,
        tooltip: 'Transcription audio',
        icon: Icon(
          Icons.multitrack_audio,
          color: ChatGPTAction.audio == chatGPTAction
              ? myself.primary
              : myself.secondary,
        ),
      ),
    ];

    return chatGPTPopActions;
  }

  List<ActionData> _buildTransportTypeSendAction() {
    TransportType transportType = chatMessageController.transportType;
    final List<ActionData> transportTypeActions = [
      ActionData(
          label: TransportType.webrtc.name,
          tooltip: 'Webrtc send',
          icon: Icon(
            Icons.webhook_rounded,
            color: TransportType.webrtc == transportType
                ? myself.primary
                : myself.secondary,
          )),
      ActionData(
          label: TransportType.email.name,
          tooltip: 'Email send',
          icon: Icon(
            Icons.email,
            color: TransportType.email == transportType
                ? myself.primary
                : myself.secondary,
          )),
      ActionData(
        label: TransportType.sfu.name,
        tooltip: 'SFU send',
        icon: Icon(
          Icons.center_focus_strong,
          color: TransportType.sfu == transportType
              ? myself.primary
              : myself.secondary,
        ),
      ),
      ActionData(
        label: TransportType.nearby.name,
        tooltip: 'Nearby send',
        icon: Icon(
          Icons.near_me_outlined,
          color: TransportType.nearby == transportType
              ? myself.primary
              : myself.secondary,
        ),
      ),
    ];

    if (platformParams.mobile) {
      transportTypeActions.add(
        ActionData(
            label: TransportType.sms.name,
            tooltip: 'SMS send',
            icon: Icon(
              Icons.sms,
              color: TransportType.sms == transportType
                  ? myself.primary
                  : myself.secondary,
            )),
      );
    }

    transportTypeActions.add(ActionData(
        label: 'SMS receive',
        tooltip: 'SMS receive',
        icon: Icon(
          Icons.try_sms_star,
          color: myself.primary,
        )));

    return transportTypeActions;
  }

  ///各种不同的ChatGPT的prompt的消息发送命令
  ///比如文本聊天，翻译，提取摘要，文本生成图片
  _onChatGPTSend(BuildContext context, int index, String label,
      {String? value}) async {
    ChatGPTAction? chatGPTAction =
        StringUtil.enumFromString(ChatGPTAction.values, label);
    if (chatGPTAction == null) {
      return null;
    }
    chatMessageController.chatGPTAction = chatGPTAction;
    // this.chatGPTAction.value = chatGPTAction;
    _send();
  }

  _onTransportSend(BuildContext context, int index, String label,
      {String? value}) async {
    if (label == 'SMS receive') {
      _onActionReceiveSms();
    } else {
      TransportType? transportType =
          StringUtil.enumFromString(TransportType.values, label);
      if (transportType == null) {
        return null;
      }
      chatMessageController.transportType = transportType;
      _send();
    }
  }

  _send() {
    if (widget.onSendPressed != null) {
      widget.onSendPressed!();
      widget.textEditingController.clear();
    }
  }

  ///接收到加密短信
  _onActionReceiveSms() async {
    ChatSummary? chatSummary = chatMessageController.chatSummary;
    if (chatSummary == null) {
      return;
    }
    Linkman? linkman =
        await linkmanService.findCachedOneByPeerId(chatSummary.peerId!);
    String text = widget.textEditingController.text;
    if (linkman != null && text.isNotEmpty) {
      await globalChatMessage.onLinkmanSmsMessage(linkman, text);
    }
    widget.textEditingController.clear();
  }

  ///弹出ChatGPT的命令菜单
  _buildChatGPTMenu(BuildContext context) {
    Widget sendButton = Visibility(
        visible: _hasValue(),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
          child: IconButton(
            tooltip: AppLocalizations.t('Send'),
            icon: Icon(Icons.send_outlined, color: myself.primary),
            onPressed: () {
              _send();
            },
          ),
        ));

    ///长按弹出式菜单
    ChatGPT? chatGPT = chatMessageController.chatGPT;
    CustomPopupMenuController menuController = CustomPopupMenuController();
    Widget menu = MenuUtil.buildPopupMenu(
        child: sendButton,
        controller: menuController,
        menuBuilder: () {
          return Card(
            child: DataActionCard(
                onPressed: (int index, String label, {String? value}) {
                  menuController.hideMenu();
                  if (chatGPT == null) {
                    _onTransportSend(context, index, label, value: value);
                  } else {
                    _onChatGPTSend(context, index, label, value: value);
                  }
                },
                crossAxisCount: 4,
                actions: chatGPT != null
                    ? _buildChatGPTSendAction()
                    : _buildTransportTypeSendAction(),
                height: 140,
                width: 320,
                iconSize: 20),
          );
        },
        pressType: PressType.longPress);

    return menu;
  }

  ///文本，录音，其他消息，ChatGPT消息命令和发送按钮
  Widget _buildTextMessageInput(BuildContext context) {
    double iconInset = 0.0;
    return Card(
        elevation: 0.0,
        margin:
            EdgeInsets.symmetric(horizontal: iconInset, vertical: iconInset),
        shape: const ContinuousRectangleBorder(),
        child: Row(children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(
                horizontal: iconInset, vertical: iconInset),
            child: IconButton(
              tooltip: voiceVisible
                  ? AppLocalizations.t('Voice')
                  : AppLocalizations.t('Keyboard'),
              icon: voiceVisible
                  ? Icon(Icons.record_voice_over_outlined,
                      color: myself.primary)
                  : Icon(Icons.keyboard_alt_outlined, color: myself.primary),
              onPressed: () {
                setState(() {
                  voiceVisible = !voiceVisible;
                });
              },
            ),
          ),
          Expanded(child: _buildMessageInputWidget(context)),
          Container(
            margin: EdgeInsets.symmetric(
                horizontal: iconInset, vertical: iconInset),
            child: IconButton(
              tooltip: AppLocalizations.t('Emoji'),
              icon: Icon(Icons.emoji_emotions_outlined, color: myself.primary),
              onPressed: () {
                if (widget.onEmojiPressed != null) {
                  widget.onEmojiPressed!();
                }
              },
            ),
          ),
          Visibility(
              visible: !_hasValue(),
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
                child: IconButton(
                  tooltip: AppLocalizations.t('More'),
                  icon: Icon(Icons.more_horiz, color: myself.primary),
                  onPressed: () {
                    if (widget.onMorePressed != null) {
                      widget.onMorePressed!();
                    }
                  },
                ),
              )),
          _buildChatGPTMenu(context),
        ]));
  }

  ///语音录音按钮和文本输入框
  Widget _buildMessageInputWidget(BuildContext context) {
    List<Widget> children = [
      voiceVisible
          ? _buildExtendedTextField(context)
          : _buildVoiceRecordButton(context)
    ];
    Widget? parentWidget = MessageWidget.buildParentChatMessageWidget();
    if (parentWidget != null) {
      children.add(const SizedBox(
        height: 2,
      ));
      children.add(parentWidget);
    }
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 2.0),
        alignment: Alignment.center,
        child: Column(children: children));
  }

  @override
  Widget build(BuildContext context) {
    return _buildTextMessageInput(context);
  }

  @override
  void dispose() {
    widget.textEditingController.removeListener(_update);
    chatMessageController.removeListener(_update);
    super.dispose();
  }
}
