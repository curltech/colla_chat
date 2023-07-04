import 'dart:async';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/document_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/smart_dialog_util.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';

///html_editor_enhanced实现，用于移动和web
///缺省的高度400
class HtmlEditorWidget extends StatefulWidget {
  final double? height;
  final String? initialText;
  final ChatMessageMimeType mimeType;
  final bool withMultiMedia;
  final Function(String result, ChatMessageMimeType mimeType)? onSubmit;
  final Function(String content, ChatMessageMimeType mimeType)? onPreview;

  const HtmlEditorWidget({
    Key? key,
    this.height,
    this.initialText,
    this.onSubmit,
    this.onPreview,
    this.mimeType = ChatMessageMimeType.html,
    this.withMultiMedia = false,
  }) : super(key: key);

  @override
  State createState() => _HtmlEditorWidgetState();
}

class _HtmlEditorWidgetState extends State<HtmlEditorWidget> {
  final HtmlEditorController controller = HtmlEditorController();

  @override
  void initState() {
    super.initState();

    ///初始化数据的是json和html格式则可以编辑
    if (widget.initialText != null) {
      if (widget.mimeType == ChatMessageMimeType.html) {
        controller.setText(widget.initialText!);
      }
    }
  }

  HtmlToolbarOptions _buildHtmlToolbarOptions() {
    var customToolbarButtons = [
      Tooltip(
          message: AppLocalizations.t('Preview'),
          child: InkWell(
            onTap: () async {
              if (widget.onPreview != null) {
                String html = await controller.getText();
                widget.onPreview!(html, ChatMessageMimeType.html);
              }
            },
            child: const Icon(Icons.preview),
          )),
      Tooltip(
          message: AppLocalizations.t('Submit'),
          child: InkWell(
            onTap: () async {
              if (widget.onSubmit != null) {
                String html = await controller.getText();
                widget.onSubmit!(html, ChatMessageMimeType.html);
              }
            },
            child: const Icon(Icons.check),
          )),
    ];
    return HtmlToolbarOptions(
      toolbarPosition: ToolbarPosition.aboveEditor,
      toolbarType: ToolbarType.nativeScrollable,
      initiallyExpanded: true,
      defaultToolbarButtons: [
        const StyleButtons(),
        const FontSettingButtons(fontSizeUnit: true),
        const FontButtons(clearAll: true),
        const ColorButtons(),
        const ListButtons(listStyles: true),
        const ParagraphButtons(
            textDirection: true, lineHeight: true, caseConverter: true),
        InsertButtons(
            video: widget.withMultiMedia,
            audio: widget.withMultiMedia,
            table: true,
            hr: true,
            otherFile: widget.withMultiMedia),
      ],
      toolbarItemHeight: 36,
      customToolbarButtons: customToolbarButtons,
      gridViewHorizontalSpacing: 1,
      gridViewVerticalSpacing: 1,
      mediaLinkInsertInterceptor: (String url, InsertFileType type) {
        logger.i(url);
        return true;
      },
      mediaUploadInterceptor: (PlatformFile file, InsertFileType type) async {
        logger.i(file.name); //filename
        logger.i(file.size); //size in bytes
        logger.i(file.extension); //file extension (eg jpeg or mp4)
        return true;
      },
    );
  }

  Widget _buildHtmlEditor(BuildContext context) {
    OtherOptions otherOptions = const OtherOptions();
    if (widget.height != null) {
      otherOptions = OtherOptions(height: widget.height!);
    }
    return HtmlEditor(
      controller: controller,
      htmlEditorOptions: HtmlEditorOptions(
        shouldEnsureVisible: true,
        initialText: widget.initialText,
      ),
      htmlToolbarOptions: _buildHtmlToolbarOptions(),
      otherOptions: otherOptions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      color: myself.getBackgroundColor(context).withOpacity(0.6),
      child: _buildHtmlEditor(context),
    );
  }
}
