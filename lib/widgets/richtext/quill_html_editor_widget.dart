import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';

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
  final FocusNode _focusNode = FocusNode();
  late Document _doc;
  final QuillController _controller = () {
    return QuillController.basic(
        config: QuillControllerConfig(
      clipboardConfig: QuillClipboardConfig(
        enableExternalRichPaste: true,
        onImagePaste: (imageBytes) async {
          if (platformParams.web) {
            return null;
          }
          String? filename =
              await FileUtil.writeTempFileAsBytes(imageBytes, extension: 'png');

          return filename;
        },
      ),
    ));
  }();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    ///初始化数据的是json格式则可以编辑
    if (widget.initialText != null) {
      try {
        if (widget.mimeType == ChatMessageMimeType.json) {
          var json = JsonUtil.toJson(widget.initialText!);
          _doc = Document.fromJson(json);
        }
        if (widget.mimeType == ChatMessageMimeType.html) {
          final converter = HtmlToDelta();
          final delta = converter.convert(widget.initialText!);
          _doc = Document.fromDelta(delta);
        }
      } catch (e) {
        _doc = Document();
      }
    } else {
      _doc = Document();
    }
    _controller.document = _doc;
    if (widget.onCreateController != null) {
      widget.onCreateController!(_controller);
    }
  }

  Widget _buildQuillToolbar(BuildContext context) {
    QuillToolbarImageButtonOptions imageButtonOptions =
        const QuillToolbarImageButtonOptions();
    QuillToolbarVideoButtonOptions videoButtonOptions =
        const QuillToolbarVideoButtonOptions();
    QuillToolbarCameraButtonOptions cameraButtonOptions =
        const QuillToolbarCameraButtonOptions();
    return QuillSimpleToolbar(
      controller: _controller,
      config: QuillSimpleToolbarConfig(
        embedButtons: FlutterQuillEmbeds.toolbarButtons(
            imageButtonOptions: imageButtonOptions,
            videoButtonOptions: videoButtonOptions,
            cameraButtonOptions: cameraButtonOptions),
        showClipboardPaste: true,
        showDirection: true,
        customButtons: [
          QuillToolbarCustomButtonOptions(
            icon: const Icon(Icons.add_alarm_rounded),
            onPressed: () {
              _controller.document.insert(
                _controller.selection.extentOffset,
                TimeStampEmbed(DateTime.now().toString()),
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
              if (platformParams.desktop) {
                _focusNode.requestFocus();
              }
            },
          ),
          linkStyle: QuillToolbarLinkStyleButtonOptions(
            validateLink: (link) {
              return true;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuillHtmlEditor(BuildContext context) {
    Widget quillHtmlEditor = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      double height = widget.height ?? constraints.minHeight;
      return QuillEditor(
        focusNode: _focusNode,
        scrollController: _scrollController,
        controller: _controller,
        config: QuillEditorConfig(
          placeholder: 'Start writing your notes...',
          padding: const EdgeInsets.all(16),
          embedBuilders: [
            ...FlutterQuillEmbeds.editorBuilders(
              imageEmbedConfig: QuillEditorImageEmbedConfig(
                imageProviderBuilder: (context, imageUrl) {
                  if (imageUrl.startsWith('assets/')) {
                    return AssetImage(imageUrl);
                  }
                  return null;
                },
              ),
              videoEmbedConfig: QuillEditorVideoEmbedConfig(
                customVideoBuilder: (videoUrl, readOnly) {
                  return null;
                },
              ),
            ),
            TimeStampEmbedBuilder(),
          ],
        ),
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
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class TimeStampEmbed extends Embeddable {
  const TimeStampEmbed(String value) : super(timeStampType, value);

  static const String timeStampType = 'timeStamp';

  static TimeStampEmbed fromDocument(Document document) =>
      TimeStampEmbed(JsonUtil.toJsonString(document.toDelta().toJson()));

  Document get document => Document.fromJson(JsonUtil.toJson(data));
}

class TimeStampEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'timeStamp';

  @override
  String toPlainText(Embed node) {
    return node.value.data;
  }

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    return Row(
      children: [
        const Icon(Icons.access_time_rounded),
        Text(embedContext.node.value.data as String),
      ],
    );
  }
}
