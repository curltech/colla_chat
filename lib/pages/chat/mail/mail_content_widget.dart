import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/pages/chat/mail/mail_address_controller.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/platform_webview.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:enough_mail/highlevel.dart';
import 'package:enough_mail_flutter/enough_mail_flutter.dart';
import 'package:flutter/material.dart';

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
  ValueNotifier<MimeMessage?> mimeMessage = ValueNotifier<MimeMessage?>(null);

  @override
  initState() {
    mailAddressController.addListener(_update);
    super.initState();

    ///桌面环境下用浏览器显示html邮件内容
    if (!platformParams.mobile) {
      platformWebViewController = PlatformWebViewController();
      platformWebView = PlatformWebView(
          onWebViewCreated: (PlatformWebViewController controller) {
        platformWebViewController!.inAppWebViewController =
            controller.inAppWebViewController;
        platformWebViewController!.webViewController =
            controller.webViewController;
      });
    }
    _updateMimeMessageViewer();
  }

  _update() {
    _updateMimeMessageViewer();
  }

  ///当前的邮件发生变化，如果没有获取内容，则获取内容
  Future<void> _updateMimeMessageViewer() async {
    MimeMessage? mimeMessage = mailAddressController.currentMimeMessage;
    if (mimeMessage != null) {
      await mailAddressController.updateMimeMessageContent();
      this.mimeMessage.value = mailAddressController.currentMimeMessage;
    }
  }

  ///邮件内容发生变化时，移动平台将重新创建mimeMessageViewer
  ///桌面平台将利用现有的webview重新装载html内容
  Widget _buildMimeMessageViewer(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: mimeMessage,
        builder:
            (BuildContext context, MimeMessage? mimeMessage, Widget? child) {
          Widget mimeMessageViewer;
          if (mimeMessage == null) {
            return Container();
          }
          if (platformParams.mobile) {
            ///在ios下会引发启动崩溃
            mimeMessageViewer = MimeMessageViewer(
              mimeMessage: mimeMessage,
              blockExternalImages: false,
              mailtoDelegate: handleMailto,
            );
          } else {
            String html = EmailMessageUtil.convertToHtml(mimeMessage);
            mimeMessageViewer = platformWebView!;
            platformWebViewController!.loadHtml(html);
          }

          return mimeMessageViewer;
        });
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
        child: _buildMimeMessageViewer(context));
    return appBarView;
  }

  @override
  void dispose() {
    mailAddressController.removeListener(_update);
    super.dispose();
  }
}
