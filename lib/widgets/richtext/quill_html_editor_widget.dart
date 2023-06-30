import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:flutter/material.dart';
import 'package:quill_html_editor/quill_html_editor.dart';

///quill_html_editor一样的实现，用于移动和web
class QuillHtmlEditorWidget extends StatefulWidget {
  final double height;
  final String? initialText;
  final ChatMessageMimeType mimeType;
  final bool withMultiMedia;
  final Function(String? result, ChatMessageMimeType mimeType)? onSubmit;

  const QuillHtmlEditorWidget({
    Key? key,
    required this.height,
    this.initialText,
    this.mimeType = ChatMessageMimeType.json,
    this.onSubmit,
    this.withMultiMedia = false,
  }) : super(key: key);

  @override
  State createState() => _QuillHtmlEditorWidgetState();
}

class _QuillHtmlEditorWidgetState extends State<QuillHtmlEditorWidget> {
  final QuillEditorController controller = QuillEditorController();

  @override
  void initState() {
    super.initState();

    ///初始化数据的是json和html格式则可以编辑
    if (widget.initialText != null) {
      if (widget.mimeType == ChatMessageMimeType.json) {
        var delta = JsonUtil.toJson(widget.initialText!);
        controller.setDelta(delta);
      }
      if (widget.mimeType == ChatMessageMimeType.html) {
        controller.setText(widget.initialText!);
      }
    }
  }

  Widget _buildQuillToolbar(BuildContext context) {
    List<ToolBarStyle> toolBarConfig = [];
    for (ToolBarStyle toolBarStyle in ToolBarStyle.values) {
      if (widget.withMultiMedia ||
          (toolBarStyle != ToolBarStyle.link &&
              toolBarStyle != ToolBarStyle.image &&
              toolBarStyle != ToolBarStyle.video)) {
        toolBarConfig.add(toolBarStyle);
      }
    }
    var customButtons = [
      Tooltip(
          message: AppLocalizations.t('Submit'),
          child: InkWell(
              onTap: () async {
                if (widget.onSubmit != null) {
                  String html = await controller.getText();
                  widget.onSubmit!(html, ChatMessageMimeType.html);

                  // var delta = await controller.getDelta();
                  // String deltaJson = JsonUtil.toJsonString(delta);
                  // widget.onSubmit!(deltaJson, ChatMessageMimeType.json);
                }
              },
              child: const Icon(
                Icons.check,
              ))),
    ];
    return ToolBar(
        toolBarColor: Colors.white,
        padding: const EdgeInsets.all(8),
        iconSize: 25,
        iconColor: Colors.black,
        activeIconColor: myself.primary,
        controller: controller,
        crossAxisAlignment: CrossAxisAlignment.start,
        toolBarConfig: toolBarConfig,
        customButtons: customButtons);
  }

  Widget _buildQuillHtmlEditor(BuildContext context) {
    Widget quillHtmlEditor = QuillHtmlEditor(
      controller: controller,
      isEnabled: true,
      minHeight: 200,
      hintTextAlign: TextAlign.start,
      backgroundColor: myself.getBackgroundColor(context).withOpacity(0.6),
    );
    var toolbar = _buildQuillToolbar(context);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            toolbar,
            const SizedBox(
              height: 10.0,
            ),
            Expanded(
              child: quillHtmlEditor,
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return _buildQuillHtmlEditor(context);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
