import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/pages/chat/me/media/ffmpeg_media_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/models/editor_callbacks/pro_image_editor_callbacks.dart';
import 'package:pro_image_editor/modules/main_editor/main_editor.dart';

class ImageEditorWidget extends StatefulWidget with TileDataMixin {
  ImageEditorWidget({
    super.key,
  });

  @override
  State createState() => _ImageEditorWidgetState();

  @override
  String get routeName => 'image_editor';

  @override
  IconData get iconData => Icons.image_outlined;

  @override
  String get title => 'ImageEditor';

  @override
  bool get withLeading => true;
}

class _ImageEditorWidgetState extends State<ImageEditorWidget> {
  @override
  void initState() {
    super.initState();
    mediaFileController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  _buildImageEditor(BuildContext context) {
    return ProImageEditor.file(File(mediaFileController.current!),
        callbacks: ProImageEditorCallbacks(
          onImageEditingComplete: (Uint8List bytes) async {},
          onCloseEditor: () {
            indexWidgetProvider.pop(context: context);
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: widget.title,
      withLeading: true,
      child: _buildImageEditor(context),
    );
  }

  @override
  void dispose() {
    mediaFileController.removeListener(_update);
    super.dispose();
  }
}
