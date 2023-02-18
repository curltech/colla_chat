import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/richtext/quill_util.dart';
import 'package:flutter/material.dart';
import 'package:visual_editor/visual-editor.dart';

//富文本的编辑的页面
class VisualRichTextWidget extends StatefulWidget {
  final String? content;
  final bool readOnly;
  final Function(DocumentM doc)? onStore;

  const VisualRichTextWidget(
      {Key? key, this.content, this.readOnly = false, this.onStore})
      : super(key: key);

  @override
  State createState() => _VisualRichTextWidgetState();
}

class _VisualRichTextWidgetState extends State<VisualRichTextWidget> {
  EditorController? _controller;

  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  _update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    if (_controller != null) {
      if (!widget.readOnly) {
        children.add(Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            child: _buildToolbar()));
      }
      children.add(Expanded(
          flex: 15,
          child: Container(
              padding: const EdgeInsets.only(left: 5, right: 5),
              child: _buildEditor())));
    } else {
      children.add(Center(
        child: Text(
          AppLocalizations.t('Loading...'),
          style: const TextStyle(
            fontSize: 30,
          ),
        ),
      ));
    }
    var richTextWidget = Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: children,
        ));

    return richTextWidget;
  }

  Widget _buildEditor() {
    return VisualEditor(
      controller: _controller!,
      scrollController: _scrollController,
      focusNode: _focusNode,
      config: EditorConfigM(
        readOnly: widget.readOnly,
        autoFocus: true,
        expands: true,
        padding: EdgeInsets.zero,
        placeholder: AppLocalizations.t(''),
        locale: myself.locale,
      ),
    );
  }

  Widget _buildToolbar() {
    return EditorToolbar.basic(
      controller: _controller!,
      toolbarIconSize: 18,
      toolbarIconAlignment: WrapAlignment.start,
      onImagePickCallback: QuillUtil.onImagePickCallback,
      onVideoPickCallback: QuillUtil.onVideoPickCallback,
      filePickImpl: QuillUtil.openFileSystemPicker,
      webImagePickImpl: QuillUtil.webImagePickImpl,
      mediaPickSettingSelector: QuillUtil.selectMediaPickSettingE,
      showAlignmentButtons: true,
      showSmallButton: true,
      multiRowsDisplay: true,
      showDirection: true,
      showMarkers: true,
      locale: myself.locale,
    );
  }

  Future<void> _load() async {
    if (widget.content != null) {
      var content = JsonUtil.toJson(widget.content!);
      _controller = EditorController(document: DocumentM.fromJson(content));
    } else {
      var content = JsonUtil.toJson(EMPTY_DELTA_DOC_JSON);
      _controller = EditorController(document: DocumentM.fromJson(content));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
