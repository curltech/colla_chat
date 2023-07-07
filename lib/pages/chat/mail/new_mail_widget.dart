import 'dart:io';
import 'dart:typed_data';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/emailaddress.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/chat/mail/mail_address_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/emailaddress.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/document_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:colla_chat/widgets/richtext/platform_editor_widget.dart';
import 'package:enough_mail/highlevel.dart';
import 'package:flutter/material.dart';
import 'package:mimecon/mimecon.dart';

class PlatformAttachmentInfo {
  PlatformAttachmentInfo(
      {required this.mediaType, required this.name, required this.size});

  /// The name of the attachment
  final String name;

  /// The size of the attachment in bytes
  final int size;

  /// The media type
  final MediaType mediaType;
}

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

  ValueNotifier<List<PlatformAttachmentInfo>> attachmentInfos =
      ValueNotifier<List<PlatformAttachmentInfo>>([]);

  TextEditingController subjectController = TextEditingController();

  PlatformEditorController platformEditorController =
      PlatformEditorController();

  ///邮件消息的构造器
  MessageBuilder builder = MessageBuilder.prepareMultipartAlternativeMessage();

  @override
  initState() {
    mailAddressController.addListener(_update);
    super.initState();
  }

  _update() {}

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
  Future<void> _buildMailSubject({
    List<MailAddress>? from,
    List<MailAddress>? to,
    MailAddress? sender,
    List<MailAddress>? cc,
    List<MailAddress>? bcc,
    String? subject,
  }) async {
    builder.from = from;
    builder.to = to;
    builder.sender = sender;
    builder.cc = cc;
    builder.bcc = bcc;

    Map<String, List<int>> encryptSubjects = await emailAddressService.encrypt(
        CryptoUtil.stringToUtf8(subject!), receipts.value);

    builder.subject = subject;
  }

  ///如果是正式发送html
  Future<PartBuilder> _addTextHtml(String html) async {
    Map<String, List<int>> encryptSubjects = await emailAddressService.encrypt(
        CryptoUtil.stringToUtf8(html), receipts.value);

    return builder.addTextHtml(html);
  }

  ///如果是草案json字符串
  PartBuilder _addText(String content) {
    return builder.addText(content);
  }

  PartBuilder _addTextPlain(String text) {
    return builder.addTextPlain(text);
  }

  ///加附件
  Future<void> _addAttachments() async {
    if (attachmentInfos.value.isNotEmpty) {
      for (var attachmentInfo in attachmentInfos.value) {
        String filename = attachmentInfo.name;
        File file = File(attachmentInfo.name);
        Uint8List data = file.readAsBytesSync();

        ///加密
        Map<String, List<int>> encryptSubjects =
            await emailAddressService.encrypt(data, receipts.value);

        builder.addBinary(data, MediaType.guessFromFileName(filename));
      }
    }
  }

  ///加附件信息
  void _addAttachmentInfo() {
    FileUtil.fullPicker(
        context: context,
        file: true,
        onSelectedFilenames: (filenames) async {
          if (filenames.isNotEmpty) {
            List<PlatformAttachmentInfo> infos = [];
            for (var filename in filenames) {
              File file = File(filename);
              int size = await file.length();
              PlatformAttachmentInfo info = PlatformAttachmentInfo(
                  mediaType: MediaType.guessFromFileName(filename),
                  name: filename,
                  size: size);
              infos.add(info);
            }
            attachmentInfos.value = infos;
          }
        });
  }

  ///删除附件信息
  _removeAttachment(PlatformAttachmentInfo info) {
    List<PlatformAttachmentInfo> infos = [];
    attachmentInfos.value.remove(info);
    infos.addAll(attachmentInfos.value);
    attachmentInfos.value = infos;
  }

  _buildMailSubjectWidget() {
    return Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(children: [
          _buildReceiptsWidget(context),
          const SizedBox(
            height: 10.0,
          ),
          CommonAutoSizeTextFormField(
              controller: subjectController,
              labelText: AppLocalizations.t('Subject'))
        ]));
  }

  /// html编辑器
  Widget _buildEnoughHtmlEditorWidget(BuildContext context) {
    PlatformEditorWidget platformEditorWidget = PlatformEditorWidget(
      platformEditorController: platformEditorController,
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
                List<PlatformAttachmentInfo> attachmentInfos, Widget? child) {
              List<Widget> chips = [];
              for (var attachmentInfo in attachmentInfos) {
                String name = attachmentInfo.name;
                int? size = attachmentInfo.size;
                MediaType mediaType = attachmentInfo.mediaType;
                String? mimeType = FileUtil.mimeType(name);
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

  ///发送前的准备，准备数据和地址
  Future<String?> _preSend() async {
    List<MailAddress> from = [];
    MailAddress? sender;
    EmailAddress? current = mailAddressController.current;
    String? email;
    if (current != null) {
      email = current.email;
      sender = MailAddress(current.name, email);
      from.add(sender);
    }

    List<MailAddress> to = [];
    List<String> peerIds = receipts.value;
    if (peerIds.isNotEmpty) {
      for (String peerId in peerIds) {
        Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
        if (linkman != null) {
          String name = linkman.name;
          String? email = linkman.email;
          if (email != null) {
            to.add(MailAddress(name, email));
          }
        }
      }
    }
    _buildMailSubject(
        from: from, sender: sender, to: to, subject: subjectController.text);

    await _addAttachments();

    return email;
  }

  _draft() async {
    String? email = await _preSend();
    String? content = await platformEditorController.content;
    if (content != null) {
      _addText(content);
    }

    MimeMessage mimeMessage = builder.buildMimeMessage();
    if (email != null) {
      EmailClient? emailClient = emailClientPool.get(email);
      if (emailClient != null) {
        Mailbox? drafts = emailClient.getMailbox(MailboxFlag.drafts);
        emailClient.sendMessage(mimeMessage,
            sentMailbox: drafts, appendToSent: false);
      }
    }
  }

  ///发送邮件，首先将邮件的编辑部分转换成html格式，对邮件的各个组成部分加密，目标为多人时采用群加密方式，然后发送
  _send() async {
    String? email = await _preSend();
    String? html = await platformEditorController.html;
    if (html != null) {
      _addTextHtml(html);
    }

    MimeMessage mimeMessage = builder.buildMimeMessage();
    if (email != null) {
      EmailClient? emailClient = emailClientPool.get(email);
      if (emailClient != null) {
        emailClient.sendMessage(mimeMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [
      Tooltip(
          message: AppLocalizations.t('Attachment'),
          child: IconButton(
              onPressed: () {
                _addAttachmentInfo();
              },
              icon: const Icon(Icons.attach_file))),
      Tooltip(
          message: AppLocalizations.t('Draft'),
          child: IconButton(
              onPressed: () {
                _draft();
              },
              icon: const Icon(Icons.drafts))),
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
