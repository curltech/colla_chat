import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pro_image_editor/core/enums/editor_mode.dart';
import 'package:pro_image_editor/core/models/editor_callbacks/pro_image_editor_callbacks.dart';
import 'package:pro_image_editor/features/main_editor/main_editor.dart';

/// 图像编辑界面
class ImageEditorWidget extends StatelessWidget with TileDataMixin {
  ImageEditorWidget({
    super.key, required this.playlistController,
  });

  @override
  String get routeName => 'image_editor';

  @override
  IconData get iconData => Icons.image_outlined;

  @override
  String get title => 'ImageEditor';



  @override
  bool get withLeading => true;

  final PlaylistController playlistController;

  _buildImageEditor(BuildContext context) {
    return Obx(
      () {
        String? filename = playlistController.current?.filename;
        if (filename == null) {
          return nilBox;
        }
        return ProImageEditor.file(File(filename),
            callbacks: ProImageEditorCallbacks(
              onImageEditingComplete: (Uint8List bytes) async {
                String? name = await DialogUtil.showTextFormField(
                    title: 'Save as', content: 'Filename', tip: filename);
                if (name != null) {
                  await FileUtil.writeFileAsBytes(bytes, name);
                  DialogUtil.info(content: 'Save file:$name successfully');
                }
              },
              onCloseEditor: (EditorMode mode) {
                indexWidgetProvider.pop(context: context);
              },
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: title,
      helpPath: routeName,
      withLeading: true,
      child: _buildImageEditor(context),
    );
  }
}
