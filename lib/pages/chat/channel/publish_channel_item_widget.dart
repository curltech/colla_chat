import 'dart:typed_data';

import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/channel/channel_chat_message_controller.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/tool/asset_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/richtext/html_editor_widget.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/src/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

///自己发布频道消息编辑页面
class PublishChannelItemWidget extends StatefulWidget with TileDataMixin {
  ChatMessage? chatMessage;

  PublishChannelItemWidget({Key? key, this.chatMessage}) : super(key: key);

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
  ValueNotifier<List<int>?> thumbnail = ValueNotifier<List<int>?>(null);
  String? html;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _onSubmit(String? result) async {
    html = result!;
  }

  Future<void> _save() async {
    String title = textEditingController.text;
    if (StringUtil.isEmpty(title)) {
      DialogUtil.error(context, content: AppLocalizations.t('Must be title'));
      return;
    }
    if (StringUtil.isEmpty(html)) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must be html content'));
      return;
    }
    var chatMessage = await myChannelChatMessageController
        .buildChannelChatMessage(title, html!, thumbnail.value);
    if (widget.chatMessage != null) {
      chatMessage.id = widget.chatMessage!.id;
      chatMessage.messageId = widget.chatMessage!.messageId;
    }
    await chatMessageService.store(chatMessage);
    widget.chatMessage = chatMessage;
  }

  Widget _buildTextField(BuildContext context) {
    var textFormField = SimpleWidgetUtil.buildTextFormField(
      controller: textEditingController,
      labelText: AppLocalizations.t('title'),
    );

    return textFormField;
  }

  Future<void> _pickThumbnail(
    BuildContext context,
  ) async {
    if (platformParams.desktop) {
      List<XFile> xfiles = await FileUtil.pickFiles(type: FileType.image);
      if (xfiles.isNotEmpty) {
        thumbnail.value = await xfiles[0].readAsBytes();
      }
    } else if (platformParams.mobile) {
      List<AssetEntity>? assets = await AssetUtil.pickAssets(context);
      if (assets != null && assets.isNotEmpty) {
        thumbnail.value = await assets[0].originBytes;
      }
    }
  }

  Future<void> _pickHtml(
    BuildContext context,
  ) async {
    if (platformParams.desktop) {
      List<XFile> xfiles = await FileUtil.pickFiles(type: FileType.any);
      if (xfiles.isNotEmpty) {
        html = await xfiles[0].readAsString();
      }
    } else if (platformParams.mobile) {
      List<AssetEntity>? assets = await AssetUtil.pickAssets(context);
      if (assets != null && assets.isNotEmpty) {
        var bytes = await assets[0].originBytes;
        html = String.fromCharCodes(bytes!);
      }
    }
  }

  Widget _buildActionWidget(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 15.0),
        child: Column(children: [
          _buildTextField(context),
          const SizedBox(
            height: 5.0,
          ),
          ValueListenableBuilder(
              valueListenable: thumbnail,
              builder: (BuildContext context, List<int>? value, Widget? child) {
                Widget? trailing;
                if (value != null) {
                  trailing =
                      ImageUtil.buildMemoryImageWidget(value as Uint8List);
                }
                return ListTile(
                    leading: Icon(
                      Icons.image_aspect_ratio,
                      color: myself.primary,
                    ),
                    title: Text(AppLocalizations.t('thumbnail')),
                    trailing: trailing,
                    onTap: () async {
                      await _pickThumbnail(context);
                    });
              }),
          ListTile(
              title: Text(AppLocalizations.t('Pick html file')),
              leading: Icon(
                Icons.file_open,
                color: myself.primary,
              ),
              onTap: () async {
                await _pickHtml(context);
              }),
          const SizedBox(
            height: 25.0,
          ),
          ButtonBar(children: [
            TextButton(
                style: SimpleWidgetUtil.buildButtonStyle(
                    backgroundColor: myself.primary),
                onPressed: () {
                  _save();
                },
                child: Text(AppLocalizations.t('Save'))),
            TextButton(
                style: SimpleWidgetUtil.buildButtonStyle(
                    backgroundColor: myself.primary),
                onPressed: () {
                  if (widget.chatMessage != null) {
                    myChannelChatMessageController
                        .publish(widget.chatMessage!.messageId!);
                  }
                },
                child: Text(AppLocalizations.t('Publish')))
          ]),
        ]));
  }

  Widget _buildChannelItemView(BuildContext context) {
    Widget view = _buildActionWidget(context);
    if (platformParams.mobile) {
      view = Swiper(
        controller: SwiperController(),
        itemCount: 2,
        index: 0,
        itemBuilder: (BuildContext context, int index) {
          if (index == 1) {
            view = HtmlEditorWidget(
              height: appDataProvider.actualSize.height -
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
        //   color: Colors.white,
        //   activeSize: 15,)
        // ),
      );
    }
    return view;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      centerTitle: false,
      withLeading: true,
      title: widget.title,
      child: _buildChannelItemView(context),
    );
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }
}
