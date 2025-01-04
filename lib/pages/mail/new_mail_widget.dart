import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/mail/mail_address.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/mail/mail_mime_message_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/mail/mail_address.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:colla_chat/widgets/richtext/platform_editor_widget.dart';
import 'package:enough_mail/highlevel.dart' as enough_mail;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mimecon/mimecon.dart';

class PlatformAttachmentInfo {
  PlatformAttachmentInfo(
      {required this.filename,
      required this.mediaType,
      required this.name,
      required this.data,
      required this.size});

  final String filename;

  /// The name of the attachment
  final String name;

  final Uint8List data;

  /// The size of the attachment in bytes
  final int size;

  /// The media type
  final enough_mail.MediaType mediaType;
}

///邮件内容子视图
class NewMailWidget extends StatelessWidget with TileDataMixin {
  NewMailWidget({super.key});

  @override
  String get routeName => 'new_mail';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.attach_email;

  @override
  String get title => 'New mail';

  //已经选择的收件人
  final RxList<String> receipts = RxList([]);

  final RxList<PlatformAttachmentInfo> attachmentInfos =
      RxList<PlatformAttachmentInfo>([]);

  final TextEditingController subjectController = TextEditingController();

  final PlatformEditorController platformEditorController =
      PlatformEditorController();

  //收件人，联系人显示和选择界面
  Widget _buildReceiptsWidget(BuildContext context) {
    var selector = Obx(() {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: LinkmanGroupSearchWidget(
            key: UniqueKey(),
            selectType: SelectType.chipMultiSelectField,
            onSelected: (List<String>? selected) async {
              if (selected != null) {
                receipts.value = selected;
              }
            },
            selected: receipts.value,
            includeGroup: false,
          ));
    });

    return selector;
  }

  ///加附件信息
  void _addAttachmentInfo(BuildContext context) {
    FileUtil.fullPicker(
        context: context,
        file: true,
        onSelectedFilenames: (filenames) async {
          if (filenames.isNotEmpty) {
            List<PlatformAttachmentInfo> infos = [];
            for (var filename in filenames) {
              File file = File(filename);
              int size = await file.length();
              Uint8List data = file.readAsBytesSync();
              PlatformAttachmentInfo info = PlatformAttachmentInfo(
                  mediaType: enough_mail.MediaType.guessFromFileName(filename),
                  filename: filename,
                  name: FileUtil.filename(filename),
                  data: data,
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

  _buildMailSubjectWidget(BuildContext context) {
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

  Future<Widget?> _buildAttachmentInfoWidget(
      PlatformAttachmentInfo attachmentInfo) async {
    if (attachmentInfo.mediaType.isImage) {
      Widget image = ImageUtil.buildMemoryImageWidget(
          height: 100, width: 100, attachmentInfo.data);

      return Center(child: image);
    }

    return null;
  }

  Future<List<Widget>?> _buildAttachmentChips(BuildContext context,
      List<PlatformAttachmentInfo> attachmentInfos) async {
    List<Widget> chips = [];
    for (var attachmentInfo in attachmentInfos) {
      String name = attachmentInfo.name;
      int? size = attachmentInfo.size;
      enough_mail.MediaType mediaType = attachmentInfo.mediaType;
      String? mimeType = FileUtil.mimeType(name);
      Widget? icon = await _buildAttachmentInfoWidget(attachmentInfo);
      size = attachmentInfo.size;
      icon ??= Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Mimecon(
          mimetype: mimeType ?? 'bin',
          color: myself.primary,
          size: 32,
          isOutlined: true,
        ),
        CommonAutoSizeText(
          name,
          softWrap: true,
          overflow: TextOverflow.fade,
          maxLines: 3,
        ),
        CommonAutoSizeText('${size % 1024}KB'),
      ]);
      var chip = Card(
        elevation: 0.0,
        shape: const ContinuousRectangleBorder(),
        color: Colors.grey.withOpacity(0.2),
        child: Container(
            padding: const EdgeInsets.all(0.0),
            height: 100,
            width: 120,
            child: Stack(
              children: [
                icon,
                InkWell(
                    onTap: () {
                      _removeAttachment(attachmentInfo);
                    },
                    child: Icon(Icons.cancel, size: 18, color: myself.primary)),
              ],
            )),
      );
      chips.add(chip);
    }

    return chips;
  }

  /// 附件显示区
  Widget _buildAttachmentWidget(BuildContext context) {
    return Container(
        alignment: Alignment.centerLeft,
        color: myself.getBackgroundColor(context).withOpacity(0.6),
        child: Obx(() {
          return PlatformFutureBuilder(
              future: _buildAttachmentChips(context, attachmentInfos),
              builder: (BuildContext context, List<Widget>? chips) {
                return Container(
                    alignment: Alignment.centerLeft,
                    color: myself.getBackgroundColor(context).withOpacity(0.6),
                    child: Wrap(
                      direction: Axis.horizontal,
                      children: chips!,
                    ));
              });
        }));
  }

  /// 发送前的准备，准备数据和地址，加密
  /// 发送到目标的peerId对应的linkman的邮件地址，加密采用对方的peerId进行加密
  /// 对方需要解密的话，需要绑定正确的邮件地址和登录peerId
  Future<String?> _preSend(enough_mail.MessageBuilder builder,
      {bool needEncrypt = true}) async {
    List<enough_mail.MailAddress> from = [];
    enough_mail.MailAddress? sender;
    MailAddress? current = mailAddressController.current;
    String? email;
    String? name;
    if (current != null) {
      email = current.email;
      name = current.name;
      sender = enough_mail.MailAddress(name, email);
      from.add(sender);
    }
    builder.from = from;
    builder.sender = sender;

    List<enough_mail.MailAddress> to = [];
    List<String> peerIds = receipts.value;
    if (peerIds.isNotEmpty) {
      for (String peerId in peerIds) {
        Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
        if (linkman != null) {
          String name = linkman.name;
          String? email = linkman.email;
          if (email != null) {
            to.add(enough_mail.MailAddress(name, email));
          }
        }
      }
    }
    builder.to = to;

    List<int>? secretKey;
    if (needEncrypt) {
      peerIds = [...peerIds];
      if (!peerIds.contains(myself.peerId)) {
        peerIds.add(myself.peerId!);
      }
      PlatformEncryptData? encryptedSubject = await mailAddressService.encrypt(
          CryptoUtil.stringToUtf8(subjectController.text), peerIds);
      String subject = CryptoUtil.encodeBase64(encryptedSubject!.data);
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
        PlatformEncryptData? encryptedHtml = await mailAddressService.encrypt(
            CryptoUtil.stringToUtf8(html), peerIds,
            secretKey: secretKey);
        builder.addText(CryptoUtil.encodeBase64(encryptedHtml!.data));
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
          PlatformEncryptData? encryptedAttachment = await mailAddressService
              .encrypt(bytes, peerIds, secretKey: secretKey);
          builder.addBinary(Uint8List.fromList(encryptedAttachment!.data),
              enough_mail.MediaType.guessFromFileName(filename),
              filename: filename);
        } else {
          builder.addBinary(
              bytes, enough_mail.MediaType.guessFromFileName(filename));
        }
      }
    }

    return email;
  }

  _draft(BuildContext context) async {
    DialogUtil.loadingShow();

    ///邮件消息的构造器
    enough_mail.MessageBuilder builder =
        enough_mail.MessageBuilder.prepareMultipartAlternativeMessage();
    String? email = await _preSend(builder, needEncrypt: true);
    if (email != null) {
      enough_mail.MimeMessage mimeMessage = builder.buildMimeMessage();

      EmailClient? emailClient = emailClientPool.get(email);
      if (emailClient != null) {
        bool success = false;
        enough_mail.Mailbox? drafts =
            emailClient.getMailbox(enough_mail.MailboxFlag.drafts);
        if (drafts != null) {
          enough_mail.UidResponseCode? responseCode = await emailClient
              .saveDraftMessage(mimeMessage, draftsMailbox: drafts);
          if (responseCode != null) {
            success = true;
          }
        }

        if (success) {
          DialogUtil.info(content: 'draft message successfully');
        } else {
          DialogUtil.error(content: 'draft message failure');
        }
      }
    }
    DialogUtil.loadingHide();

    indexWidgetProvider.pop();
  }

  ///发送邮件，首先将邮件的编辑部分转换成html格式，对邮件的各个组成部分加密，目标为多人时采用群加密方式，然后发送
  _send(BuildContext context) async {
    DialogUtil.loadingShow();

    ///邮件消息的构造器
    enough_mail.MessageBuilder builder =
        enough_mail.MessageBuilder.prepareMultipartAlternativeMessage();
    String? email = await _preSend(builder, needEncrypt: true);
    if (email != null) {
      enough_mail.MimeMessage mimeMessage = builder.buildMimeMessage();

      EmailClient? emailClient = emailClientPool.get(email);
      if (emailClient != null) {
        bool success = false;

        ///目前采用smtp直接发送，email客户端目前有小bug，能发送，但是会报异常
        success = await emailClient.smtpSend(mimeMessage, from: builder.sender);
        // success =
        //     await emailClient.sendMessage(mimeMessage);
        if (success) {
          DialogUtil.info(content: 'send message successfully');
        } else {
          DialogUtil.error(content: 'send message failure');
        }
      }
    }
    DialogUtil.loadingHide();

    indexWidgetProvider.pop();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [
      Tooltip(
          message: AppLocalizations.t('Attachment'),
          child: IconButton(
              onPressed: () {
                _addAttachmentInfo(context);
              },
              icon: const Icon(Icons.attach_file))),
      Tooltip(
          message: AppLocalizations.t('Draft'),
          child: IconButton(
              onPressed: () {
                _draft(context);
              },
              icon: const Icon(Icons.drafts))),
      Tooltip(
          message: AppLocalizations.t('Send'),
          child: IconButton(
              onPressed: () {
                _send(context);
              },
              icon: const Icon(Icons.send))),
    ];
    var appBarView = AppBarView(
        title: title,
        withLeading: withLeading,
        rightWidgets: rightWidgets,
        child: Column(children: [
          _buildMailSubjectWidget(context),
          Expanded(child: _buildEnoughHtmlEditorWidget(context)),
          _buildAttachmentWidget(context),
        ]));
    return appBarView;
  }
}
