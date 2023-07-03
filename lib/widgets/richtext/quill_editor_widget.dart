import 'dart:convert';
import 'dart:io';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/document_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:cross_file/cross_file.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:path_provider/path_provider.dart';

///quill_editor的实现，用于IOS,LINUX,MACOS,WINDOWS桌面平台
///编辑的时候是quill可识别的json格式，完成后可转换成html格式，就不可以再编辑了
class QuillEditorWidget extends StatefulWidget {
  final double height;
  final String? initialText;
  final ChatMessageMimeType mimeType;
  final bool withMultiMedia;
  final Function(String? result, ChatMessageMimeType mimeType)? onSubmit;

  const QuillEditorWidget({
    Key? key,
    required this.height,
    this.initialText,
    this.onSubmit,
    this.mimeType = ChatMessageMimeType.json,
    this.withMultiMedia = false,
  }) : super(key: key);

  @override
  State createState() => _QuillEditorWidgetState();
}

class _QuillEditorWidgetState extends State<QuillEditorWidget> {
  final FocusNode _focusNode = FocusNode();
  late Document doc;
  late final QuillController controller;

  @override
  void initState() {
    super.initState();

    ///初始化数据的是json格式则可以编辑
    if (widget.initialText != null) {
      try {
        if (widget.mimeType == ChatMessageMimeType.json) {
          doc = Document.fromJson(JsonUtil.toJson(widget.initialText!));
        }
      } catch (e) {
        doc = Document();
      }
    } else {
      doc = Document();
    }
    controller = QuillController(
        document: doc, selection: const TextSelection.collapsed(offset: 0));
  }

  Future<String?> _onImagePaste(Uint8List imageBytes) async {
    String? filename =
        await FileUtil.writeTempFile(imageBytes, extension: 'png');

    return filename;
  }

  Future<void> _addEditNote(BuildContext context, {Document? document}) async {
    final isEditing = document != null;
    final quillEditorController = QuillController(
      document: document ?? Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.only(left: 16, top: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CommonAutoSizeText('${isEditing ? 'Edit' : 'Add'} note'),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            )
          ],
        ),
        content: QuillEditor.basic(
          controller: quillEditorController,
          readOnly: false,
        ),
      ),
    );

    if (quillEditorController.document.isEmpty()) return;

    final block = BlockEmbed.custom(
      NotesBlockEmbed.fromDocument(quillEditorController.document),
    );
    final index = controller.selection.baseOffset;
    final length = controller.selection.extentOffset - index;

    if (isEditing) {
      final offset =
          getEmbedNode(controller, controller.selection.start).offset;
      controller.replaceText(
          offset, 1, block, TextSelection.collapsed(offset: offset));
    } else {
      controller.replaceText(index, length, block, null);
    }
  }

  Future<String> _onMediaPickCallback(File file) async {
    final filename = await FileUtil.getTempFilename();
    final copiedFile = await file.copy(filename);

    return copiedFile.path.toString();
  }

  Future<String?> _webImagePickImpl(
      OnImagePickCallback onImagePickCallback) async {
    final List<XFile> result = await FileUtil.pickFiles();
    if (result.isEmpty) {
      return null;
    }
    final fileName = result.first.name;
    final file = File(fileName);

    return onImagePickCallback(file);
  }

  Future<String?> openFileSystemPickerForDesktop(BuildContext context) async {
    return await FileUtil.open(
      context: context,
      rootDirectory: await getApplicationDocumentsDirectory(),
      fsType: FilesystemType.file,
      fileTileSelectMode: FileTileSelectMode.wholeTile,
    );
  }

  /// 定制媒体选择界面
  Future<MediaPickSetting?> _selectMediaPickSetting(BuildContext context) =>
      showDialog<MediaPickSetting>(
        context: context,
        builder: (ctx) => AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.collections),
                label: CommonAutoSizeText(AppLocalizations.t('Gallery')),
                onPressed: () => Navigator.pop(ctx, MediaPickSetting.Gallery),
              ),
              TextButton.icon(
                icon: const Icon(Icons.link),
                label: CommonAutoSizeText(AppLocalizations.t('Link')),
                onPressed: () => Navigator.pop(ctx, MediaPickSetting.Link),
              )
            ],
          ),
        ),
      );

  // ignore: unused_element
  Future<MediaPickSetting?> _selectCameraPickSetting(BuildContext context) =>
      showDialog<MediaPickSetting>(
        context: context,
        builder: (ctx) => AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.camera),
                label:
                    CommonAutoSizeText(AppLocalizations.t('Capture a photo')),
                onPressed: () => Navigator.pop(ctx, MediaPickSetting.Camera),
              ),
              TextButton.icon(
                icon: const Icon(Icons.video_call),
                label:
                    CommonAutoSizeText(AppLocalizations.t('Capture a video')),
                onPressed: () => Navigator.pop(ctx, MediaPickSetting.Video),
              )
            ],
          ),
        ),
      );

  Widget _buildQuillToolbar(BuildContext context) {
    ///定制提交按钮
    var customButtons = <QuillCustomButton>[
      QuillCustomButton(
          icon: Icons.check,
          onTap: () {
            if (widget.onSubmit != null) {
              String jsonStr = DocumentUtil.deltaToJson(doc.toDelta());
              widget.onSubmit!(jsonStr, ChatMessageMimeType.json);
            }
          },
          tooltip: AppLocalizations.t('Submit')),
    ];
    List<
            Widget Function(
                QuillController, double, QuillIconTheme?, QuillDialogTheme?)>?
        embedButtons;
    if (widget.withMultiMedia) {
      embedButtons = FlutterQuillEmbeds.buttons(
        onImagePickCallback: _onMediaPickCallback,
        onVideoPickCallback: _onMediaPickCallback,
        // uncomment to provide a custom "pick from" dialog.
        // mediaPickSettingSelector: _selectMediaPickSetting,
        // uncomment to provide a custom "pick from" dialog.
        // cameraPickSettingSelector: _selectCameraPickSetting,
      );
    }
    var toolbar = QuillToolbar.basic(
      locale: myself.locale,
      controller: controller,
      toolbarIconAlignment: WrapAlignment.start,
      toolbarIconCrossAlignment: WrapCrossAlignment.start,
      toolbarSectionSpacing: 1,
      sectionDividerSpace: 1,
      multiRowsDisplay: true,
      showLink: false,
      embedButtons: embedButtons,
      customButtons: customButtons,
      showAlignmentButtons: true,
      afterButtonPressed: _focusNode.requestFocus,
    );

    return toolbar;
  }

  Widget _buildQuillEditor(BuildContext context) {
    Widget quillEditor = QuillEditor(
      minHeight: 200,
      maxHeight: widget.height,
      locale: myself.locale,
      controller: controller,
      scrollController: ScrollController(),
      scrollable: true,
      focusNode: _focusNode,
      autoFocus: false,
      readOnly: false,
      enableSelectionToolbar: true,
      expands: false,
      padding: EdgeInsets.zero,
      onImagePaste: _onImagePaste,
      embedBuilders: [
        ...FlutterQuillEmbeds.builders(),
        NotesEmbedBuilder(addEditNote: _addEditNote)
      ],
    );
    var toolbar = _buildQuillToolbar(context);

    return Card(
        color: myself.getBackgroundColor(context).withOpacity(0.6),
        elevation: 0.0,
        margin: EdgeInsets.zero,
        shape: const ContinuousRectangleBorder(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                toolbar,
                const SizedBox(
                  height: 10.0,
                ),
                SizedBox(
                  height: widget.height,
                  child: quillEditor,
                ),
              ]),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return _buildQuillEditor(context);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class NotesEmbedBuilder extends EmbedBuilder {
  NotesEmbedBuilder({required this.addEditNote});

  Future<void> Function(BuildContext context, {Document? document}) addEditNote;

  @override
  String get key => 'notes';

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    final notes = NotesBlockEmbed(node.value.data).document;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        title: CommonAutoSizeText(
          notes.toPlainText().replaceAll('\n', ' '),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        leading: const Icon(Icons.notes),
        onTap: () => addEditNote(context, document: notes),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.grey),
        ),
      ),
    );
  }
}

class NotesBlockEmbed extends CustomBlockEmbed {
  const NotesBlockEmbed(String value) : super(noteType, value);

  static const String noteType = 'notes';

  static NotesBlockEmbed fromDocument(Document document) =>
      NotesBlockEmbed(jsonEncode(document.toDelta().toJson()));

  Document get document => Document.fromJson(jsonDecode(data));
}
