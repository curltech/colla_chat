import 'dart:typed_data';

import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/channel/channel_chat_message_controller.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/tool/asset_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/richtext/platform_editor_widget.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/src/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

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
  ValueNotifier<String?> html = ValueNotifier<String?>(null);
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
      html.value = CryptoUtil.utf8ToString(bytes);
    }
  }

  Future<void> _onSubmit(String? result) async {
    html.value = result!;
  }

  Future<void> _save() async {
    String title = textEditingController.text;
    if (StringUtil.isEmpty(title)) {
      DialogUtil.error(context, content: AppLocalizations.t('Must be title'));
      return;
    }
    if (StringUtil.isEmpty(html.value)) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must be html content'));
      return;
    }
    ChatMessage? chatMessage = myChannelChatMessageController.current;
    if (chatMessage != null) {
      chatMessage.title = title;
      chatMessage.content = chatMessageService.processContent(html.value!);
      chatMessage.thumbnail = thumbnail.value;
    } else {
      chatMessage = await myChannelChatMessageController
          .buildChannelChatMessage(title, html.value!, thumbnail.value);
      myChannelChatMessageController.current = chatMessage;
    }
    await chatMessageService.store(chatMessage);
    if (mounted) {
      DialogUtil.info(context,
          content: AppLocalizations.t('Save html file successfully'));
    }
  }

  Widget _buildTextField(BuildContext context) {
    var textFormField = CommonAutoSizeTextFormField(
      controller: textEditingController,
      labelText: AppLocalizations.t('Title'),
    );

    return textFormField;
  }

  Future<void> _pickThumbnail(
    BuildContext context,
  ) async {
    if (platformParams.desktop) {
      List<XFile> xfiles = await FileUtil.pickFiles(type: FileType.image);
      if (xfiles.isNotEmpty) {
        var data = await xfiles[0].readAsBytes();
        thumbnail.value = CryptoUtil.encodeBase64(data);
      }
    } else if (platformParams.mobile) {
      List<AssetEntity>? assets = await AssetUtil.pickAssets(context);
      if (assets != null && assets.isNotEmpty) {
        var data = await assets[0].originBytes;
        thumbnail.value = CryptoUtil.encodeBase64(data!);
      }
    }
  }

  Future<void> _pickHtml(
    BuildContext context,
  ) async {
    if (platformParams.desktop) {
      List<XFile> xfiles = await FileUtil.pickFiles(type: FileType.any);
      if (xfiles.isNotEmpty) {
        Uint8List bytes = await xfiles[0].readAsBytes();
        html.value = CryptoUtil.utf8ToString(bytes);
      }
    } else if (platformParams.mobile) {
      List<AssetEntity>? assets = await AssetUtil.pickAssets(context);
      if (assets != null && assets.isNotEmpty) {
        Uint8List? bytes = await assets[0].originBytes;
        html.value = CryptoUtil.utf8ToString(bytes!);
      }
    }
  }

  Widget _buildActionWidget(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 15.0),
        child: Column(children: [
          const SizedBox(
            height: 15.0,
          ),
          _buildTextField(context),
          const SizedBox(
            height: 5.0,
          ),
          ValueListenableBuilder(
              valueListenable: thumbnail,
              builder: (BuildContext context, String? value, Widget? child) {
                Widget? trailing;
                if (value != null) {
                  trailing = ImageUtil.buildMemoryImageWidget(
                      CryptoUtil.decodeBase64(value),
                      height: AppImageSize.mdSize,
                      width: AppImageSize.mdSize);
                }
                return ListTile(
                    leading: Icon(
                      Icons.image_aspect_ratio,
                      color: myself.primary,
                    ),
                    title: CommonAutoSizeText(AppLocalizations.t('thumbnail')),
                    trailing: trailing,
                    onTap: () async {
                      await _pickThumbnail(context);
                    });
              }),
          ValueListenableBuilder(
              valueListenable: html,
              builder: (BuildContext context, String? value, Widget? child) {
                return ListTile(
                    title: CommonAutoSizeText(
                        AppLocalizations.t('Pick html file')),
                    leading: Icon(
                      Icons.file_open,
                      color: myself.primary,
                    ),
                    trailing: html.value != null
                        ? Icon(
                            Icons.check_circle,
                            color: myself.primary,
                          )
                        : null,
                    onTap: () async {
                      await _pickHtml(context);
                    });
              }),
          const SizedBox(
            height: 25.0,
          ),
          ButtonBar(children: [
            TextButton(
                style: StyleUtil.buildButtonStyle(),
                onPressed: () {
                  indexWidgetProvider.push('channel_message_view');
                },
                child: CommonAutoSizeText(AppLocalizations.t('View'))),
            TextButton(
                style: StyleUtil.buildButtonStyle(),
                onPressed: () {
                  _save();
                },
                child: CommonAutoSizeText(AppLocalizations.t('Save'))),
            TextButton(
                style:
                    StyleUtil.buildButtonStyle(backgroundColor: myself.primary),
                onPressed: () async {
                  ChatMessage? chatMessage =
                      myChannelChatMessageController.current;
                  if (chatMessage != null) {
                    await myChannelChatMessageController
                        .publish(chatMessage.messageId!);
                    if (mounted) {
                      DialogUtil.info(context,
                          content: AppLocalizations.t(
                              'Publish channel successfully'));
                    }
                  }
                },
                child: CommonAutoSizeText(AppLocalizations.t('Publish')))
          ]),
        ]));
  }

  Widget _buildChannelItemView(BuildContext context) {
    Widget view = _buildActionWidget(context);
    Widget swiper = Swiper(
      controller: controller,
      itemCount: 2,
      index: 0,
      itemBuilder: (BuildContext context, int index) {
        if (index == 1) {
          return PlatformEditorWidget(
            height: appDataProvider.portraitSize.height -
                appDataProvider.toolbarHeight,
            onSubmit: _onSubmit,
          );
        }
        return view;
      },
      onIndexChanged: (int index) {
        logger.i('changed to index $index');
      },
      // pagination: SwiperPagination(
      //     builder: DotSwiperPaginationBuilder(
      //   activeColor: myself.primary,
      //   color: myself.secondary,
      //   activeSize: 15,
      // )),
    );
    return swiper;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      centerTitle: false,
      withLeading: true,
      title: widget.title,
      rightWidgets: [
        IconButton(
            onPressed: () {
              controller.next();
            },
            icon: const Icon(Icons.more_horiz_outlined))
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
