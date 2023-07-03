import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/channel/channel_chat_message_controller.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/richtext/platform_editor_widget.dart';
import 'package:flutter/material.dart';

///自己发布频道消息编辑页面
class PublishChannelItemWidget extends StatefulWidget with TileDataMixin {
  PublishChannelItemWidget({Key? key}) : super(key: key);

  @override
  State createState() => _PublishChannelItemWidgetState();

  @override
  String get routeName => 'publish_channel_item';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.edit;

  @override
  String get title => 'Publish Channel Item';
}

class _PublishChannelItemWidgetState extends State<PublishChannelItemWidget> {
  final TextEditingController textEditingController = TextEditingController();
  ValueNotifier<String?> thumbnail = ValueNotifier<String?>(null);
  ValueNotifier<String?> documentText = ValueNotifier<String?>(null);
  ChatMessageMimeType mimeType = ChatMessageMimeType.html;
  SwiperController controller = SwiperController();

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
  Future<void> _onSubmit(String? result, ChatMessageMimeType mimeType) async {
    documentText.value = result;
    this.mimeType = mimeType;
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

  Widget _buildChannelItemView(BuildContext context) {
    Widget titleWidget = _buildTitleTextField(context);
    Widget view = Column(children: [
      titleWidget,
      PlatformEditorWidget(
        height:
            appDataProvider.portraitSize.height - appDataProvider.toolbarHeight,
        onSubmit: _onSubmit,
      )
    ]);

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
          icon: const Icon(Icons.preview),
          onPressed: () {
            indexWidgetProvider.push('channel_message_view');
          },
          tooltip: AppLocalizations.t('Preview'),
        ),
        IconButton(
          icon: const Icon(Icons.publish),
          onPressed: () async {
            ChatMessage? chatMessage = myChannelChatMessageController.current;
            if (chatMessage != null) {
              await myChannelChatMessageController
                  .publish(chatMessage.messageId!);
              if (mounted) {
                DialogUtil.info(context,
                    content:
                        AppLocalizations.t('Publish channel successfully'));
              }
            }
          },
          tooltip: AppLocalizations.t('Publish'),
        )
      ],
      child: _buildChannelItemView(context),
    );
  }

  @override
  void dispose() {
    textEditingController.dispose();
    controller.dispose();
    super.dispose();
  }
}
