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
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/richtext/platform_editor_widget.dart';
import 'package:colla_chat/widgets/webview/html_preview_widget.dart';
import 'package:flutter/material.dart';

///自己发布频道消息编辑页面
class PublishChannelEditWidget extends StatefulWidget with DataTileMixin {
  PublishChannelEditWidget({super.key});

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
  final TextEditingController textEditingController = TextEditingController();
  PlatformEditorController platformEditorController =
      PlatformEditorController();

  @override
  void initState() {
    super.initState();
  }

  Future<String> _findContent() async {
    ChatMessage? chatMessage = myChannelChatMessageController.current;
    if (chatMessage != null) {
      String mimeType = chatMessage.mimeType!;
      if (chatMessage.title != null) {
        textEditingController.text = chatMessage.title!;
      }
      if (chatMessage.thumbnail != null) {
        thumbnail.value = chatMessage.thumbnail!;
      }
      var bytes = await messageAttachmentService.findContent(
          chatMessage.messageId!, chatMessage.title!);
      if (bytes != null) {
        String content = CryptoUtil.utf8ToString(bytes);

        return content;
      }
    }

    return '';
  }

  Future<void> _onPreview() async {
    indexWidgetProvider.push('html_preview');
    htmlPreviewController.title = textEditingController.text;
    htmlPreviewController.html = await platformEditorController.html;
  }

  ///保存到数据库为草案，采用原生的可编辑模式，发布后才转换成统一的html格式，便不可更改
  Future<void> _save() async {
    String title = textEditingController.text;
    if (StringUtil.isEmpty(title)) {
      DialogUtil.error(content: AppLocalizations.t('Must have title'));
      return;
    }
    String? content = await platformEditorController.content;
    if (mounted && StringUtil.isEmpty(content)) {
      DialogUtil.error(content: AppLocalizations.t('Must have content'));
      return;
    }
    ChatMessage? chatMessage = myChannelChatMessageController.current;
    bool newDocument = false;
    if (chatMessage != null) {
      String? status = chatMessage.status;
      if (status != MessageStatus.published.name) {
        chatMessage.title = title;
        chatMessage.content = chatMessageService.processContent(content!);
        chatMessage.thumbnail = thumbnail.value;
      } else {
        if (mounted) {
          DialogUtil.info(
              content: 'Document already was published, can not be updated');
        }
        return;
      }
    } else {
      chatMessage = await myChannelChatMessageController
          .buildChannelChatMessage(title, content!, thumbnail.value);
      myChannelChatMessageController.insert(0, chatMessage);
      newDocument = true;
    }
    ChatMessageMimeType mimeType = platformEditorController.mimeType;
    chatMessage.mimeType = mimeType.name;
    await chatMessageService.store(chatMessage);
    if (newDocument) {
      //myChannelChatMessageController.add(chatMessage);
    }
    if (mounted) {
      DialogUtil.info(
          content: AppLocalizations.t('Save draft content successfully'));
    }
  }

  Widget _buildTitleTextField(BuildContext context) {
    var textFormField = TextFormField(
        controller: textEditingController,
        decoration: buildInputDecoration(
          labelText: AppLocalizations.t('Title'),
        ));

    return textFormField;
  }

  Widget _buildChannelItemView(BuildContext context) {
    Widget titleWidget = Container(
        padding: const EdgeInsets.all(5.0),
        child: _buildTitleTextField(context));
    Widget view = PlatformFutureBuilder(
        future: _findContent(),
        builder: (BuildContext context, String? content) {
          return Column(children: [
            titleWidget,
            Expanded(
                child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 0.0, horizontal: 5.0),
                    child: PlatformEditorWidget(
                      initialText: content,
                      platformEditorController: platformEditorController,
                    )))
          ]);
        });

    return view;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      centerTitle: false,
      withLeading: true,
      title: widget.title,
      helpPath: widget.routeName,
      rightWidgets: [
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: () async {
            await _save();
          },
          tooltip: AppLocalizations.t('Save'),
          // labelColor: Colors.white,
        ),
        const SizedBox(
          width: 10,
        ),
      ],
      child: _buildChannelItemView(context),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
