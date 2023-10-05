import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/emailaddress.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/chat/mail/mail_mime_message_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/emailaddress.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:colla_chat/widgets/richtext/platform_editor_widget.dart';
import 'package:enough_mail/highlevel.dart';
import 'package:flutter/material.dart';
import 'package:mimecon/mimecon.dart';

class PlatformAttachmentInfo {
  PlatformAttachmentInfo(
      {required this.filename,
      required this.mediaType,
      required this.name,
      required this.size});

  final String filename;

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

  @override
  initState() {
    mailMimeMessageController.addListener(_update);
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
                  filename: filename,
                  name: FileUtil.filename(filename),
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
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(children: [
          _buildReceiptsWidget(context),
          const SizedBox(
            height: 5.0,
          ),
          CommonTextFormField(
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
                    child: Expanded(
                        child: Row(
                      children: chips,
                    )));
              } else {
                return Container();
              }
            }));
  }

  /// 发送前的准备，准备数据和地址，加密
  /// 发送到目标的peerId对应的linkman的邮件地址，加密采用对方的peerId进行加密
  /// 对方需要解密的话，需要绑定正确的邮件地址和登录peerId
  Future<String?> _preSend(MessageBuilder builder,
      {bool needEncrypt = true}) async {
    List<MailAddress> from = [];
    MailAddress? sender;
    EmailAddress? current = mailMimeMessageController.current;
    String? email;
    if (current != null) {
      email = current.email;
      sender = MailAddress(null, email);
      from.add(sender);
    }
    builder.from = from;
    builder.sender = sender;

    List<MailAddress> to = [];
    List<String> peerIds = receipts.value;
    if (peerIds.isNotEmpty) {
      for (String peerId in peerIds) {
        Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
        if (linkman != null) {
          String name = linkman.name;
          String? email = linkman.email;
          if (email != null) {
            to.add(MailAddress(null, email));
          }
        }
      }
    }
    builder.to = to;

    List<int>? secretKey;
    if (needEncrypt) {
      PlatformEncryptData? encryptedSubject = await emailAddressService.encrypt(
          CryptoUtil.stringToUtf8(subjectController.text), receipts.value);
      if (encryptedSubject == null) {
        return null;
      }
      String subject = CryptoUtil.encodeBase64(encryptedSubject.data);
      //加前后缀表示加密

      secretKey = encryptedSubject.secretKey;
      Map<String, String>? payloadKeys = encryptedSubject.payloadKeys;
      //表示群加密
      if (payloadKeys != null) {
        var payloadKeysStr = JsonUtil.toJsonString(payloadKeys);
        builder.subject = '$subject#{$payloadKeysStr}';
      } else {
        builder.subject = '$subject#{}';
      }
    } else {
      builder.subject = subjectController.text;
    }

    String? html = await platformEditorController.html;
    if (html != null) {
      if (needEncrypt) {
        PlatformEncryptData? encryptedHtml = await emailAddressService.encrypt(
            CryptoUtil.stringToUtf8(html), receipts.value,
            secretKey: secretKey);
        if (encryptedHtml != null) {
          builder.addText(CryptoUtil.encodeBase64(encryptedHtml.data));
        }
      } else {
        builder.addTextHtml(html);
      }
    }

    for (PlatformAttachmentInfo attachmentInfo in attachmentInfos.value) {
      String filename = attachmentInfo.filename;
      File file = File(filename);
      bool exists = await file.exists();
      if (exists) {
        Uint8List bytes = file.readAsBytesSync();

        if (needEncrypt) {
          PlatformEncryptData? encryptedAttachment = await emailAddressService
              .encrypt(bytes, receipts.value, secretKey: secretKey);
          if (encryptedAttachment != null) {
            builder.addBinary(Uint8List.fromList(encryptedAttachment.data),
                MediaType.guessFromFileName(filename),
                filename: filename);
          }
        } else {
          builder.addBinary(bytes, MediaType.guessFromFileName(filename));
        }
      }
    }

    return email;
  }

  _draft() async {
    DialogUtil.loadingShow(context);

    ///邮件消息的构造器
    MessageBuilder builder =
        MessageBuilder.prepareMultipartAlternativeMessage();
    String? email = await _preSend(builder, needEncrypt: true);
    if (email != null) {
      MimeMessage mimeMessage = builder.buildMimeMessage();

      EmailClient? emailClient = emailClientPool.get(email);
      if (emailClient != null) {
        bool success = false;
        Mailbox? drafts = emailClient.getMailbox(MailboxFlag.drafts);
        if (drafts != null) {
          UidResponseCode? responseCode = await emailClient
              .saveDraftMessage(mimeMessage, draftsMailbox: drafts);
          if (responseCode != null) {
            success = true;
          }
        }
        if (mounted) {
          if (success) {
            DialogUtil.info(context, content: 'draft message successfully');
          } else {
            DialogUtil.error(context, content: 'draft message failure');
          }
        }
      }
    }
    if (mounted) {
      DialogUtil.loadingHide(context);
    }

    indexWidgetProvider.pop();
  }

  ///发送邮件，首先将邮件的编辑部分转换成html格式，对邮件的各个组成部分加密，目标为多人时采用群加密方式，然后发送
  _send() async {
    DialogUtil.loadingShow(context);

    ///邮件消息的构造器
    MessageBuilder builder =
        MessageBuilder.prepareMultipartAlternativeMessage();
    String? email = await _preSend(builder, needEncrypt: true);
    if (email != null) {
      MimeMessage mimeMessage = builder.buildMimeMessage();

      EmailClient? emailClient = emailClientPool.get(email);
      if (emailClient != null) {
        bool success = false;

        ///目前采用smtp直接发送，email客户端目前有小bug，能发送，但是会报异常
        success = await emailClient.smtpSend(mimeMessage, from: builder.sender);
        // success =
        //     await emailClient.sendMessage(mimeMessage);
        if (mounted) {
          if (success) {
            DialogUtil.info(context, content: 'send message successfully');
          } else {
            DialogUtil.error(context, content: 'send message failure');
          }
        }
      }
    }
    if (mounted) {
      DialogUtil.loadingHide(context);
    }

    indexWidgetProvider.pop();
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
    mailMimeMessageController.removeListener(_update);
    super.dispose();
  }
}
