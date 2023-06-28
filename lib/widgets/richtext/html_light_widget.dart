import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:light_html_editor/editor.dart';
import 'package:light_html_editor/html_editor_controller.dart';

///light_html_editor的实现，用于简单的编辑，flutter_html实现
///应用于所有的平台
class HtmlLightWidget extends StatefulWidget {
  final double height;
  final String? initialText;
  final ChatMessageMimeType mimeType;
  final Function(String? result, ChatMessageMimeType mimeType)? onSubmit;

  const HtmlLightWidget({
    Key? key,
    required this.height,
    this.initialText,
    this.mimeType = ChatMessageMimeType.html,
    this.onSubmit,
  }) : super(key: key);

  @override
  State createState() => _HtmlLightWidgetState();
}

class _HtmlLightWidgetState extends State<HtmlLightWidget> {
  late final HtmlEditorController controller;

  @override
  void initState() {
    super.initState();
    controller = HtmlEditorController(text: widget.initialText!);
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
    return SizedBox(
      width: 400,
      child: RichTextEditor(
        initialValue: widget.initialText,
        alwaysShowButtons: true,
        controller: HtmlEditorController(),
        additionalActionButtons: const <Widget>[],
        onChanged: (String html) {},
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
