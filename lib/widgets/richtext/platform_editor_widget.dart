import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/document_util.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/richtext/html_editor_widget.dart';
import 'package:colla_chat/widgets/richtext/html_rte_widget.dart';
import 'package:colla_chat/widgets/richtext/quill_editor_widget.dart';
import 'package:colla_chat/widgets/richtext/quill_html_editor_widget.dart';
import 'package:enough_html_editor/enough_html_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:quill_html_editor/quill_html_editor.dart';
import 'package:flutter_rte/flutter_rte.dart' as rte;

class PlatformEditorController with ChangeNotifier {
  dynamic _originalController;
  ChatMessageMimeType? mimeType;

  dynamic get originalController {
    return _originalController;
  }

  set originalController(dynamic originalController) {
    this.originalController = originalController;
    if (_originalController is QuillController) {
      mimeType = ChatMessageMimeType.json;
    } else if (_originalController is QuillEditorController) {
      mimeType = ChatMessageMimeType.html;
    } else if (_originalController is HtmlEditorController) {
      mimeType = ChatMessageMimeType.html;
    } else if (_originalController is rte.HtmlEditorController) {
      mimeType = ChatMessageMimeType.html;
    } else if (_originalController is HtmlEditorApi) {
      mimeType = ChatMessageMimeType.html;
    }
  }

  Future<String?> get content async {
    if (_originalController is QuillController) {
      QuillController controller = _originalController as QuillController;
      Delta delta = controller.document.toDelta();
      return DocumentUtil.deltaToJson(delta);
    } else if (_originalController is QuillEditorController) {
      QuillEditorController controller =
          _originalController as QuillEditorController;
      return await controller.getText();
    } else if (_originalController is HtmlEditorController) {
      HtmlEditorController controller =
          _originalController as HtmlEditorController;
      return await controller.getText();
    } else if (_originalController is rte.HtmlEditorController) {
      rte.HtmlEditorController controller =
          _originalController as rte.HtmlEditorController;
      return await controller.getText();
    } else if (_originalController is HtmlEditorApi) {
      HtmlEditorApi controller = _originalController as HtmlEditorApi;
      return await controller.getText();
    }
    return null;
  }

  Future<String?> get html async {
    if (_originalController is QuillController) {
      QuillController controller = _originalController as QuillController;
      Delta delta = controller.document.toDelta();
      return DocumentUtil.deltaToHtml(delta);
    } else if (_originalController is QuillEditorController) {
      QuillEditorController controller =
          _originalController as QuillEditorController;
      return await controller.getText();
    } else if (_originalController is HtmlEditorController) {
      HtmlEditorController controller =
          _originalController as HtmlEditorController;
      return await controller.getText();
    } else if (_originalController is rte.HtmlEditorController) {
      rte.HtmlEditorController controller =
          _originalController as rte.HtmlEditorController;
      return await controller.getText();
    } else if (_originalController is HtmlEditorApi) {
      HtmlEditorApi controller = _originalController as HtmlEditorApi;
      return await controller.getFullHtml();
    }
    return null;
  }
}

///要么加expanded，要么设置height，否则使用缺省的高度
class PlatformEditorWidget extends StatefulWidget {
  final double? height;
  final String? initialText;
  PlatformEditorController? platformEditorController;

  PlatformEditorWidget({
    Key? key,
    this.initialText,
    this.height,
    this.platformEditorController,
  }) : super(key: key) {
    platformEditorController ??= PlatformEditorController();
  }

  @override
  State createState() => _PlatformEditorWidgetState();
}

class _PlatformEditorWidgetState extends State<PlatformEditorWidget> {
  @override
  void initState() {
    super.initState();
  }

  _onCreateController(dynamic controller) {
    widget.platformEditorController!._originalController = controller;
  }

  @override
  Widget build(BuildContext context) {
    if (platformParams.desktop) {
      return KeepAliveWrapper(
          child: QuillEditorWidget(
        height: widget.height,
        initialText: widget.initialText,
        onCreateController: _onCreateController,
      ));
    }
    if (platformParams.mobile || platformParams.web) {
      return KeepAliveWrapper(
          child: QuillHtmlEditorWidget(
        height: widget.height,
        initialText: widget.initialText,
        onCreateController: _onCreateController,
      ));
    }
    if (platformParams.windows) {
      return KeepAliveWrapper(
          child: HtmlRteWidget(
        height: widget.height,
        initialText: widget.initialText,
        onCreateController: _onCreateController,
      ));
    }
    return KeepAliveWrapper(
        child: HtmlEditorWidget(
      height: widget.height,
      initialText: widget.initialText,
      onCreateController: _onCreateController,
    ));
  }
}
