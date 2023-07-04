import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/channel/channel_chat_message_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/richtext/platform_editor_widget.dart';
import 'package:colla_chat/widgets/webview/html_preview_widget.dart';
import 'package:flutter/material.dart';

///自己发布频道消息编辑页面
class PublishChannelEditWidget extends StatefulWidget with TileDataMixin {
  PublishChannelEditWidget({Key? key}) : super(key: key);

  @override
  State createState() => _PublishChannelEditWidgetState();

  @override
  String get routeName => 'publish_channel_edit';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.edit;

  @override
  String get title => 'Publish Channel Edit';
}

class _PublishChannelEditWidgetState extends State<PublishChannelEditWidget> {
  ValueNotifier<String?> thumbnail = ValueNotifier<String?>(null);
  ValueNotifier<String?> documentText = ValueNotifier<String?>(null);
  ChatMessageMimeType mimeType = ChatMessageMimeType.html;
  SwiperController controller = SwiperController();
  final TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ChatMessage? chatMessage = myChannelChatMessageController.current;
    if (chatMessage != null) {
      if (chatMessage.title != null) {
        textEditingController.text = chatMessage.title!;
      }
      if (chatMessage.thumbnail != null) {
        thumbnail.value = chatMessage.thumbnail!;
      }
      _init(chatMessage);
    }
  }

  _init(ChatMessage chatMessage) async {
    var bytes = await messageAttachmentService.findContent(
        chatMessage.messageId!, chatMessage.title!);
    if (bytes != null) {
      documentText.value = CryptoUtil.utf8ToString(bytes);
    }
  }

  ///编辑器提交表示暂存，原生的格式，json或者html
  Future<void> _onSubmit(String? content, ChatMessageMimeType mimeType) async {
    documentText.value = content;
    this.mimeType = mimeType;
    await _save();
  }

  ///保存到数据库为草案，采用原生的可编辑模式，发布后才转换成统一的html格式，便不可更改
  Future<void> _save() async {
    String title = textEditingController.text;
    if (StringUtil.isEmpty(title)) {
      DialogUtil.error(context, content: AppLocalizations.t('Must be title'));
      return;
    }
    if (StringUtil.isEmpty(documentText.value)) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must be html content'));
      return;
    }
    ChatMessage? chatMessage = myChannelChatMessageController.current;
    if (chatMessage != null) {
      chatMessage.title = title;
      chatMessage.content =
          chatMessageService.processContent(documentText.value!);
      chatMessage.thumbnail = thumbnail.value;
    } else {
      chatMessage = await myChannelChatMessageController
          .buildChannelChatMessage(title, documentText.value!, thumbnail.value);
      myChannelChatMessageController.current = chatMessage;
    }
    chatMessage.mimeType = mimeType.name;
    await chatMessageService.store(chatMessage);
    if (mounted) {
      DialogUtil.info(context,
          content: AppLocalizations.t('Save html file successfully'));
    }
  }

  Widget _buildTitleTextField(BuildContext context) {
    var textFormField = CommonAutoSizeTextFormField(
      controller: textEditingController,
      labelText: AppLocalizations.t('Title'),
    );

    return textFormField;
  }

  _onPreview(String? content, ChatMessageMimeType mimeType) {
    if (mimeType == ChatMessageMimeType.html) {
      indexWidgetProvider.push('html_preview');
      htmlPreviewController.title = textEditingController.text;
      htmlPreviewController.html = content;
    }
  }

  Widget _buildChannelItemView(BuildContext context) {
    Widget titleWidget = Container(
        padding: const EdgeInsets.all(10.0),
        child: _buildTitleTextField(context));
    Widget view = Column(children: [
      titleWidget,
      Expanded(
          child: KeepAliveWrapper(
              child: PlatformEditorWidget(
        onPreview: _onPreview,
        onSubmit: _onSubmit,
      )))
    ]);

    return view;
  }

  ///将编辑的内容正式发布，统一采用html格式保存和发送，原先保存的草案要转换格式，更新状态
  _publish() async {
    ChatMessage? chatMessage = myChannelChatMessageController.current;
    if (chatMessage != null) {
      await myChannelChatMessageController.publish(chatMessage.messageId!);
      if (mounted) {
        DialogUtil.info(context,
            content: AppLocalizations.t('Publish channel successfully'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      centerTitle: false,
      withLeading: true,
      title: widget.title,
      rightWidgets: [
        IconButton(
          icon: const Icon(Icons.publish),
          onPressed: () async {
            await _publish();
          },
          tooltip: AppLocalizations.t('Publish'),
        )
      ],
      child: _buildChannelItemView(context),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
