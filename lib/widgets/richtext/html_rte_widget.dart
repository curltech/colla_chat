import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/document_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rte/flutter_rte.dart';

///html_editor_enhanced一样的实现，用于移动和web，但是是用webview实现的
///所以可以用于其他除macos外的平台
class HtmlRteWidget extends StatefulWidget {
  final double height;
  final String? initialText;
  final ChatMessageMimeType mimeType;
  final Function(String? result, ChatMessageMimeType mimeType)? onSubmit;

  const HtmlRteWidget({
    Key? key,
    required this.height,
    this.initialText,
    this.mimeType = ChatMessageMimeType.html,
    this.onSubmit,
  }) : super(key: key);

  @override
  State createState() => _HtmlRteWidgetState();
}

class _HtmlRteWidgetState extends State<HtmlRteWidget> {
  late final HtmlEditorController controller;

  @override
  void initState() {
    super.initState();
    controller = HtmlEditorController();
    controller.editorOptions.decoration = BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: Colors.white, width: 2));
    if (widget.initialText != null) {
      var html = widget.initialText!;
      if (widget.mimeType == ChatMessageMimeType.json) {
        var deltaJson = JsonUtil.toJson(html);
        html = DocumentUtil.jsonToHtml(deltaJson);
      }
      controller.setInitialText(html);
    }
    _buildToolbarOptions();
  }

  HtmlToolbarOptions _buildToolbarOptions() {
    var customButtonGroups = [
      CustomButtonGroup(buttons: [
        CustomToolbarButton(
            icon: Icons.check,
            action: () async {
              if (widget.onSubmit != null) {
                String html = await controller.getText();
                widget.onSubmit!(html, ChatMessageMimeType.html);
              }
            },
            isSelected: false),
      ])
    ];
    var toolbarOptions = HtmlToolbarOptions(
        toolbarType: ToolbarType.nativeScrollable,
        backgroundColor: Colors.transparent,
        toolbarPosition: ToolbarPosition.aboveEditor,
        defaultToolbarButtons: const [
          VoiceToTextButtons(),
          OtherButtons(),
          FontButtons(),
          ColorButtons(),
          ParagraphButtons(),
          ListButtons(),
          InsertButtons(),
          OtherButtons()
        ],
        customButtonGroups: customButtonGroups);
    controller.toolbarOptions = toolbarOptions;

    return toolbarOptions;
  }

  Widget _buildHtmlRteEditor(BuildContext context) {
    HtmlEditor htmlRteEditor = HtmlEditor(
      controller: controller,
      height: 200,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      color: myself.getBackgroundColor(context).withOpacity(0.6),
      child: htmlRteEditor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildHtmlRteEditor(context);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
