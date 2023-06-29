import 'dart:convert';
import 'dart:io';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
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

///quill_editor一样的实现，用于IOS,LINUX,MACOS,WINDOWS
class QuillEditorWidget extends StatefulWidget {
  final double height;
  final String? initialText;
  final ChatMessageMimeType mimeType;
  final Function(String? result, ChatMessageMimeType mimeType)? onSubmit;

  const QuillEditorWidget({
    Key? key,
    required this.height,
    this.initialText,
    this.onSubmit,
    this.mimeType = ChatMessageMimeType.json,
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
    var toolbar = QuillToolbar.basic(
      locale: myself.locale,
      controller: controller,
      toolbarIconAlignment: WrapAlignment.start,
      toolbarIconCrossAlignment: WrapCrossAlignment.start,
      embedButtons: FlutterQuillEmbeds.buttons(
        onImagePickCallback: _onMediaPickCallback,
        onVideoPickCallback: _onMediaPickCallback,
        // uncomment to provide a custom "pick from" dialog.
        // mediaPickSettingSelector: _selectMediaPickSetting,
        // uncomment to provide a custom "pick from" dialog.
        // cameraPickSettingSelector: _selectCameraPickSetting,
      ),
      customButtons: customButtons,
      showAlignmentButtons: true,
      afterButtonPressed: _focusNode.requestFocus,
    );
    if (platformParams.web) {
      toolbar = QuillToolbar.basic(
        locale: myself.locale,
        controller: controller,
        toolbarIconAlignment: WrapAlignment.start,
        toolbarIconCrossAlignment: WrapCrossAlignment.start,
        embedButtons: FlutterQuillEmbeds.buttons(
          onImagePickCallback: _onMediaPickCallback,
          webImagePickImpl: _webImagePickImpl,
        ),
        customButtons: customButtons,
        showAlignmentButtons: true,
        afterButtonPressed: _focusNode.requestFocus,
      );
    }
    return toolbar;
  }

  Widget _buildQuillEditor(BuildContext context) {
    Widget quillEditor = QuillEditor(
      locale: myself.locale,
      controller: controller,
      scrollController: ScrollController(),
      scrollable: true,
      focusNode: _focusNode,
      autoFocus: false,
      readOnly: false,
      // placeholder: AppLocalizations.t('Add content'),
      enableSelectionToolbar: platformParams.mobile,
      expands: false,
      padding: EdgeInsets.zero,
      onImagePaste: _onImagePaste,
      customStyles: DefaultStyles(
        h1: DefaultTextBlockStyle(
            const TextStyle(
              fontSize: 32,
              color: Colors.black,
              height: 1.15,
              fontWeight: FontWeight.w300,
            ),
            const VerticalSpacing(16, 0),
            const VerticalSpacing(0, 0),
            null),
        sizeSmall: const TextStyle(fontSize: 9),
      ),
      embedBuilders: [
        ...FlutterQuillEmbeds.builders(),
        NotesEmbedBuilder(addEditNote: _addEditNote)
      ],
    );
    if (platformParams.web) {
      quillEditor = QuillEditor(
          locale: myself.locale,
          controller: controller,
          scrollController: ScrollController(),
          scrollable: true,
          focusNode: _focusNode,
          autoFocus: false,
          readOnly: false,
          expands: false,
          padding: EdgeInsets.zero,
          customStyles: DefaultStyles(
            h1: DefaultTextBlockStyle(
                const TextStyle(
                  fontSize: 32,
                  color: Colors.black,
                  height: 1.15,
                  fontWeight: FontWeight.w300,
                ),
                const VerticalSpacing(16, 0),
                const VerticalSpacing(0, 0),
                null),
            sizeSmall: const TextStyle(fontSize: 9),
          ),
          embedBuilders: [
            NotesEmbedBuilder(addEditNote: _addEditNote),
          ]);
    }
    var toolbar = _buildQuillToolbar(context);

    return Card(
        elevation: 0.0,
        margin: EdgeInsets.zero,
        shape: const ContinuousRectangleBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            platformParams.web
                ? Expanded(
                    child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: toolbar,
                  ))
                : Container(child: toolbar),
            Expanded(
              flex: 15,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: quillEditor,
              ),
            ),
          ],
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
