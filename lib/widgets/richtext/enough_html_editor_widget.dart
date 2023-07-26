import 'package:colla_chat/provider/myself.dart';
import 'package:enough_html_editor/enough_html_editor.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';

///EnoughHtmlEditor的实现，用于简单的编辑，inappwebview实现
///应用于移动平台，最小高度200
class EnoughHtmlEditorWidget extends StatefulWidget {
  final double? height;
  final String? initialText;
  final Function(HtmlEditorApi controller)? onCreateController;

  const EnoughHtmlEditorWidget({
    Key? key,
    this.height,
    this.initialText,
    this.onCreateController,
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

  Widget _buildHtmlEditorControls() {
    if (controller == null) {
      return const PlatformProgressIndicator();
    } else {
      return SliverHeaderHtmlEditorControls(editorApi: controller);
    }
  }

  HtmlEditor _buildHtmlEditor() {
    return HtmlEditor(
      key: UniqueKey(),
      initialContent: widget.initialText ?? '',
      minHeight: 200,
      onCreated: (api) {
        controller = api;
        if (widget.initialText != null) {
          var html = widget.initialText!;
          controller!.setText(html);
        }
        if (widget.onCreateController != null) {
          widget.onCreateController!(controller!);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        color: myself.getBackgroundColor(context).withOpacity(0.6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHtmlEditorControls(),
            const SizedBox(
              height: 10.0,
            ),
            Expanded(
                child: SizedBox(
              height: widget.height,
              child: _buildHtmlEditor(),
            )),
          ],
        ));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
