import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/richtext/quill_util.dart';
import 'package:flutter/material.dart';
import 'package:visual_editor/documents/models/delta/delta-changes.model.dart';
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
      children.add(_buildEditor());
      if (!widget.readOnly) {
        children.add(_buildToolbar());
      }
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
    var child = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: children,
    );
    return child;
  }

  Widget _buildEditor() {
    return Flexible(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
        ),
        child: VisualEditor(
          controller: _controller!,
          scrollController: _scrollController,
          focusNode: _focusNode,
          config: EditorConfigM(
            readOnly: widget.readOnly,
            placeholder: AppLocalizations.t('Enter text'),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return EditorToolbar.basic(
      controller: _controller!,
      onImagePickCallback: QuillUtil.onImagePickCallback,
      onVideoPickCallback:
          platformParams.web ? QuillUtil.onVideoPickCallback : null,
      filePickImpl: platformParams.desktop
          ? QuillUtil.openFileSystemPickerForDesktop
          : null,
      webImagePickImpl: QuillUtil.webImagePickImpl,
      mediaPickSettingSelector: QuillUtil.selectMediaPickSettingE,
      showAlignmentButtons: true,
      multiRowsDisplay: false,
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
    _controller!.changes.listen((DeltaChangeM deltaChangeM) {
      if (widget.onStore != null) {
        widget.onStore!(_controller!.document);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
