import 'dart:convert';
import 'dart:io';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/video_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

///quill_editor的实现，用于IOS,LINUX,MACOS,WINDOWS桌面平台
///编辑的时候是quill可识别的json格式，完成后可转换成html格式，就不可以再编辑了
///缺省的最小高度200
class QuillEditorWidget extends StatefulWidget {
  final double? height;
  final String? initialText;
  final bool withMultiMedia;
  final bool base64;
  final Function(QuillController controller)? onCreateController;

  const QuillEditorWidget({
    Key? key,
    this.height,
    this.initialText,
    this.onCreateController,
    this.withMultiMedia = true,
    this.base64 = true,
  }) : super(key: key);

  @override
  State createState() => _QuillEditorWidgetState();
}

class _QuillEditorWidgetState extends State<QuillEditorWidget> {
  final FocusNode _focusNode = FocusNode();
  late Document doc;
  late final QuillController quillController;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    ///初始化数据的是json格式则可以编辑
    if (widget.initialText != null) {
      try {
        doc = Document.fromJson(JsonUtil.toJson(widget.initialText!));
      } catch (e) {
        doc = Document();
      }
    } else {
      doc = Document();
    }
    quillController = QuillController(
        document: doc, selection: const TextSelection.collapsed(offset: 0));
    if (widget.onCreateController != null) {
      widget.onCreateController!(quillController);
    }
  }

  Future<String?> _onImagePaste(Uint8List imageBytes) async {
    String? filename =
        await FileUtil.writeTempFileAsBytes(imageBytes, extension: 'png');

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
          content: QuillProvider(
            configurations: QuillConfigurations(
              controller: quillEditorController,
            ),
            child: QuillEditor.basic(
                configurations: const QuillEditorConfigurations()),
          )),
    );

    if (quillEditorController.document.isEmpty()) return;

    final block = BlockEmbed.custom(
      NotesBlockEmbed.fromDocument(quillEditorController.document),
    );
    final index = quillController.selection.baseOffset;
    final length = quillController.selection.extentOffset - index;

    if (isEditing) {
      final offset =
          getEmbedNode(quillController, quillController.selection.start).offset;
      quillController.replaceText(
          offset, 1, block, TextSelection.collapsed(offset: offset));
    } else {
      quillController.replaceText(index, length, block, null);
    }
  }

  ///以下多媒体文件选择按钮的功能，其调用方式是：
  ///1.如果mediaPickSettingSelector存在则调用，否则调用通用的，选择媒体文件的两个选项，图片廊和link
  ///2.如果是图片廊，则调用filePickImpl，找到文件
  ///3.调用onImagePickCallback，获取资源的获取方式
  ///这些功能都有默认实现

  ///媒体选择回调，当选择了一个本地文件后，给出访问这个选择文件的办法
  ///比如上传内容到网上，然后给出url
  Future<String> _onImagePickCallback(File file) async {
    if (widget.base64) {
      Uint8List data = file.readAsBytesSync();
      String img = CryptoUtil.encodeBase64(data);
      return ImageUtil.base64Img(img);
    }

    return file.path.toString();
  }

  Future<String> _onVideoPickCallback(File file) async {
    if (widget.base64) {
      Uint8List data = file.readAsBytesSync();
      String img = CryptoUtil.encodeBase64(data);
      return VideoUtil.base64Video(img);
    }

    return file.path.toString();
  }

  ///桌面平台的文件选择对话框，返回选择的文件名
  Future<String?> _filePickImpl(BuildContext context) async {
    final List<XFile> result = await FileUtil.pickFiles();
    if (result.isEmpty) {
      return null;
    }
    final filename = result.first.path;

    return filename;
  }

  ///web平台选择图像文件
  Future<String?> _webImagePickImpl(
      Function(String) onImagePickCallback) async {
    final List<XFile> result = await FileUtil.pickFiles();
    if (result.isEmpty) {
      return null;
    }
    final filename = result.first.name;
    final file = File(filename);

    return '';
  }

  ///web平台选择视频文件
  Future<String?> _webVideoPickImpl(
      Function(String) onVideoPickCallback) async {
    final List<XFile> result = await FileUtil.pickFiles();
    if (result.isEmpty) {
      return null;
    }
    final filename = result.first.name;
    final file = File(filename);

    return '';
  }

  /// 媒体来源的选择界面
  /// 从图片廊和link中选择
  Future<QuillMediaType?> _mediaPickSettingSelector(
      BuildContext context) async {
    return await showDialog<QuillMediaType>(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.collections),
              label: Text(AppLocalizations.t('Gallery')),
              onPressed: () => Navigator.pop(ctx, QuillMediaType.video),
            ),
            TextButton.icon(
              icon: const Icon(Icons.link),
              label: Text(AppLocalizations.t('Link')),
              onPressed: () => Navigator.pop(ctx, QuillMediaType.image),
            )
          ],
        ),
      ),
    );
  }

  /// 相机模式选择，照相还是录制视频
  Future<QuillMediaType?> _cameraPickSettingSelector(
      BuildContext context) async {
    return await showDialog<QuillMediaType>(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.camera),
              label: Text(AppLocalizations.t('Capture photo')),
              onPressed: () => Navigator.pop(ctx, QuillMediaType.image),
            ),
            TextButton.icon(
              icon: const Icon(Icons.video_call),
              label: Text(AppLocalizations.t('Capture video')),
              onPressed: () => Navigator.pop(ctx, QuillMediaType.video),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuillToolbar(BuildContext context) {
    if (widget.withMultiMedia) {}

    var toolbar = QuillToolbar(
      configurations: QuillToolbarConfigurations(
        showAlignmentButtons: true,
        toolbarIconAlignment: WrapAlignment.start,
        toolbarIconCrossAlignment: WrapCrossAlignment.start,
        toolbarSectionSpacing: 1,
        sectionDividerSpace: 1,
        showLink: false,
        buttonOptions: QuillToolbarButtonOptions(
          base: QuillToolbarBaseButtonOptions(
            // Request editor focus when any button is pressed
            afterButtonPressed: _focusNode.requestFocus,
          ),
        ),
        customButtons: [
          QuillToolbarCustomButtonOptions(
            icon: const Icon(Icons.add_alarm_rounded),
            onPressed: () {
              final controller = context.requireQuillController;
              controller.document
                  .insert(controller.selection.extentOffset, '\n');
              controller.updateSelection(
                TextSelection.collapsed(
                  offset: controller.selection.extentOffset + 1,
                ),
                ChangeSource.local,
              );

              controller.document.insert(
                controller.selection.extentOffset,
                NotesBlockEmbed(
                  DateTime.now().toString(),
                ),
              );

              controller.updateSelection(
                TextSelection.collapsed(
                  offset: controller.selection.extentOffset + 1,
                ),
                ChangeSource.local,
              );

              controller.document
                  .insert(controller.selection.extentOffset, ' ');
              controller.updateSelection(
                TextSelection.collapsed(
                  offset: controller.selection.extentOffset + 1,
                ),
                ChangeSource.local,
              );

              controller.document
                  .insert(controller.selection.extentOffset, '\n');
              controller.updateSelection(
                TextSelection.collapsed(
                  offset: controller.selection.extentOffset + 1,
                ),
                ChangeSource.local,
              );
            },
          ),
          QuillToolbarCustomButtonOptions(
            icon: const Icon(Icons.ac_unit),
            onPressed: () {},
          ),
        ],
        embedButtons: FlutterQuillEmbeds.toolbarButtons(
          imageButtonOptions: QuillToolbarImageButtonOptions(
            imageButtonConfigurations: QuillToolbarImageConfigurations(
                onImageInsertCallback: (image, controller) async {}),
          ),
          videoButtonOptions: QuillToolbarVideoButtonOptions(
            childBuilder: (QuillToolbarVideoButtonOptions,
                QuillToolbarVideoButtonExtraOptions) {
              return Container();
            },
            controller: quillController,
            videoConfigurations: const QuillToolbarVideoConfigurations(),
          ),
          cameraButtonOptions: const QuillToolbarCameraButtonOptions(),
          mediaButtonOptions: QuillToolbarMediaButtonOptions(
              type: QuillMediaType.video,
              onMediaPickedCallback: (XFile file) async {
                return '';
              }),
        ),
      ),
    );

    return toolbar;
  }

  Widget _buildQuillEditor(BuildContext context) {
    Widget quillEditor = QuillEditor(
      configurations: QuillEditorConfigurations(
        minHeight: 200,
        maxHeight: widget.height,
        scrollable: true,
        autoFocus: false,
        enableSelectionToolbar: true,
        expands: false,
        padding: EdgeInsets.zero,
        onImagePaste: _onImagePaste,
        readOnly: false,
        embedBuilders: [
          ...FlutterQuillEmbeds.defaultEditorBuilders(),
          NotesEmbedBuilder(addEditNote: _addEditNote)
        ],
      ),
      scrollController: scrollController,
      focusNode: _focusNode,
    );

    var toolbar = _buildQuillToolbar(context);

    return QuillProvider(
        configurations: QuillConfigurations(
          controller: quillController,
          sharedConfigurations: QuillSharedConfigurations(
            animationConfigurations: QuillAnimationConfigurations.disableAll(),
            extraConfigurations: const {
              QuillSharedExtensionsConfigurations.key:
                  QuillSharedExtensionsConfigurations(
                assetsPrefix: 'assets',
              ),
            },
          ),
        ),
        child: Card(
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
                    const SizedBox(
                      height: 5.0,
                    ),
                    toolbar,
                    const SizedBox(
                      height: 5.0,
                    ),
                    Divider(
                      height: 1.0,
                      thickness: 1.0,
                      color: myself.primary,
                    ),
                    const SizedBox(
                      height: 5.0,
                    ),
                    Expanded(
                        child: SizedBox(
                      height: widget.height,
                      child: quillEditor,
                    )),
                  ]),
            )));
  }

  @override
  Widget build(BuildContext context) {
    return _buildQuillEditor(context);
  }

  @override
  void dispose() {
    quillController.dispose();
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
