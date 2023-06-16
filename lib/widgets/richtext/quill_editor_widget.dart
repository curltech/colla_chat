import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

///quill_editor一样的实现，用于IOS,LINUX,MACOS,WINDOWS
class QuillEditorWidget extends StatefulWidget {
  final double height;
  final String? initialText;
  final Function(String? result)? onSubmit;

  const QuillEditorWidget({
    Key? key,
    required this.height,
    this.initialText,
    this.onSubmit,
  }) : super(key: key);

  @override
  State createState() => _QuillEditorWidgetState();
}

class _QuillEditorWidgetState extends State<QuillEditorWidget> {
  String result = '';
  final QuillController controller = QuillController.basic();

  @override
  void initState() {
    super.initState();
  }

  Widget _buildEditor() {
    return QuillEditor.basic(
      controller: controller,
      locale: myself.locale,
      readOnly: false, // true for view only mode
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
        child: Card(
            elevation: 0.0,
            margin: EdgeInsets.zero,
            shape: const ContinuousRectangleBorder(),
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
            )));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
