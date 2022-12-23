import 'dart:io';

import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/richtext/quill_util.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:visual_editor/visual-editor.dart';
import 'package:path/path.dart';

//富文本的编辑的页面
class VisualRichTextWidget extends StatefulWidget {
  final ChatMessage? chatMessage;
  final bool readOnly;

  const VisualRichTextWidget(
      {Key? key, this.chatMessage, this.readOnly = false})
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
    if (widget.chatMessage != null) {
      var content = JsonUtil.toJson(widget.chatMessage!.content);
      _controller = EditorController(document: DocumentM.fromJson(content));
    } else {
      var content = JsonUtil.toJson(EMPTY_DELTA_DOC_JSON);
      _controller = EditorController(document: DocumentM.fromJson(content));
    }
  }

  Future<void> _store() async {
    final content = _controller!.document.toDelta().toJson();
    final thumbnail = _controller!.document.toPlainText();
    final title = thumbnail.substring(0, 30);
    var data = JsonUtil.toUintList(content);
    ChatMessage chatMessage = await chatMessageService.buildChatMessage(
      myself.peerId!,
      data: data,
      title: title,
      thumbnail: JsonUtil.toUintList(thumbnail),
      messageType: ChatMessageType.channel,
      subMessageType: ChatMessageSubType.sendChannel,
      contentType: ContentType.rich,
    );
    await chatMessageService.store(chatMessage, updateSummary: false);
  }
}
