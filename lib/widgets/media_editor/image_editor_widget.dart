import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/common/app_bar_adaptive_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pro_image_editor/core/enums/editor_mode.dart';
import 'package:pro_image_editor/core/models/editor_callbacks/pro_image_editor_callbacks.dart';
import 'package:pro_image_editor/features/main_editor/main_editor.dart';

/// 图像编辑界面，使用pro_image_editor
class ImageEditorWidget extends StatelessWidget with DataTileMixin {
  ImageEditorWidget({
    super.key,
  });

  @override
  String get routeName => 'image_editor';

  @override
  IconData get iconData => Icons.image_outlined;

  @override
  String get title => 'ImageEditor';

  @override
  bool get withLeading => true;

  final PlaylistController playlistController = PlaylistController();
  late final PlaylistWidget playlistWidget = PlaylistWidget(
    playlistController: playlistController,
  );

  Widget _buildImageEditor(BuildContext context) {
    Widget mediaView = Obx(
      () {
        String? filename = playlistController.current?.filename;
        if (filename == null) {
          return nilBox;
        }
        return ProImageEditor.file(File(filename),
            key: UniqueKey(),
            callbacks: ProImageEditorCallbacks(
                onImageEditingComplete: (Uint8List bytes) async {
                  bool? confirm = await DialogUtil.confirm(
                    context: context,
                    title: 'Save as',
                    content: filename,
                  );
                  if (confirm != null && confirm) {
                    await FileUtil.writeFileAsBytes(bytes, filename);
                    DialogUtil.info(
                        content: 'Save file:$filename successfully');
                  }
                },
                onCloseEditor: (EditorMode mode) {}));
      },
    );
    return Center(
      child: mediaView,
    );
  }

  List<Widget>? _buildRightWidgets(BuildContext context) {
    List<Widget> children = [
      IconButton(
        tooltip: AppLocalizations.t('More'),
        onPressed: () {
          playlistWidget.showActionCard(context);
        },
        icon: const Icon(Icons.more_horiz_outlined),
      ),
    ];

    return children;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarAdaptiveView(
      title: title,
      helpPath: routeName,
      withLeading: true,
      rightWidgets: _buildRightWidgets(context),
      main: playlistWidget,
      body: _buildImageEditor(context),
    );
  }
}
