import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:flutter/material.dart';
import 'package:quill_html_editor/quill_html_editor.dart';

///quill_html_editor一样的实现，用于移动和web
///缺省的最小高度200
class QuillHtmlEditorWidget extends StatefulWidget {
  final double? height;
  final String? initialText;
  final ChatMessageMimeType mimeType;
  final bool withMultiMedia;
  final bool base64;
  final Function(QuillEditorController controller)? onCreateController;

  const QuillHtmlEditorWidget({
    Key? key,
    this.height,
    this.initialText,
    this.mimeType = ChatMessageMimeType.json,
    this.onCreateController,
    this.withMultiMedia = true,
    this.base64 = true,
  }) : super(key: key);

  @override
  State createState() => _QuillHtmlEditorWidgetState();
}

class _QuillHtmlEditorWidgetState extends State<QuillHtmlEditorWidget> {
  final QuillEditorController controller = QuillEditorController();

  @override
  void initState() {
    super.initState();
    if (widget.onCreateController != null) {
      widget.onCreateController!(controller);
    }

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
    var customButtons = <Widget>[];
    return ToolBar.scroll(
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
      ensureVisible: true,
      hintTextAlign: TextAlign.start,
      hintText: '',
    );
    var toolbar = _buildQuillToolbar(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(
          height: 5.0,
        ),
        toolbar,
        Divider(
          height: 1.0,
          thickness: 1.0,
          color: myself.primary,
        ),
        Expanded(
            child: SizedBox(
          height: widget.height,
          child: quillHtmlEditor,
        )),
      ],
    );
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
