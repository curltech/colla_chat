import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/richtext/html_editor_widget.dart';
import 'package:colla_chat/widgets/richtext/html_rte_widget.dart';
import 'package:colla_chat/widgets/richtext/quill_editor_widget.dart';
import 'package:colla_chat/widgets/richtext/quill_html_editor_widget.dart';
import 'package:flutter/material.dart';

class PlatformEditorWidget extends StatefulWidget {
  final double height;
  final String? initialText;
  final Function(String? result) onSubmit;

  const PlatformEditorWidget(
      {Key? key,
      this.initialText,
      required this.height,
      required this.onSubmit})
      : super(key: key);

  @override
  State createState() => _PlatformEditorWidgetState();
}

class _PlatformEditorWidgetState extends State<PlatformEditorWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (platformParams.mobile || platformParams.web || platformParams.windows) {
      return QuillHtmlEditorWidget(
        height: widget.height,
        initialText: widget.initialText,
        onSubmit: widget.onSubmit,
      );
      return HtmlEditorWidget(
        height: widget.height,
        initialText: widget.initialText,
        onSubmit: widget.onSubmit,
      );
      return HtmlRteWidget(
        height: widget.height,
        initialText: widget.initialText,
        onSubmit: widget.onSubmit,
      );
    }
    return QuillEditorWidget(
      height: widget.height,
      initialText: widget.initialText,
      onSubmit: widget.onSubmit,
    );
  }
}
