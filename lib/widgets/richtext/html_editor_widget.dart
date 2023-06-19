import 'dart:async';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/document_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/smart_dialog_util.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';

///html_editor_enhanced实现，用于移动和web
class HtmlEditorWidget extends StatefulWidget {
  final double height;
  final String? initialText;
  final ChatMessageMimeType mimeType;
  final Function(String? result, ChatMessageMimeType mimeType)? onSubmit;

  const HtmlEditorWidget({
    Key? key,
    required this.height,
    this.initialText,
    this.onSubmit,
    this.mimeType = ChatMessageMimeType.html,
  }) : super(key: key);

  @override
  State createState() => _HtmlEditorWidgetState();
}

class _HtmlEditorWidgetState extends State<HtmlEditorWidget> {
  final HtmlEditorController controller = HtmlEditorController();

  @override
  void initState() {
    super.initState();
  }

  Widget _buildHtmlEditor(BuildContext context) {
    if (widget.initialText != null) {
      var html = widget.initialText!;
      if (widget.mimeType == ChatMessageMimeType.json) {
        var deltaJson = JsonUtil.toJson(html);
        html = DocumentUtil.jsonToHtml(deltaJson);
      }
      controller.setText(html);
    }
    return HtmlEditor(
      controller: controller,
      htmlEditorOptions: HtmlEditorOptions(
        hint: AppLocalizations.t('Your text here...'),
        shouldEnsureVisible: true,
        initialText: widget.initialText,
      ),
      htmlToolbarOptions: _buildHtmlToolbarOptions(),
      otherOptions: OtherOptions(height: widget.height),
      callbacks: _buildCallbacks(),
      plugins: _buildPlugins(),
    );
  }

  Callbacks _buildCallbacks() {
    return Callbacks(onBeforeCommand: (String? currentHtml) {
      logger.i('html before change is $currentHtml');
    }, onChangeContent: (String? changed) {
      logger.i('content changed to $changed');
    }, onChangeCodeview: (String? changed) {
      logger.i('code changed to $changed');
    }, onChangeSelection: (EditorSettings settings) {
      logger.i('parent element is ${settings.parentElement}');
      logger.i('font name is ${settings.fontName}');
    }, onDialogShown: () {
      logger.i('dialog shown');
    }, onEnter: () {
      logger.i('enter/return pressed');
    }, onFocus: () {
      logger.i('editor focused');
    }, onBlur: () {
      logger.i('editor unfocused');
    }, onBlurCodeview: () {
      logger.i('codeview either focused or unfocused');
    }, onInit: () {
      logger.i('init');
    }, onImageUploadError:
        (FileUpload? file, String? base64Str, UploadError error) {
      logger.i(describeEnum(error));
      logger.i(base64Str ?? '');
      if (file != null) {
        logger.i(file.name);
        logger.i(file.size);
        logger.i(file.type);
      }
    }, onKeyDown: (int? keyCode) {
      logger.i('$keyCode key downed');
      logger.i('current character count: ${controller.characterCount}');
    }, onKeyUp: (int? keyCode) {
      logger.i('$keyCode key released');
    }, onMouseDown: () {
      logger.i('mouse downed');
    }, onMouseUp: () {
      logger.i('mouse released');
    }, onNavigationRequestMobile: (String url) {
      logger.i(url);
      return NavigationActionPolicy.ALLOW;
    }, onPaste: () {
      logger.i('pasted into editor');
    }, onScroll: () {
      logger.i('editor scrolled');
    });
  }

  HtmlToolbarOptions _buildHtmlToolbarOptions() {
    return HtmlToolbarOptions(
      toolbarPosition: ToolbarPosition.aboveEditor,
      toolbarType: ToolbarType.nativeExpandable,
      initiallyExpanded: true,
      defaultToolbarButtons: const [
        StyleButtons(),
        FontSettingButtons(fontSizeUnit: true),
        FontButtons(clearAll: false),
        ColorButtons(),
        ListButtons(listStyles: true),
        ParagraphButtons(
            textDirection: true, lineHeight: true, caseConverter: true),
        InsertButtons(
            video: true, audio: true, table: true, hr: true, otherFile: true),
      ],
      toolbarItemHeight: 36,
      customToolbarButtons: [
        Tooltip(
            message: AppLocalizations.t('Confirm'),
            child: InkWell(
              onTap: () async {
                if (widget.onSubmit != null) {
                  String html = await controller.getText();
                  widget.onSubmit!(html, ChatMessageMimeType.html);
                }
              },
              child: const Icon(Icons.check),
            )),
      ],
      gridViewHorizontalSpacing: 5,
      gridViewVerticalSpacing: 5,
      onButtonPressed: (ButtonType type, bool? status, Function? updateStatus) {
        logger.i(
            "button '${describeEnum(type)}' pressed, the current selected status is $status");
        return true;
      },
      onDropdownChanged: (DropdownType type, dynamic changed,
          Function(dynamic)? updateSelectedItem) {
        logger.i("dropdown '${describeEnum(type)}' changed to $changed");
        return true;
      },
      mediaLinkInsertInterceptor: (String url, InsertFileType type) {
        logger.i(url);
        return true;
      },
      mediaUploadInterceptor: (PlatformFile file, InsertFileType type) async {
        logger.i(file.name); //filename
        logger.i(file.size); //size in bytes
        logger.i(file.extension); //file extension (eg jpeg or mp4)
        return true;
      },
    );
  }

  List<Plugins> _buildPlugins() {
    return [
      SummernoteAtMention(
          getSuggestionsMobile: (String value) {
            var mentions = <String>['test1', 'test2', 'test3'];
            return mentions
                .where((element) => element.contains(value))
                .toList();
          },
          mentionsWeb: ['test1', 'test2', 'test3'],
          onSelect: (String value) {
            logger.i(value);
          }),
    ];
  }

  List<ActionData> _buildActionData() {
    List<ActionData> actionData = [];
    actionData.add(
      ActionData(
        label: 'Undo',
        icon: const Icon(Icons.undo),
        onTap: (int index, String label, {String? value}) {
          controller.undo();
        },
      ),
    );
    actionData.add(
      ActionData(
        label: 'Reset',
        icon: const Icon(Icons.clear),
        onTap: (int index, String label, {String? value}) {
          controller.clear();
        },
      ),
    );
    //提交编辑的数据
    actionData.add(
      ActionData(
        label: 'Submit',
        icon: const Icon(Icons.save),
        onTap: (int index, String label, {String? value}) async {
          var html = await controller.getText();
          if (widget.onSubmit != null) {
            widget.onSubmit!(html, ChatMessageMimeType.html);
          }
        },
      ),
    );
    actionData.add(
      ActionData(
        label: 'Redo',
        icon: const Icon(Icons.redo),
        onTap: (int index, String label, {String? value}) {
          controller.redo();
        },
      ),
    );
    actionData.add(
      ActionData(
        label: 'Disable',
        icon: const Icon(Icons.disabled_by_default_outlined),
        onTap: (int index, String label, {String? value}) {
          controller.disable();
        },
      ),
    );
    actionData.add(
      ActionData(
        label: 'Enable',
        icon: const Icon(Icons.phone_enabled),
        onTap: (int index, String label, {String? value}) {
          controller.enable();
        },
      ),
    );
    actionData.add(
      ActionData(
        label: 'Insert Text',
        icon: const Icon(Icons.text_increase),
        onTap: (int index, String label, {String? value}) {
          controller.insertText('Google');
        },
      ),
    );
    actionData.add(
      ActionData(
        label: 'Insert HTML',
        icon: const Icon(Icons.html),
        onTap: (int index, String label, {String? value}) {
          controller
              .insertHtml('''<p style="color: blue">Google in blue</p>''');
        },
      ),
    );
    actionData.add(
      ActionData(
        label: 'Insert Link',
        icon: const Icon(Icons.link),
        onTap: (int index, String label, {String? value}) {
          controller.insertLink('Google linked', 'https://google.com', true);
        },
      ),
    );
    actionData.add(
      ActionData(
        label: 'Insert network image',
        icon: const Icon(Icons.image),
        onTap: (int index, String label, {String? value}) {
          controller.insertNetworkImage(
              'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png',
              filename: 'Google network image');
        },
      ),
    );
    actionData.add(
      ActionData(
        label: 'Info',
        icon: const Icon(Icons.info_outline),
        onTap: (int index, String label, {String? value}) {
          controller.addNotification(
              'Info notification', NotificationType.info);
        },
      ),
    );
    actionData.add(
      ActionData(
        label: 'Warning',
        icon: const Icon(Icons.warning_amber_outlined),
        onTap: (int index, String label, {String? value}) {
          controller.addNotification(
              'Warning notification', NotificationType.warning);
        },
      ),
    );
    actionData.add(
      ActionData(
        label: 'Success',
        icon: const Icon(Icons.check_circle_outline),
        onTap: (int index, String label, {String? value}) {
          controller.addNotification(
              'Success notification', NotificationType.success);
        },
      ),
    );
    actionData.add(
      ActionData(
        label: 'Danger',
        icon: const Icon(Icons.dangerous_outlined),
        onTap: (int index, String label, {String? value}) {
          controller.addNotification(
              'Danger notification', NotificationType.danger);
        },
      ),
    );
    actionData.add(
      ActionData(
        label: 'Plaintext',
        icon: const Icon(Icons.text_format),
        onTap: (int index, String label, {String? value}) {
          controller.addNotification(
              'Plaintext notification', NotificationType.plaintext);
        },
      ),
    );
    actionData.add(
      ActionData(
        label: 'Remove',
        icon: const Icon(Icons.remove_circle_outline),
        onTap: (int index, String label, {String? value}) {
          controller.removeNotification();
        },
      ),
    );
    actionData.add(
      ActionData(
        label: 'Toggle code view',
        icon: const Icon(Icons.toggle_on),
        onTap: (int index, String label, {String? value}) {
          controller.toggleCodeView();
        },
      ),
    );
    actionData.add(
      ActionData(
        label: 'Refresh',
        icon: const Icon(Icons.refresh),
        onTap: (int index, String label, {String? value}) {
          if (platformParams.web) {
            controller.reloadWeb();
          } else {
            controller.editorController!.reload();
          }
        },
      ),
    );

    return actionData;
  }

  Future<dynamic> _showActionCard(BuildContext context) {
    return SmartDialogUtil.popModalBottomSheet(context, builder: (context) {
      return Card(
          child: DataActionCard(
              // onPressed: (int index, String label, {String? value}) {
              //   _onAction(context!, index, label, value: value);
              // },
              showLabel: true,
              showTooltip: true,
              crossAxisCount: 3,
              actions: _buildActionData(),
              height: 360,
              width: 340,
              size: 20));
    });
  }

  Future<void> _onAction(BuildContext context, int index, String name,
      {String? value}) async {
    switch (name) {
      case 'Camera switch':
        break;
      case 'Microphone switch':
        break;
      case 'Speaker switch':
        break;
      case 'Volume increase':
        break;
      case 'Volume decrease':
        break;
      case 'Volume mute':
        break;
      case 'Zoom out':
        break;
      case 'Zoom in':
        break;
      case 'Close':
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!platformParams.web) {
          controller.clearFocus();
        }
      },
      onLongPress: () {
        _showActionCard(context);
      },
      child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          borderOnForeground: false,
          clipBehavior: Clip.none,
          //BeveledRectangleBorder,RoundedRectangleBorder,CircleBorder
          shape: const ContinuousRectangleBorder(),
          child: SingleChildScrollView(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _buildHtmlEditor(context),
                ]),
          )),
    );
  }
}
