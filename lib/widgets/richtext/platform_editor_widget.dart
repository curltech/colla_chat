import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/richtext/html_editor_widget.dart';
import 'package:colla_chat/widgets/richtext/html_light_widget.dart';
import 'package:colla_chat/widgets/richtext/html_rte_widget.dart';
import 'package:colla_chat/widgets/richtext/quill_editor_widget.dart';
import 'package:colla_chat/widgets/richtext/quill_html_editor_widget.dart';
import 'package:flutter/material.dart';

class PlatformEditorWidget extends StatefulWidget {
  final double height;
  final String? initialText;
  final Function(String? result, ChatMessageMimeType mimeType) onSubmit;

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
    if (platformParams.macos) {
      return QuillEditorWidget(
        height: widget.height,
        initialText: widget.initialText,
        onSubmit: widget.onSubmit,
      );
    }
    if (platformParams.mobile || platformParams.web) {
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
    }
    if (platformParams.windows) {
      return HtmlRteWidget(
        height: widget.height,
        initialText: widget.initialText,
        onSubmit: widget.onSubmit,
      );
    }
    return HtmlLightWidget(
      height: widget.height,
      initialText: widget.initialText,
      onSubmit: widget.onSubmit,
    );
  }
}
