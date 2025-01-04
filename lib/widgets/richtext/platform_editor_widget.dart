import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/document_util.dart';
import 'package:colla_chat/widgets/richtext/html_editor_widget.dart';
import 'package:colla_chat/widgets/richtext/quill_editor_widget.dart';
import 'package:colla_chat/widgets/richtext/quill_html_editor_widget.dart';
import 'package:dart_quill_delta/src/delta/delta.dart';
import 'package:enough_html_editor/enough_html_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:quill_html_editor_v2/quill_html_editor_v2.dart';

class PlatformEditorController with ChangeNotifier {
  dynamic originalController;
  ChatMessageMimeType mimeType = ChatMessageMimeType.html;

  Future<String?> get content async {
    if (originalController is QuillController) {
      QuillController controller = originalController as QuillController;
      Delta delta = controller.document.toDelta();
      return DocumentUtil.deltaToJson(delta);
    } else if (originalController is QuillEditorController) {
      QuillEditorController controller =
          originalController as QuillEditorController;
      return await controller.getText();
    } else if (originalController is HtmlEditorController) {
      HtmlEditorController controller =
          originalController as HtmlEditorController;
      return await controller.getText();
    } else if (originalController is HtmlEditorApi) {
      HtmlEditorApi controller = originalController as HtmlEditorApi;
      return await controller.getText();
    }
    return null;
  }

  Future<String?> get html async {
    if (originalController is QuillController) {
      QuillController controller = originalController as QuillController;
      Delta delta = controller.document.toDelta();
      return DocumentUtil.deltaToHtml(delta);
    } else if (originalController is QuillEditorController) {
      QuillEditorController controller =
          originalController as QuillEditorController;
      return await controller.getText();
    } else if (originalController is HtmlEditorController) {
      HtmlEditorController controller =
          originalController as HtmlEditorController;
      return await controller.getText();
    } else if (originalController is HtmlEditorApi) {
      HtmlEditorApi controller = originalController as HtmlEditorApi;
      return await controller.getFullHtml();
    }
    return null;
  }
}

///要么加expanded，要么设置height，否则使用缺省的高度
class PlatformEditorWidget extends StatefulWidget {
  final double? height;
  final String? initialText;
  final PlatformEditorController platformEditorController;

  const PlatformEditorWidget({
    super.key,
    this.initialText,
    this.height,
    required this.platformEditorController,
  });

  @override
  State createState() => _PlatformEditorWidgetState();
}

class _PlatformEditorWidgetState extends State<PlatformEditorWidget> {
  @override
  void initState() {
    super.initState();
  }

  _onCreateController(dynamic controller) {
    widget.platformEditorController.originalController = controller;
  }

  @override
  Widget build(BuildContext context) {
    Widget editor = HtmlEditorWidget(
      height: widget.height,
      initialText: widget.initialText,
      onCreateController: _onCreateController,
    );
    if (platformParams.desktop) {
      widget.platformEditorController.mimeType = ChatMessageMimeType.json;
      editor = QuillEditorWidget(
        height: widget.height,
        initialText: widget.initialText,
        onCreateController: _onCreateController,
      );
    } else if (platformParams.mobile || platformParams.web) {
      editor = QuillHtmlEditorWidget(
        height: widget.height,
        initialText: widget.initialText,
        mimeType: ChatMessageMimeType.html,
        onCreateController: _onCreateController,
      );
    }
    return editor;
  }
}
