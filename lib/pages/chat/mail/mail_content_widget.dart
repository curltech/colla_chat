import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/mail/mail_address_controller.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/emailaddress.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/tool/path_util.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/webview/platform_webview.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:enough_mail/highlevel.dart';
import 'package:enough_mail_flutter/enough_mail_flutter.dart';
import 'package:flutter/material.dart';
import 'package:mimecon/mimecon.dart';
import 'package:path/path.dart' as p;

///邮件内容子视图
class MailContentWidget extends StatefulWidget with TileDataMixin {
  const MailContentWidget({Key? key}) : super(key: key);

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
  String? html;
  String? filename;

  ///移动平台采用MimeMessage显示
  ///非windows平台直接使用html显示
  ///windows平台需要先转换成文件，防止乱码

  @override
  initState() {
    mailAddressController.addListener(_update);
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
    MimeMessage? mimeMessage = mailAddressController.currentMimeMessage;
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
    MimeMessage? mimeMessage = mailAddressController.currentMimeMessage;
    if (mimeMessage == null) {
      return null;
    }
    MimePart? mimePart = mimeMessage.getPart(fetchId);
    //如果附件还未获取，则获取
    mimePart ??= await mailAddressController.fetchMessagePart(fetchId);
    if (mimePart == null) {
      return null;
    }

    ///获取附件的内容，文本内容或者二进制内容
    final name = mimePart.decodeFileName();
    final mediaType = mimePart.mediaType.text;
    if (mimePart.mediaType.isText) {
      return TextMediaProvider(name!, mediaType, mimePart.decodeContentText()!);
    } else {
      Uint8List? data = mimePart.decodeContentBinary();
      return MemoryMediaProvider(name!, mediaType, data!,
          description: mimeMessage.decodeSubject());
    }
  }

  ///当前的邮件发生变化，如果没有获取内容，则获取内容
  Future<MimeMessage?> findMimeMessage() async {
    MimeMessage? mimeMessage = mailAddressController.currentMimeMessage;
    if (mimeMessage != null) {
      try {
        await mailAddressController.fetchMessageContents();
      } catch (e) {
        logger.e('updateMimeMessageContent failure:$e');
      }
      mimeMessage = mailAddressController.currentMimeMessage;
      if (mimeMessage != null) {
        String? keys = mimeMessage.decodeHeaderValue('payloadKeys');
        if (keys != null && keys.isNotEmpty) {
          Map<String, String> payloadKeys = JsonUtil.toJson(keys);
          String payloadKey = payloadKeys[myself.peerId]!;
          emailAddressService.decrypt(
              CryptoUtil.decodeBase64(html!), payloadKey);
          if (payloadKeys.containsKey(myself.peerId)) {}
        }

        ///windows平台采用文件加载的方式，避免中文乱码
        if (platformParams.windows) {
          int? uid = mimeMessage.uid;
          String? sender = mimeMessage.envelope?.sender?.email;
          Directory tempDir = await PathUtil.getTemporaryDirectory();
          String filename = p.join(tempDir.path, '${sender}_$uid.html');
          File file = File(filename);
          bool exist = file.existsSync();
          if (!exist) {
            html = EmailMessageUtil.convertToHtml(mimeMessage);
            file.writeAsStringSync(html!, flush: true);
            html = null;
          }
        } else {
          ///非windos平台，可以直接使用html字符串
          html = EmailMessageUtil.convertToHtml(mimeMessage);
          filename = null;
        }
      }
    } else {
      html = null;
      filename = null;
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
              return Text(AppLocalizations.t('MimeMessage is no content'));
            }

            ///移动平台使用邮件的显示组建
            if (platformParams.mobile) {
              return PlatformWebView(html: html);
            } else if (platformParams.macos) {
              ///macos使用html字符串
              return PlatformWebView(html: html);
            } else {
              ///windows平台使用文件
              platformWebViewController!.load(filename);
              return platformWebView!;
            }
          }
          return Center(
            child: Text(AppLocalizations.t("Have no mimeMessage")),
          );
        });
    return mimeMessageViewer;
  }

  /// 附件显示区
  Widget _buildAttachmentChips(BuildContext context) {
    List<Widget> chips = [];
    List<ContentInfo>? contentInfos = findContentInfos();
    if (contentInfos == null) {
      return Container();
    }
    for (var contentInfo in contentInfos!) {
      String? name = contentInfo.fileName;
      int? size = contentInfo.size;
      MediaType? mediaType = contentInfo.mediaType;
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
              icon,
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
      return Container(
          alignment: Alignment.centerLeft,
          color: myself.getBackgroundColor(context).withOpacity(0.6),
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips,
              )));
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    String? title = widget.title;
    MimeMessage? mimeMessage = mailAddressController.currentMimeMessage;
    if (mimeMessage != null) {
      title = mimeMessage.envelope?.subject;
    }
    var appBarView = AppBarView(
        title: title,
        withLeading: widget.withLeading,
        child: Card(
            elevation: 0.0,
            shape: const ContinuousRectangleBorder(),
            margin: EdgeInsets.zero,
            child: SizedBox(
                width: double.infinity,
                child: Column(children: [
                  Expanded(child: _buildMimeMessageViewer(context)),
                  _buildAttachmentChips(context)
                ]))));
    return appBarView;
  }

  @override
  void dispose() {
    mailAddressController.removeListener(_update);
    super.dispose();
  }
}
