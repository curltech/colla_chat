import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/richtext/html_editor_widget.dart';
import 'package:colla_chat/widgets/richtext/html_rte_widget.dart';
import 'package:colla_chat/widgets/richtext/quill_editor_widget.dart';
import 'package:colla_chat/widgets/richtext/quill_html_editor_widget.dart';
import 'package:flutter/material.dart';

///要么加expanded，要么设置height，否则使用缺省的高度
class PlatformEditorWidget extends StatefulWidget {
  final double? height;
  final String? initialText;
  Function(String? content, ChatMessageMimeType mimeType)? onSubmit;
  Function(String? content, ChatMessageMimeType mimeType)? onPreview;

  PlatformEditorWidget({
    Key? key,
    this.initialText,
    this.height,
    this.onSubmit,
    this.onPreview,
  }) : super(key: key);

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
    if (platformParams.desktop) {
      return KeepAliveWrapper(
          child: QuillEditorWidget(
        height: widget.height,
        initialText: widget.initialText,
        onSubmit: widget.onSubmit,
        onPreview: widget.onPreview,
      ));
    }
    if (platformParams.mobile || platformParams.web) {
      return KeepAliveWrapper(
          child: QuillHtmlEditorWidget(
        height: widget.height,
        initialText: widget.initialText,
        onSubmit: widget.onSubmit,
            onPreview: widget.onPreview,
      ));
    }
    if (platformParams.windows) {
      return KeepAliveWrapper(
          child: HtmlRteWidget(
        height: widget.height,
        initialText: widget.initialText,
        onSubmit: widget.onSubmit,
            onPreview: widget.onPreview,
      ));
    }
    return KeepAliveWrapper(
        child: HtmlEditorWidget(
      height: widget.height,
      initialText: widget.initialText,
      onSubmit: widget.onSubmit,
          onPreview: widget.onPreview,
    ));
  }
}
