import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/channel/channel_chat_message_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/document_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
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
  final TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<String?> _findContent() async {
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

    return null;
  }

  _onPreview(String? content, ChatMessageMimeType mimeType) {
    if (mimeType == ChatMessageMimeType.html) {
      indexWidgetProvider.push('html_preview');
      htmlPreviewController.title = textEditingController.text;
      htmlPreviewController.html = content;
    }
  }

  ///编辑器提交表示暂存，原生的格式，json或者html
  Future<void> _onSubmit(String? content, ChatMessageMimeType mimeType) async {
    await _save(content, mimeType);
  }

  ///保存到数据库为草案，采用原生的可编辑模式，发布后才转换成统一的html格式，便不可更改
  Future<void> _save(String? content, ChatMessageMimeType mimeType) async {
    String title = textEditingController.text;
    if (StringUtil.isEmpty(title)) {
      DialogUtil.error(context, content: AppLocalizations.t('Must have title'));
      return;
    }
    if (StringUtil.isEmpty(content)) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must have content'));
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
          DialogUtil.info(context,
              content: 'Document already was published, can not be updated');
        }
        return;
      }
    } else {
      chatMessage = await myChannelChatMessageController
          .buildChannelChatMessage(title, content!, thumbnail.value);
      myChannelChatMessageController.current = chatMessage;
      newDocument = true;
    }
    chatMessage.mimeType = mimeType.name;
    await chatMessageService.store(chatMessage);
    if (newDocument) {
      myChannelChatMessageController.add(chatMessage);
    }
    if (mounted) {
      DialogUtil.info(context,
          content: AppLocalizations.t('Save draft content successfully'));
    }
  }

  ///将编辑的内容正式发布，统一采用html格式保存和发送，原先保存的草案要转换格式，更新状态
  _publish() async {
    ChatMessage? chatMessage = myChannelChatMessageController.current;
    if (chatMessage == null) {
      return;
    }
    String? mimeType = chatMessage.mimeType;
    if (mimeType == ChatMessageMimeType.json.name) {
      var bytes = await messageAttachmentService.findContent(
          chatMessage.messageId!, chatMessage.title!);
      if (bytes != null) {
        String json = CryptoUtil.utf8ToString(bytes);
        var deltaJson = JsonUtil.toJson(json);
        var html = DocumentUtil.jsonToHtml(deltaJson);
        chatMessage.mimeType = ChatMessageMimeType.html.name;
        chatMessage.content = chatMessageService.processContent(html);
      }
      chatMessage.status = MessageStatus.published.name;
      chatMessage.sendTime = DateUtil.currentDate();
      await chatMessageService.store(chatMessage);
    } else if (mimeType == ChatMessageMimeType.html.name) {
      await myChannelChatMessageController.publish(chatMessage.messageId!);
    }

    if (mounted) {
      DialogUtil.info(context,
          content: AppLocalizations.t('Publish document successfully'));
    }
  }

  Widget _buildTitleTextField(BuildContext context) {
    var textFormField = CommonAutoSizeTextFormField(
      controller: textEditingController,
      labelText: AppLocalizations.t('Title'),
    );

    return textFormField;
  }

  Widget _buildChannelItemView(BuildContext context) {
    Widget titleWidget = Container(
        padding: const EdgeInsets.all(10.0),
        child: _buildTitleTextField(context));
    Widget view = FutureBuilder(
        future: _findContent(),
        builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return LoadingUtil.buildLoadingIndicator();
          }
          String? content = snapshot.data;
          return Column(children: [
            titleWidget,
            Expanded(
                child: KeepAliveWrapper(
                    child: PlatformEditorWidget(
              initialText: content,
              onPreview: _onPreview,
              onSubmit: _onSubmit,
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
    super.dispose();
  }
}
