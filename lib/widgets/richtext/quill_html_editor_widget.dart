import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

///quill_html_editor一样的实现，用于移动和web
///缺省的最小高度200
class QuillHtmlEditorWidget extends StatefulWidget {
  final double? height;
  final String? initialText;
  final ChatMessageMimeType mimeType;
  final bool withMultiMedia;
  final bool base64;
  final Function(QuillController controller)? onCreateController;

  const QuillHtmlEditorWidget({
    super.key,
    this.height,
    this.initialText,
    this.mimeType = ChatMessageMimeType.html,
    this.onCreateController,
    this.withMultiMedia = true,
    this.base64 = true,
  });

  @override
  State createState() => _QuillHtmlEditorWidgetState();
}

class _QuillHtmlEditorWidgetState extends State<QuillHtmlEditorWidget> {
  final QuillController _controller = () {
    return QuillController.basic(
        config: QuillControllerConfig(
          clipboardConfig: QuillClipboardConfig(
            enableExternalRichPaste: true,
            onImagePaste: (imageBytes) async {
              if (kIsWeb) {
                // Dart IO is unsupported on the web.
                return null;
              }
              // Save the image somewhere and return the image URL that will be
              // stored in the Quill Delta JSON (the document).
              final newFileName =
                  'image-file-${DateTime.now().toIso8601String()}.png';
              final newPath = path.join(
                io.Directory.systemTemp.path,
                newFileName,
              );
              final file = await io.File(
                newPath,
              ).writeAsBytes(imageBytes, flush: true);
              return file.path;
            },
          ),
        ));
  }();
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.document = Document.fromJson(kQuillDefaultSample);
    if (widget.onCreateController != null) {
      widget.onCreateController!(controller);
    }

    ///初始化数据的是json和html格式则可以编辑
    if (widget.initialText != null) {
      if (widget.mimeType == ChatMessageMimeType.json) {
        var delta = JsonUtil.toJson(widget.initialText!);
        controller..setDelta(delta);
      }
      if (widget.mimeType == ChatMessageMimeType.html &&
          widget.initialText != null) {
        controller.setText(widget.initialText!);
      }
    }
  }

  Widget _buildQuillToolbar(BuildContext context) {
    QuillSimpleToolbar(
      controller: _controller,
      config: QuillSimpleToolbarConfig(
        embedButtons: FlutterQuillEmbeds.toolbarButtons(),
        showClipboardPaste: true,
        customButtons: [
          QuillToolbarCustomButtonOptions(
            icon: const Icon(Icons.add_alarm_rounded),
            onPressed: () {
              _controller.document.insert(
                _controller.selection.extentOffset,
                TimeStampEmbed(
                  DateTime.now().toString(),
                ),
              );

              _controller.updateSelection(
                TextSelection.collapsed(
                  offset: _controller.selection.extentOffset + 1,
                ),
                ChangeSource.local,
              );
            },
          ),
        ],
        buttonOptions: QuillSimpleToolbarButtonOptions(
          base: QuillToolbarBaseButtonOptions(
            afterButtonPressed: () {
              final isDesktop = {
                TargetPlatform.linux,
                TargetPlatform.windows,
                TargetPlatform.macOS
              }.contains(defaultTargetPlatform);
              if (isDesktop) {
                _editorFocusNode.requestFocus();
              }
            },
          ),
          linkStyle: QuillToolbarLinkStyleButtonOptions(
            validateLink: (link) {
              // Treats all links as valid. When launching the URL,
              // `https://` is prefixed if the link is incomplete (e.g., `google.com` → `https://google.com`)
              // however this happens only within the editor.
              return true;
            },
          ),
        ),
      ),
    ),
    List<ToolBarStyle> toolBarConfig = [];
    for (ToolBarStyle toolBarStyle in ToolBarStyle.values) {
      if (widget.withMultiMedia ||
          (toolBarStyle != ToolBarStyle.link &&
              toolBarStyle != ToolBarStyle.image &&
              toolBarStyle != ToolBarStyle.video)) {
        toolBarConfig.add(toolBarStyle);
      }
    }
    var customButtons = <Widget>[];
    return ToolBar.scroll(
        toolBarColor: Colors.white,
        padding: const EdgeInsets.all(8),
        iconSize: 25,
        iconColor: Colors.black,
        activeIconColor: myself.primary,
        controller: controller,
        crossAxisAlignment: CrossAxisAlignment.start,
        toolBarConfig: toolBarConfig,
        customButtons: customButtons);
  }

  Widget _buildQuillHtmlEditor(BuildContext context) {
    Widget quillHtmlEditor = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      double height = widget.height ?? constraints.minHeight;
      return QuillEditor(
        text: widget.initialText,
        controller: controller,
        isEnabled: true,
        minHeight: height,
        ensureVisible: true,
        hintTextAlign: TextAlign.start,
        hintText: '', focusNode: null, scrollController: null,
      );
    });
    var toolbar = _buildQuillToolbar(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(
          height: 5.0,
        ),
        toolbar,
        Divider(
          height: 1.0,
          thickness: 1.0,
          color: myself.primary,
        ),
        Expanded(
          child: quillHtmlEditor,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildQuillHtmlEditor(context);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
