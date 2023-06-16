import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quill_html_editor/quill_html_editor.dart';

///quill_html_editor一样的实现，用于移动和web
class QuillHtmlEditorWidget extends StatefulWidget {
  final double height;
  final String? initialText;
  final Function(String? result)? onSubmit;

  const QuillHtmlEditorWidget({
    Key? key,
    required this.height,
    this.initialText,
    this.onSubmit,
  }) : super(key: key);

  @override
  State createState() => _QuillHtmlEditorWidgetState();
}

class _QuillHtmlEditorWidgetState extends State<QuillHtmlEditorWidget> {
  String result = '';
  final QuillEditorController controller = QuillEditorController();

  @override
  void initState() {
    super.initState();
  }

  Widget _buildEditor() {
    return QuillHtmlEditor(
      text: "",
      hintText: 'Hint text goes here',
      controller: controller,
      isEnabled: true,
      minHeight: 500,
      hintTextAlign: TextAlign.start,
      padding: const EdgeInsets.only(left: 10, top: 10),
      hintTextPadding: const EdgeInsets.only(left: 20),
      backgroundColor: Colors.white,
      onFocusChanged: (hasFocus) => logger.i('has focus $hasFocus'),
      onTextChanged: (text) => logger.i('widget text change $text'),
      onEditorCreated: () async {
        await controller.setText('');
      },
      onEditorResized: (height) => logger.i('Editor resized $height'),
      onSelectionChanged: (sel) =>
          logger.i('index ${sel.index}, range ${sel.length}'),
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
        controller.enableEditor(true);
        break;
      case 'Disable':
        controller.enableEditor(false);
        break;
      case 'InsertText':
        controller.insertText('');
        break;
      case 'InsertHtml':
        controller.insertText('');
        break;
      case 'InsertNetworkImage':
        controller.embedImage('');
        break;
      case 'InsertNetworkVideo':
        controller.embedVideo('');
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
            controller.unFocus();
          }
        },
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildEditor(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildCustomButton(),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CommonAutoSizeText(result),
              ),
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
