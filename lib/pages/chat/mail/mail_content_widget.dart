import 'package:colla_chat/pages/chat/mail/mail_address_controller.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:enough_mail/highlevel.dart';
import 'package:flutter/material.dart';
import 'package:enough_mail_flutter/enough_mail_flutter.dart';

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
  @override
  initState() {
    mailAddressController.addListener(_update);
    super.initState();
  }

  _update() {
    setState(() {});
  }

  Widget _buildMimeMessageViewer(BuildContext context) {
    MimeMessage mimeMessage = mailAddressController
        .currentMimeMessages![mailAddressController.currentMailIndex];
    Widget mimeMessageViewer;
    if (platformParams.mobile || platformParams.macos) {
      ///在ios下会引发启动崩溃
      mimeMessageViewer = MimeMessageViewer(
        mimeMessage: mimeMessage,
        blockExternalImages: false,
        mailtoDelegate: handleMailto,
      );
    } else {
      mimeMessageViewer =
          const Center(child: CommonAutoSizeText('Not support'));
    }
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

  Widget _buildMailContentWidget(BuildContext context) {
    Widget mimeMessageViewer = _buildMimeMessageViewer(context);

    return mimeMessageViewer;
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: _buildMailContentWidget(context));
    return appBarView;
  }

  @override
  void dispose() {
    mailAddressController.removeListener(_update);
    super.dispose();
  }
}
