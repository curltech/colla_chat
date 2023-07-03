import 'dart:io';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/mail/mail_address_controller.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/path_util.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/platform_webview.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:enough_mail/highlevel.dart';
import 'package:enough_mail_flutter/enough_mail_flutter.dart';
import 'package:flutter/material.dart';
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

  ///当前的邮件发生变化，如果没有获取内容，则获取内容
  Future<MimeMessage?> findMimeMessage() async {
    MimeMessage? mimeMessage = mailAddressController.currentMimeMessage;
    if (mimeMessage != null) {
      try {
        await mailAddressController.updateMimeMessageContent();
      } catch (e) {
        logger.e('updateMimeMessageContent failure:$e');
      }
      mimeMessage = mailAddressController.currentMimeMessage;
      if (mimeMessage != null) {
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
        } else if (platformParams.macos) {
          ///macos平台，可以直接使用html字符串
          html = EmailMessageUtil.convertToHtml(mimeMessage);
          filename = null;
        }

        ///其他平台，移动平台，不使用文件或者html字符串，而采用邮件的显示组建
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
          MimeMessage? mimeMessage = snapshot.data;
          if (mimeMessage != null) {
            MimeMessage? mimeMessageContent =
                mimeMessage.decodeContentMessage();
            if (mimeMessageContent == null) {
              return Text(AppLocalizations.t('MimeMessage is no content'));
            }

            ///移动平台使用邮件的显示组建
            if (platformParams.mobile) {
              ///在ios下会引发启动崩溃
              MimeMessageViewer mimeMessageViewer = MimeMessageViewer(
                mimeMessage: mimeMessage,
                blockExternalImages: false,
                mailtoDelegate: handleMailto,
              );
              return mimeMessageViewer;
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
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              Text(AppLocalizations.t("Loading, please waiting...")),
            ],
          ));
        });
    return mimeMessageViewer;
  }

  Future<dynamic> handleMailto(Uri mailto, MimeMessage mimeMessage) async {
    final fromAddress = MailAddress('My Name', 'email@domain.com');
    final messageBuilder =
        MessageBuilder.prepareMailtoBasedMessage(mailto, MailAddress('', ''));
    return null;
  }

  Widget? buildViewerForMessage(
      MimeMessage mimeMessage, MailClient mailClient) {
    mailClient.fetchMessages(fetchPreference: FetchPreference.envelope);

    ///在ios下会引发启动崩溃
    return null;
    //   MimeMessageDownloader(
    //   mimeMessage: mimeMessage,
    //   mailClient: mailClient,
    //   onDownloaded: onMessageDownloaded,
    //   blockExternalImages: false,
    //   markAsSeen: true,
    //   mailtoDelegate: handleMailto,
    // );
  }

  void onMessageDownloaded(MimeMessage mimeMessage) {
    // update other things to show eg attachment view, e.g.:
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: Card(
            elevation: 0.0,
            shape: const ContinuousRectangleBorder(),
            margin: EdgeInsets.zero,
            child: SizedBox(
                width: double.infinity,
                child: Center(child: _buildMimeMessageViewer(context)))));
    return appBarView;
  }

  @override
  void dispose() {
    mailAddressController.removeListener(_update);
    super.dispose();
  }
}
