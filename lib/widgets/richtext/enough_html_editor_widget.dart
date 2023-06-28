import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:enough_html_editor/enough_html_editor.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

///EnoughHtmlEditor的实现，用于简单的编辑，inappwebview实现
///应用于移动平台
class EnoughHtmlEditorWidget extends StatefulWidget {
  final double height;
  final String? initialText;
  final ChatMessageMimeType mimeType;
  final Function(String? result, ChatMessageMimeType mimeType)? onSubmit;

  const EnoughHtmlEditorWidget({
    Key? key,
    required this.height,
    this.initialText,
    this.mimeType = ChatMessageMimeType.html,
    this.onSubmit,
  }) : super(key: key);

  @override
  State createState() => _EnoughHtmlEditorWidgetState();
}

class _EnoughHtmlEditorWidgetState extends State<EnoughHtmlEditorWidget> {
  HtmlEditorApi? controller;

  @override
  void initState() {
    super.initState();
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
        break;
      case 'Reset':
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
      child: Column(
        children: [
          if (controller == null) ...{
            const PlatformProgressIndicator(),
          } else ...{
            SliverHeaderHtmlEditorControls(
              editorApi: controller,
              suffix: Tooltip(
                  message: AppLocalizations.t('Submit'),
                  child: InkWell(
                    onTap: () async {
                      if (widget.onSubmit != null) {
                        String html = await controller!.getFullHtml();
                        widget.onSubmit!(html, ChatMessageMimeType.html);
                      }
                    },
                    child: const Icon(
                      Icons.check,
                    ),
                  )),
            ),
          },
          HtmlEditor(
            initialContent: widget.initialText!,
            minHeight: 200,
            onCreated: (api) {
              controller = api;
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
