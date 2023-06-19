import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/tool/document_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rte/flutter_rte.dart';

///html_editor_enhanced一样的实现，用于移动和web，但是是用webview实现的
///所以可以用于其他
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
    controller = HtmlEditorController(
      toolbarOptions: _buildToolbarOptions(),
    );
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
    controller.callbacks.onChangeContent = (s) {};
  }

  HtmlToolbarOptions _buildToolbarOptions() {
    var toolbarOptions = HtmlToolbarOptions(
        toolbarType: ToolbarType.nativeScrollable,
        backgroundColor: Colors.transparent,
        toolbarPosition: ToolbarPosition.custom,
        customButtonGroups: [
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
          ]),
        ]);
    toolbarOptions.toolbarPosition = ToolbarPosition.aboveEditor;
    toolbarOptions.toolbarType = ToolbarType.nativeExpandable;
    toolbarOptions.initiallyExpanded = false;
    toolbarOptions.backgroundColor = Colors.white;

    return toolbarOptions;
  }

  Widget _buildHtmlRteEditor() {
    return HtmlEditor(
      controller: controller,
      height: 250,
    );
  }

  List<ActionData> _buildActionData() {
    List<ActionData> actionData = [];
    actionData.add(
      ActionData(label: 'Undo', icon: const Icon(Icons.undo)),
    );
    actionData.add(
      ActionData(label: 'Reset', icon: const Icon(Icons.clear)),
    );
    actionData.add(
      ActionData(label: 'Redo', icon: const Icon(Icons.redo)),
    );
    actionData.add(
      ActionData(label: 'Enable', icon: const Icon(Icons.comment_sharp)),
    );
    actionData.add(
      ActionData(label: 'Disable', icon: const Icon(Icons.comments_disabled)),
    );
    return actionData;
  }

  Future<void> _onAction(BuildContext context, int index, String name,
      {String? value}) async {
    switch (name) {
      case 'Undo':
        controller.undo();
        break;
      case 'Reset':
        controller.clear();
        break;
      case 'Redo':
        controller.redo();
        break;
      case 'Enable':
        controller.enable();
        break;
      case 'Disable':
        controller.disable();
        break;
      case 'InsertText':
        controller.insertText('');
        break;
      case 'InsertHtml':
        controller.insertHtml('');
        break;
      case 'InsertLink':
        controller.insertLink('', '', false);
        break;
      case 'InsertNetworkImage':
        break;
      default:
        break;
    }
  }

  Widget _buildCustomButton() {
    return Visibility(
        visible: true,
        child: Center(
            child: Card(
                child: DataActionCard(
                    onPressed: (int index, String label, {String? value}) {
                      _onAction(context, index, label, value: value);
                    },
                    showLabel: false,
                    showTooltip: false,
                    crossAxisCount: 4,
                    actions: _buildActionData(),
                    // height: 120,
                    //width: 320,
                    size: 20))));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          if (!kIsWeb) {
            controller.clearFocus();
          }
        },
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildHtmlRteEditor(),
            ],
          ),
        ));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
