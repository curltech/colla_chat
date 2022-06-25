import 'package:enough_mail/codecs.dart';
import 'package:enough_mail/highlevel.dart';
import 'package:enough_mail_flutter/enough_mail_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../platform.dart';
import '../../../../transport/emailclient.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/widget_mixin.dart';
import 'mail_address_provider.dart';

//邮件内容组件
class MailContentWidget extends StatefulWidget with TileDataMixin {
  const MailContentWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MailContentWidgetState();

  @override
  String get routeName => 'mail_content';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.attach_email);

  @override
  String get title => 'MailContent';
}

class _MailContentWidgetState extends State<MailContentWidget> {
  @override
  initState() {
    super.initState();
  }

  Widget _buildMimeMessageViewer(
      BuildContext context, MailAddressProvider mailAddressProvider) {
    var currentChatMessage = mailAddressProvider.currentChatMessage;
    MimeMessage mimeMessage;
    if (currentChatMessage != null) {
      mimeMessage = EmailMessageUtil.convertToMimeMessage(currentChatMessage);
    } else {
      mimeMessage = MimeMessage();
    }
    Widget mimeMessageViewer;
    if (PlatformParams.instance.android || PlatformParams.instance.ios) {
      mimeMessageViewer = MimeMessageViewer(
        mimeMessage: mimeMessage,
        blockExternalImages: false,
        mailtoDelegate: handleMailto,
      );
    } else {
      mimeMessageViewer = const Center(child: Text('Not support'));
    }
    return mimeMessageViewer;
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
    return Consumer<MailAddressProvider>(
        builder: (context, mailAddressProvider, child) {
      var mimeMessageViewer =
          _buildMimeMessageViewer(context, mailAddressProvider);
      var appBarView = AppBarView(
          title: widget.title,
          withLeading: widget.withLeading,
          child: mimeMessageViewer);
      return appBarView;
    });
  }
}
