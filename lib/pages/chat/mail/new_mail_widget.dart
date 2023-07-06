import 'dart:io';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/chat/mail/mail_address_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/document_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:colla_chat/widgets/richtext/platform_editor_widget.dart';
import 'package:cross_file/cross_file.dart';
import 'package:enough_mail/highlevel.dart';
import 'package:flutter/material.dart';
import 'package:mimecon/mimecon.dart';

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
  //已经选择的收件人
  ValueNotifier<List<String>> receipts = ValueNotifier([]);

  ValueNotifier<List<AttachmentInfo>> attachmentInfos =
      ValueNotifier<List<AttachmentInfo>>([]);

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

  //收件人，联系人显示和选择界面
  Widget _buildReceiptsWidget(BuildContext context) {
    var selector = ValueListenableBuilder(
        valueListenable: receipts,
        builder: (BuildContext context, List<String> receipts, Widget? child) {
          return Container(
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
              child: LinkmanGroupSearchWidget(
                key: UniqueKey(),
                selectType: SelectType.chipMultiSelectField,
                onSelected: (List<String>? selected) async {
                  if (selected != null) {
                    this.receipts.value = selected;
                  }
                },
                selected: this.receipts.value,
                includeGroup: false,
              ));
        });

    return selector;
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

  ///加附件
  void _addAttachment() {
    FileUtil.fullPicker(
        context: context,
        file: true,
        onSelectedFilenames: (filenames) async {
          if (filenames.isNotEmpty) {
            for (var filename in filenames) {
              File file = File(filename);
              await builder.addFile(
                  file, MediaType.guessFromFileName(filename));
            }
            List<AttachmentInfo> infos = [];
            infos.addAll(builder.attachments);
            attachmentInfos.value = infos;
          }
        });
  }

  ///删除附件
  _removeAttachment(AttachmentInfo info) {
    builder.removeAttachment(info);
    List<AttachmentInfo> infos = [];
    infos.addAll(builder.attachments);
    attachmentInfos.value = infos;
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
          _buildReceiptsWidget(context),
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
        alignment: Alignment.centerLeft,
        color: myself.getBackgroundColor(context).withOpacity(0.6),
        child: ValueListenableBuilder(
            valueListenable: attachmentInfos,
            builder: (BuildContext context,
                List<AttachmentInfo> attachmentInfos, Widget? child) {
              List<Widget> chips = [];
              for (var attachmentInfo in attachmentInfos) {
                String? name = attachmentInfo.name;
                int? size = attachmentInfo.size;
                MediaType mediaType = attachmentInfo.mediaType;
                String? mimeType = FileUtil.mimeType(name!);
                Widget icon = Mimecon(
                  mimetype: mimeType!,
                  color: myself.primary,
                  size: 32,
                  isOutlined: true,
                );
                var chip = Card(
                  elevation: 0.0,
                  //margin: const EdgeInsets.all(10.0),
                  child: Container(
                      padding: const EdgeInsets.all(5.0),
                      width: 150,
                      child: Column(children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            icon,
                            const Spacer(),
                            InkWell(
                                onTap: () {
                                  _removeAttachment(attachmentInfo);
                                },
                                child: Icon(Icons.cancel,
                                    size: 18, color: myself.primary)),
                          ],
                        ),
                        Text(
                          name ?? '',
                          softWrap: true,
                          overflow: TextOverflow.fade,
                          maxLines: 3,
                        ),
                        Text('$size'),
                      ])),
                );
                chips.add(chip);
              }
              if (chips.isNotEmpty) {
                return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: chips,
                    ));
              } else {
                return Container();
              }
            }));
  }

  ///发送邮件，首先将邮件的编辑部分转换成html格式，对邮件的各个组成部分加密，目标为多人时采用群加密方式，然后发送
  _send() {}

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [
      Tooltip(
          message: AppLocalizations.t('Attachment'),
          child: IconButton(
              onPressed: () {
                _addAttachment();
              },
              icon: const Icon(Icons.attach_file))),
      Tooltip(
          message: AppLocalizations.t('Send'),
          child: IconButton(
              onPressed: () {
                _send();
              },
              icon: const Icon(Icons.send))),
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
