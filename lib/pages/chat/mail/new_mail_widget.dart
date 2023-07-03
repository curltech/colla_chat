import 'dart:io';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/pages/chat/mail/mail_address_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/document_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/richtext/platform_editor_widget.dart';
import 'package:enough_mail/highlevel.dart';
import 'package:flutter/material.dart';

///邮件内容子视图
class NewMailWidget extends StatefulWidget with TileDataMixin {
  const NewMailWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NewMailWidgetState();

  @override
  String get routeName => 'new_mail';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.attach_email;

  @override
  String get title => 'New mail';
}

class _NewMailWidgetState extends State<NewMailWidget> {
  ///邮件消息的构造器
  MessageBuilder builder = MessageBuilder.prepareMultipartAlternativeMessage();

  @override
  initState() {
    mailAddressController.addListener(_update);
    super.initState();
  }

  _update() {}

  /// html编辑完成，草案原始格式暂存到chatMessage中
  _onSubmit(String? content, ChatMessageMimeType mimeType) {
    if (content != null) {
      String html = content;
      if (mimeType == ChatMessageMimeType.json) {
        List<dynamic> deltaJson = JsonUtil.toJson(content);
        html = DocumentUtil.jsonToHtml(deltaJson);
      }
      _addTextHtml(html);
    }
  }

  ///设置邮件的地址和主题
  void _buildMailSubject({
    List<MailAddress>? from,
    List<MailAddress>? to,
    MailAddress? sender,
    List<MailAddress>? cc,
    List<MailAddress>? bcc,
    String? subject,
  }) {
    builder.from = from;
    builder.to = to;
    builder.sender = sender;
    builder.cc = cc;
    builder.bcc = bcc;
    builder.subject = subject;
  }

  PartBuilder _addTextHtml(String html) {
    return builder.addTextHtml(html);
  }

  PartBuilder _addText(String text) {
    return builder.addText(text);
  }

  PartBuilder _addTextPlain(String text) {
    return builder.addTextPlain(text);
  }

  ValueNotifier<List<PartBuilder>> attachmentPartBuilders =
      ValueNotifier<List<PartBuilder>>([]);

  ///设置邮件的地址和主题
  void _buildMessageAttachment() {
    List<PartBuilder> attachments = [];
    FileUtil.fullPicker(
        context: context,
        file: true,
        onSelectedFilenames: (filenames) async {
          if (filenames.isNotEmpty) {
            for (var filename in filenames) {
              File file = File(filename);
              PartBuilder partBuilder = await builder.addFile(
                  file, MediaSubtype.applicationPdf.mediaType);
              attachments.add(partBuilder);
            }
          }
        });
    attachmentPartBuilders.value = [...attachments];
  }

  _removePartBuilder(List<PartBuilder> partBuilders) {
    for (var partBuilder in partBuilders) {
      builder.removePart(partBuilder);
    }
  }

  final ColumnFieldController receiptColumnFieldController =
      ColumnFieldController(ColumnFieldDef(
    name: 'receipt',
    label: 'Receipt',
    cancel: true,
  ));
  final ColumnFieldController subjectColumnFieldController =
      ColumnFieldController(ColumnFieldDef(
    name: 'subject',
    label: 'Subject',
    cancel: true,
  ));

  _buildMailSubjectWidget() {
    return Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(children: [
          ColumnFieldWidget(
            controller: receiptColumnFieldController,
          ),
          const SizedBox(
            height: 10.0,
          ),
          ColumnFieldWidget(
            controller: subjectColumnFieldController,
          )
        ]));
  }

  /// html编辑器
  Widget _buildEnoughHtmlEditorWidget(BuildContext context) {
    PlatformEditorWidget platformEditorWidget = PlatformEditorWidget(
      onSubmit: _onSubmit,
    );

    return platformEditorWidget;
  }

  /// 附件显示区
  Widget _buildAttachmentChips(BuildContext context) {
    return Container(
        color: myself.getBackgroundColor(context).withOpacity(0.6),
        height: 100,
        child: ValueListenableBuilder(
            valueListenable: attachmentPartBuilders,
            builder: (BuildContext context,
                List<PartBuilder> attachmentPartBuilders, Widget? child) {
              List<Chip> chips = [];
              for (var partBuilder in attachmentPartBuilders) {
                String? name = partBuilder.attachments.first.name;
                int? size = partBuilder.attachments.first.size;

                var chip = Chip(
                  label: CommonAutoSizeText(
                    name ?? '',
                    style: const TextStyle(color: Colors.black),
                  ),
                  //avatar: option.leading,
                  backgroundColor: Colors.white,
                  deleteIconColor: myself.primary,
                  onDeleted: () {},
                );
                chips.add(chip);
              }
              if (chips.isNotEmpty) {
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: chips,
                );
              } else {
                return Container();
              }
            }));
  }

  ///发送邮件，首先将邮件的编辑部分转换成html格式，对邮件的各个组成部分加密，目标为多人时采用群加密方式，然后发送
  _send(){

  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [
      IconButton(onPressed: () {
        _send();
      }, icon: const Icon(Icons.send)),
    ];
    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        rightWidgets: rightWidgets,
        child: Column(children: [
          _buildMailSubjectWidget(),
          Expanded(child: _buildEnoughHtmlEditorWidget(context)),
          _buildAttachmentChips(context),
        ]));
    return appBarView;
  }

  @override
  void dispose() {
    mailAddressController.removeListener(_update);
    super.dispose();
  }
}
