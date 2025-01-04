import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/mail/mail_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/mail/full_screen_attachment_widget.dart';
import 'package:colla_chat/pages/mail/mail_mime_message_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/mail/mail_address.dart';
import 'package:colla_chat/service/mail/mail_message.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/webview/platform_webview.dart';
import 'package:enough_mail/highlevel.dart';
import 'package:enough_mail_flutter/enough_mail_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mimecon/mimecon.dart';

///邮件内容子视图
class MailContentWidget extends StatelessWidget with TileDataMixin {
  MailContentWidget({super.key}) {
    FullScreenAttachmentWidget fullScreenAttachmentWidget =
        const FullScreenAttachmentWidget();
    indexWidgetProvider.define(fullScreenAttachmentWidget);
  }

  @override
  String get routeName => 'mail_content';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.attach_email;

  @override
  String get title => 'MailContent';

  // late final PlatformWebView? platformWebView;
  final PlatformWebViewController platformWebViewController =
      PlatformWebViewController();

  ///移动平台采用MimeMessage显示
  ///非windows平台直接使用html显示
  ///windows平台需要先转换成文件，防止乱码

  ///当前的邮件发生变化，如果没有获取内容，则获取内容
  Future<DecryptedMimeMessage?> _buildMimeMessage() async {
    MailMessage? mailMessage = mailMimeMessageController.currentMailMessage;
    if (mailMessage == null) {
      return null;
    }
    MimeMessage? mimeMessage;
    if (mailMessage.status != FetchPreference.full.name) {
      List<MimeMessage>? mimeMessages = await mailMimeMessageController
          .fetchMessageSequence([mailMessage.uid]);
      if (mimeMessages == null || mimeMessages.isEmpty) {
        mimeMessage = await mailMimeMessageController.convert(mailMessage);
      } else {
        mimeMessage = mimeMessages.first;
        mailMessageService.storeMimeMessage(
            mailAddressController.current!.email,
            mailboxController.currentMailbox!,
            mimeMessage,
            FetchPreference.full,
            force: true);
      }
    } else {
      mimeMessage = await mailMimeMessageController.convert(mailMessage);
    }

    final DecryptedMimeMessage decryptedMimeMessage;
    if (mimeMessage == null) {
      decryptedMimeMessage = DecryptedMimeMessage();
    } else {
      decryptedMimeMessage =
          await mailMimeMessageController.decryptMimeMessage(mimeMessage);
    }

    return decryptedMimeMessage;
  }

  Widget _buildSubjectWidget(DecryptedMimeMessage decryptedMimeMessage) {
    var subtitle = decryptedMimeMessage.subject;
    MailAddress? sender = decryptedMimeMessage.sender;
    var title = sender?.personalName;
    title = title ?? '';
    var email = sender?.email;
    email = email ?? '';
    title = '$title[$email]';
    var sendTime = decryptedMimeMessage.sendTime;
    var titleTail = '';
    if (sendTime != null) {
      titleTail = DateUtil.formatEasyRead(sendTime);
    }
    TileData tileData = TileData(
        prefix: decryptedMimeMessage.needDecrypt
            ? const Icon(
                Icons.mail_lock,
                color: Colors.yellow,
              )
            : null,
        title: title,
        titleTail: titleTail,
        subtitle: subtitle.toString());

    return DataListTile(tileData: tileData);
  }

  ///邮件内容发生变化时，移动平台将重新创建mimeMessageViewer
  ///桌面平台将利用现有的webview重新装载html内容
  Widget _buildMimeMessageViewer(
      BuildContext context, DecryptedMimeMessage decryptedMimeMessage) {
    if (decryptedMimeMessage.html == null) {
      return Center(
          child: Column(children: [
        Text(AppLocalizations.t('The message is no content')),
        const SizedBox(
          height: 15.0,
        ),
        IconButton(
            onPressed: () {
              //setState(() {});
            },
            icon: Icon(
              Icons.refresh,
              color: myself.primary,
            ))
      ]));
    }
    Widget webView = nil;
    try {
      webView = Center(
          child: PlatformWebView(
        html: decryptedMimeMessage.html,
        inline: true,
        webViewController: platformWebViewController,
      ));
    } catch (e) {
      logger.e('PlatformWebView failure:$e');
    }
    Widget mailAttachmentWidget = MailAttachmentWidget(
      decryptedMimeMessage: decryptedMimeMessage,
    );

    return Column(mainAxisSize: MainAxisSize.min, children: [
      _buildSubjectWidget(decryptedMimeMessage),
      const Divider(),
      Expanded(child: webView),
      mailAttachmentWidget,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Widget mimeMessageViewer = PlatformFutureBuilder(
          future: _buildMimeMessage(),
          builder: (BuildContext context,
              DecryptedMimeMessage? decryptedMimeMessage) {
            var appBarView = AppBarView(
                titleWidget:
                    CommonAutoSizeText(decryptedMimeMessage?.subject ?? ''),
                withLeading: withLeading,
                child: Card(
                    elevation: 0.0,
                    shape: const ContinuousRectangleBorder(),
                    margin: EdgeInsets.zero,
                    child: SizedBox(
                        width: double.infinity,
                        child: _buildMimeMessageViewer(
                            context, decryptedMimeMessage!))));
            return appBarView;
          });

      return mimeMessageViewer;
    });
  }
}

class MailAttachmentWidget extends StatelessWidget {
  final DecryptedMimeMessage decryptedMimeMessage;

  const MailAttachmentWidget({super.key, required this.decryptedMimeMessage});

  Future<Widget?> _buildMediaProviderWidget(MediaProvider mediaProvider) async {
    if (mediaProvider.isImage) {
      MemoryMediaProvider memoryMediaProvider =
          await mediaProvider.toMemoryProvider();
      Widget image = ImageUtil.buildMemoryImageWidget(
          height: 100, width: 100, memoryMediaProvider.data);

      return Center(child: image);
    }

    return null;
  }

  ///获取当前邮件的附件目录信息，用于展示
  Future<List<ContentInfo>?> findContentInfos() async {
    MailMessage? mailMessage = mailMimeMessageController.currentMailMessage;
    if (mailMessage == null) {
      return null;
    }
    MimeMessage? mimeMessage =
        await mailMimeMessageController.convert(mailMessage);
    if (mimeMessage == null) {
      return null;
    }
    bool hasAttachment = mimeMessage.hasAttachmentsOrInlineNonTextualParts();
    if (!hasAttachment) {
      return null;
    }
    final List<ContentInfo> infos =
        mimeMessage.findContentInfo(disposition: ContentDisposition.attachment);

    return infos;
  }

  ///根据fetchId获取当前邮件的特定附件数据
  Future<MediaProvider?> findAttachmentMediaProvider(String fetchId) async {
    MailMessage? mailMessage = mailMimeMessageController.currentMailMessage;
    if (mailMessage == null) {
      return null;
    }
    MimeMessage? mimeMessage =
        await mailMimeMessageController.convert(mailMessage);
    if (mimeMessage == null) {
      return null;
    }
    MimePart? mimePart = mimeMessage.getPart(fetchId);
    //如果附件还未获取，则获取
    mimePart ??= await mailMimeMessageController.fetchMessagePart(fetchId);
    if (mimePart == null) {
      return null;
    }

    ///获取附件的内容，文本内容或者二进制内容
    final filename = mimePart.decodeFileName();
    final mediaType = mimePart.mediaType.text;
    if (mimePart.mediaType.isText) {
      String? text = mimePart.decodeContentText();
      if (text != null) {
        if (decryptedMimeMessage.needDecrypt) {
          try {
            List<int>? data = await mailAddressService.decrypt(
                CryptoUtil.stringToUtf8(text),
                payloadKey: decryptedMimeMessage.payloadKey);
            text = CryptoUtil.utf8ToString(data!);
          } catch (e) {
            logger.e('filename:$filename decrypt failure:$e');
          }
        }
        return TextMediaProvider(filename!, mediaType, text!,
            description: decryptedMimeMessage.subject);
      }
    } else {
      List<int>? data = mimePart.decodeContentBinary();
      if (data != null) {
        if (decryptedMimeMessage.needDecrypt) {
          try {
            data = await mailAddressService.decrypt(data,
                payloadKey: decryptedMimeMessage.payloadKey);
          } catch (e) {
            logger.e('filename:$filename decrypt failure:$e');
          }
        }
        return MemoryMediaProvider(
            filename!, mediaType, Uint8List.fromList(data!),
            description: decryptedMimeMessage.subject);
      }
    }
    return null;
  }

  /// 附件显示区
  Future<List<Widget>?> _buildAttachmentChips(BuildContext context) async {
    List<ContentInfo>? contentInfos = await findContentInfos();
    if (contentInfos == null || contentInfos.isEmpty) {
      return null;
    }
    List<Widget> chips = [];
    for (ContentInfo contentInfo in contentInfos) {
      String? fileName = contentInfo.fileName;
      fileName = fileName ?? AppLocalizations.t('Unknown filename');
      fileName = FileUtil.filename(fileName);
      int? size = contentInfo.size;
      MediaType? mediaType = contentInfo.mediaType;
      String? mimeType = FileUtil.mimeType(fileName);
      Widget? icon;
      String fetchId = contentInfo.fetchId;
      MediaProvider? mediaProvider = await findAttachmentMediaProvider(fetchId);
      if (mediaProvider != null) {
        icon = await _buildMediaProviderWidget(mediaProvider);
        size = mediaProvider.size;
      }
      icon ??= Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Mimecon(
          mimetype: mimeType ?? 'bin',
          color: myself.primary,
          size: 32,
          isOutlined: true,
        ),
        CommonAutoSizeText(
          fileName,
          softWrap: true,
          overflow: TextOverflow.fade,
          maxLines: 3,
        ),
        CommonAutoSizeText(size == null ? '' : '${size % 1024}KB'),
      ]);

      var chip = GestureDetector(
          onDoubleTap: () async {
            attachmentMediaProvider.value = mediaProvider;
            indexWidgetProvider.push('full_screen_attachment');
          },
          child: Card(
            elevation: 0.0,
            color: Colors.grey.withOpacity(0.2),
            shape: const ContinuousRectangleBorder(),
            child: Container(
                padding: const EdgeInsets.all(0.0),
                height: 100,
                width: 120,
                child: icon),
          ));
      chips.add(chip);
    }
    return chips;
  }

  Widget _buildAttachmentWidget(BuildContext context) {
    return PlatformFutureBuilder(
        future: _buildAttachmentChips(context),
        builder: (BuildContext context, List<Widget>? chips) {
          return Container(
              alignment: Alignment.centerLeft,
              color: myself.getBackgroundColor(context).withOpacity(0.6),
              child: Wrap(
                direction: Axis.horizontal,
                children: chips!,
              ));
        });
  }

  @override
  Widget build(BuildContext context) {
    return _buildAttachmentWidget(context);
  }
}
