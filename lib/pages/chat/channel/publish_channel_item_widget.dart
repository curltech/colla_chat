import 'dart:typed_data';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/channel/channel_chat_message_controller.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/asset_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
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
  ValueNotifier<List<int>?> thumbnail = ValueNotifier<List<int>?>(null);

  @override
  void initState() {
    super.initState();
  }

  Future<void> _store(String? result) async {
    await myChannelChatMessageController.store(
        textEditingController.text, result!, thumbnail.value);
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

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      centerTitle: false,
      withLeading: true,
      title: widget.title,
      child: Column(children: [
        _buildTextField(context),
        ValueListenableBuilder(
            valueListenable: thumbnail,
            builder: (BuildContext context, List<int>? value, Widget? child) {
              Widget? trailing;
              if (value != null) {
                trailing =
                    ImageUtil.buildMemoryImageWidget(value! as Uint8List);
              }
              return ListTile(
                  title: Text(AppLocalizations.t('thumbnail')),
                  trailing: trailing,
                  onTap: () async {
                    await _pickThumbnail(context);
                  });
            }),
        HtmlEditorWidget(
          height:
              appDataProvider.actualSize.height - appDataProvider.toolbarHeight,
          onSave: _store,
        )
      ]),
    );
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }
}
