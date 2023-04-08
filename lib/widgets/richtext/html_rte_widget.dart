import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rte/flutter_rte.dart';

class HtmlRteWidget extends StatefulWidget {
  const HtmlRteWidget({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State createState() => _HtmlRteWidgetState();
}

class _HtmlRteWidgetState extends State<HtmlRteWidget> {
  String result = '';
  final HtmlEditorController controller = HtmlEditorController();

  @override
  void initState() {
    super.initState();
  }

  Widget _buildEditor() {
    return HtmlEditor(
      controller: controller,
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
}
