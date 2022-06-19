import 'package:enough_mail/codecs.dart';
import 'package:enough_mail/highlevel.dart';
import 'package:enough_mail_flutter/enough_mail_flutter.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/common/widget_mixin.dart';

//邮件内容组件
class MailContentWidget extends StatefulWidget
    with BackButtonMixin, RouteNameMixin {
  final Function? backCallBack;

  MailContentWidget({Key? key, this.backCallBack}) : super(key: key) {}

  @override
  State<StatefulWidget> createState() => _MailContentWidgetState();

  @override
  String get routeName => 'mail_content';

  @override
  bool get withBack => true;
}

class _MailContentWidgetState extends State<MailContentWidget> {
  late MimeMessage mimeMessage;

  @override
  initState() async {
    super.initState();
  }

  Widget _build(MimeMessage mimeMessage) {
    return MimeMessageViewer(
      mimeMessage: mimeMessage,
      blockExternalImages: false,
      mailtoDelegate: handleMailto,
    );
  }

  Future<dynamic> handleMailto(Uri mailto, MimeMessage mimeMessage) async {
    final fromAddress = MailAddress('My Name', 'email@domain.com');
    final messageBuilder =
        MessageBuilder.prepareMailtoBasedMessage(mailto, MailAddress('', ''));
    return null;
  }

  Widget buildViewerForMessage(MimeMessage mimeMessage, MailClient mailClient) {
    mailClient.fetchMessages(fetchPreference: FetchPreference.envelope);
    return MimeMessageDownloader(
      mimeMessage: mimeMessage,
      mailClient: mailClient,
      onDownloaded: onMessageDownloaded,
      blockExternalImages: false,
      markAsSeen: true,
      mailtoDelegate: handleMailto,
    );
  }

  void onMessageDownloaded(MimeMessage mimeMessage) {
    // update other things to show eg attachment view, e.g.:
    //setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _build(mimeMessage);
  }
}
