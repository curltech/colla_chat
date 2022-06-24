import 'package:enough_mail/codecs.dart';
import 'package:enough_mail/highlevel.dart';
import 'package:enough_mail_flutter/enough_mail_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../transport/emailclient.dart';
import '../../../../widgets/common/widget_mixin.dart';
import 'mail_address_provider.dart';

//邮件内容组件
class MailContentWidget extends StatefulWidget
    with LeadingButtonMixin, RouteNameMixin {
  final Function? leadingCallBack;

  MailContentWidget({Key? key, this.leadingCallBack}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MailContentWidgetState();

  @override
  String get routeName => 'mail_content';

  @override
  bool get withLeading => true;
}

class _MailContentWidgetState extends State<MailContentWidget> {
  MimeMessage mimeMessage = MimeMessage();

  @override
  initState() async {
    super.initState();
  }

  Widget _build(BuildContext context) {
    MailAddressProvider mailAddressProvider =
        Provider.of<MailAddressProvider>(context);
    var currentChatMessage = mailAddressProvider.currentChatMessage;
    if (currentChatMessage != null) {
      mimeMessage = EmailMessageUtil.convertToMimeMessage(currentChatMessage);
    }
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _build(context);
  }
}
