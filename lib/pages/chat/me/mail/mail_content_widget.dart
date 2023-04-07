import 'package:colla_chat/pages/chat/me/mail/mail_data_provider.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:enough_mail/codecs.dart';
import 'package:enough_mail/highlevel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  IconData get iconData => Icons.attach_email;

  @override
  String get title => 'MailContent';
}

class _MailContentWidgetState extends State<MailContentWidget> {
  late Widget mimeMessageViewer;

  @override
  initState() {
    super.initState();
    mimeMessageViewer = _build(context);
  }

  Widget _buildMimeMessageViewer(
      BuildContext context, MailDataProvider mailAddressProvider) {
    var currentChatMessage = mailAddressProvider.currentChatMessage;
    MimeMessage mimeMessage;
    if (currentChatMessage != null) {
      mimeMessage = EmailMessageUtil.convertToMimeMessage(currentChatMessage);
    } else {
      mimeMessage = MimeMessage();
    }
    Widget mimeMessageViewer;
    if (platformParams.android || platformParams.ios) {
      mimeMessageViewer = Container();

      ///在ios下会引发启动崩溃
      // mimeMessageViewer = MimeMessageViewer(
      //   mimeMessage: mimeMessage,
      //   blockExternalImages: false,
      //   mailtoDelegate: handleMailto,
      // );
    } else {
      mimeMessageViewer = const Center(child: CommonAutoSizeText('Not support'));
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

  Widget _build(BuildContext context) {
    return Consumer<MailDataProvider>(
        builder: (context, mailAddressProvider, child) {
      Widget mimeMessageViewer = Container();
      mimeMessageViewer = _buildMimeMessageViewer(context, mailAddressProvider);
      return mimeMessageViewer;
    });
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: mimeMessageViewer);
    return appBarView;
  }
}
