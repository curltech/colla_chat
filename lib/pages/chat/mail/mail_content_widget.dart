import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/mail/full_screen_attachment_widget.dart';
import 'package:colla_chat/pages/chat/mail/mail_mime_message_controller.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/emailaddress.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/webview/platform_webview.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:enough_mail/highlevel.dart';
import 'package:enough_mail_flutter/enough_mail_flutter.dart';
import 'package:flutter/material.dart';
import 'package:mimecon/mimecon.dart';

///邮件内容子视图
class MailContentWidget extends StatefulWidget with TileDataMixin {
  MailContentWidget({Key? key}) : super(key: key) {
    FullScreenAttachmentWidget fullScreenAttachmentWidget =
        const FullScreenAttachmentWidget();
    indexWidgetProvider.define(fullScreenAttachmentWidget);
  }

  @override
  State<StatefulWidget> createState() => _MailContentWidgetState();

  @override
  String get routeName => 'mail_content';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.attach_email;

  @override
  String get title => 'MailContent';
}

class _MailContentWidgetState extends State<MailContentWidget> {
  PlatformWebView? platformWebView;
  PlatformWebViewController? platformWebViewController;
  DecryptedMimeMessage decryptedMimeMessage = DecryptedMimeMessage();
  ValueNotifier<String?> subject = ValueNotifier<String?>(null);

  ///移动平台采用MimeMessage显示
  ///非windows平台直接使用html显示
  ///windows平台需要先转换成文件，防止乱码

  @override
  initState() {
    mailMimeMessageController.addListener(_update);
    super.initState();

    ///windows桌面环境下用webview显示html文件方式的邮件内容，后面用load方式装载
    if (!platformParams.mobile && !platformParams.macos) {
      platformWebViewController = PlatformWebViewController();
      platformWebView = PlatformWebView(
          onWebViewCreated: (PlatformWebViewController controller) {
        platformWebViewController!.inAppWebViewController =
            controller.inAppWebViewController;
        platformWebViewController!.webViewController =
            controller.webViewController;
      });
    }
  }

  _update() {
    setState(() {});
  }

  ///获取当前邮件的附件目录信息，用于展示
  List<ContentInfo>? findContentInfos() {
    MimeMessage? mimeMessage = mailMimeMessageController.currentMimeMessage;
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
    MimeMessage? mimeMessage = mailMimeMessageController.currentMimeMessage;
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
            List<int>? data = await emailAddressService.decrypt(
                CryptoUtil.stringToUtf8(text),
                payloadKey: decryptedMimeMessage.payloadKey);
            if (data != null) {
              text = CryptoUtil.utf8ToString(data);
            }
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
            data = await emailAddressService.decrypt(data,
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

  ///当前的邮件发生变化，如果没有获取内容，则获取内容
  Future<MimeMessage?> findMimeMessage() async {
    MimeMessage? mimeMessage = mailMimeMessageController.currentMimeMessage;
    if (mimeMessage != null) {
      try {
        await mailMimeMessageController.fetchMessageContents();
        mimeMessage = mailMimeMessageController.currentMimeMessage;
      } catch (e) {
        logger.e('updateMimeMessageContent failure:$e');
      }
      if (mimeMessage != null) {
        decryptedMimeMessage =
            await mailMimeMessageController.decryptMimeMessage(mimeMessage);
        subject.value = decryptedMimeMessage.subject;
      }
    }
    if (mimeMessage == null) {
      decryptedMimeMessage.subject = null;
      subject.value = null;
      decryptedMimeMessage.html = null;
    }
    return mimeMessage;
  }

  ///邮件内容发生变化时，移动平台将重新创建mimeMessageViewer
  ///桌面平台将利用现有的webview重新装载html内容
  Widget _buildMimeMessageViewer(BuildContext context) {
    Widget mimeMessageViewer = FutureBuilder(
        future: findMimeMessage(),
        builder: (BuildContext context, AsyncSnapshot<MimeMessage?> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return LoadingUtil.buildLoadingIndicator();
          }
          MimeMessage? mimeMessage = snapshot.data;
          if (mimeMessage != null) {
            MimeMessage? mimeMessageContent =
                mimeMessage.decodeContentMessage();
            if (mimeMessageContent == null) {
              return Center(
                  child: Column(children: [
                Text(AppLocalizations.t('MimeMessage is no content')),
                const SizedBox(
                  height: 15.0,
                ),
                IconButton(
                    onPressed: () {
                      setState(() {});
                    },
                    icon: Icon(
                      Icons.refresh,
                      color: myself.primary,
                    ))
              ]));
            }
            Widget webView = Container();
            try {
              webView = PlatformWebView(html: decryptedMimeMessage.html);
            } catch (e) {
              logger.e('PlatformWebView failure:$e');
            }
            Widget? attachWidget = _buildAttachmentChips(context);
            if (attachWidget == null) {
              return webView;
            }
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Expanded(child: webView),
              attachWidget,
            ]);
          }
          return Center(
            child: Text(AppLocalizations.t("Have no mimeMessage")),
          );
        });
    return mimeMessageViewer;
  }

  /// 附件显示区
  Widget? _buildAttachmentChips(BuildContext context) {
    List<Widget> chips = [];
    List<ContentInfo>? contentInfos = findContentInfos();
    if (contentInfos == null) {
      return null;
    }
    for (ContentInfo contentInfo in contentInfos) {
      String? fileName = contentInfo.fileName;
      fileName = fileName ?? AppLocalizations.t('Unknown filename');
      fileName = FileUtil.filename(fileName);
      int? size = contentInfo.size;
      MediaType? mediaType = contentInfo.mediaType;
      String? mimeType = FileUtil.mimeType(fileName);
      Widget icon = Mimecon(
        mimetype: mimeType ?? 'bin',
        color: myself.primary,
        size: 32,
        isOutlined: true,
      );
      String fetchId = contentInfo.fetchId;
      var chip = GestureDetector(
          onDoubleTap: () async {
            MediaProvider? mediaProvider =
                await findAttachmentMediaProvider(fetchId);
            if (mediaProvider != null) {
              mimeMessageAttachmentController.mediaProvider = mediaProvider;
              indexWidgetProvider.push('full_screen_attachment');
            }
          },
          child: Card(
            elevation: 0.0,
            shape: ContinuousRectangleBorder(
                side: BorderSide(color: myself.primary)),
            //margin: const EdgeInsets.all(10.0),
            child: Container(
                padding: const EdgeInsets.all(5.0),
                width: 150,
                child: Column(children: [
                  icon,
                  Expanded(
                      child: Text(
                    fileName,
                    softWrap: true,
                    overflow: TextOverflow.fade,
                    maxLines: 3,
                  )),
                  Text('$size'),
                ])),
          ));
      chips.add(chip);
    }
    if (chips.isNotEmpty) {
      return Container(
          alignment: Alignment.centerLeft,
          color: myself.getBackgroundColor(context).withOpacity(0.6),
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Expanded(
                  child: Row(
                children: chips,
              ))));
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        titleWidget: ValueListenableBuilder(
          valueListenable: subject,
          builder: (BuildContext context, subject, Widget? child) {
            return CommonAutoSizeText(subject ?? '');
          },
        ),
        withLeading: widget.withLeading,
        child: Card(
            elevation: 0.0,
            shape: const ContinuousRectangleBorder(),
            margin: EdgeInsets.zero,
            child: SizedBox(
                width: double.infinity,
                child: _buildMimeMessageViewer(context))));
    return appBarView;
  }

  @override
  void dispose() {
    mailMimeMessageController.removeListener(_update);
    super.dispose();
  }
}
