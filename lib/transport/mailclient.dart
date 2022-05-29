import 'dart:io';

import 'package:enough_mail/enough_mail.dart' as enough_mail;
import 'package:enough_mail_html/enough_mail_html.dart';

import '../app.dart';

class MailClient {
  String _userName = '';
  String _password = '';
  String _domain = '';

  String _imapServerHost = '';
  int _imapServerPort = 993;
  bool _imapServerSecure = true;

  String _popServerHost = '';
  int _popServerPort = 995;
  bool _popServerSecure = true;

  String _smtpServerHost = '';
  int _smtpServerPort = 465;
  bool _smtpServerSecure = true;

  /// Auto discover settings from email address
  Future<enough_mail.ClientConfig?> discover(String email) async {
    final config =
        await enough_mail.Discover.discover(email, isLogEnabled: false);
    if (config != null) {
      for (final provider in config.emailProviders!) {
        logger.i('provider: ${provider.displayName}');
        logger.i('provider-domains: ${provider.domains}');
        logger.i('documentation-url: ${provider.documentationUrl}');
        logger.i('Incoming:');
        provider.incomingServers?.forEach(logger.i);
        logger.i(provider.preferredIncomingServer);
        logger.i('Outgoing:');
        provider.outgoingServers?.forEach(logger.i);
        logger.i(provider.preferredOutgoingServer);
      }
    }

    return config;
  }

  /// Builds a simple example message
  enough_mail.MimeMessage buildMessage() {
    final builder =
        enough_mail.MessageBuilder.prepareMultipartAlternativeMessage(
      plainText: 'Hello world!',
      htmlText: '<p>Hello world!</p>',
    )
          ..from = [
            enough_mail.MailAddress('Personal Name', 'sender@domain.com')
          ]
          ..to = [
            enough_mail.MailAddress(
                'Recipient Personal Name', 'recipient@domain.com'),
            enough_mail.MailAddress('Other Recipient', 'other@domain.com')
          ];
    return builder.buildMimeMessage();
  }

  /// Builds an example message with attachment
  Future<enough_mail.MimeMessage> buildMessageWithAttachment() async {
    final builder = enough_mail.MessageBuilder()
      ..from = [enough_mail.MailAddress('Personal Name', 'sender@domain.com')]
      ..to = [
        enough_mail.MailAddress(
            'Recipient Personal Name', 'recipient@domain.com'),
        enough_mail.MailAddress('Other Recipient', 'other@domain.com')
      ]
      ..addMultipartAlternative(
        plainText: 'Hello world!',
        htmlText: '<p>Hello world!</p>',
      );
    final file = File.fromUri(Uri.parse('file://./document.pdf'));
    await builder.addFile(
        file, enough_mail.MediaSubtype.applicationPdf.mediaType);
    return builder.buildMimeMessage();
  }

  /// High level mail API example
  Future<void> autoMail() async {
    final email = '$_userName@$_domain';
    final config = await enough_mail.Discover.discover(email);
    if (config == null) {
      // note that you can also directly create an account when
      // you cannot auto-discover the settings:
      // Compare the [MailAccount.fromManualSettings]
      // and [MailAccount.fromManualSettingsWithAuth]
      // methods for details.
      logger.i('Unable to auto-discover settings for $email');
      return;
    }
    logger.i('connecting to ${config.displayName}.');
    final account = enough_mail.MailAccount.fromDiscoveredSettings(
        'my account', email, _password, config);
    final mailClient = enough_mail.MailClient(account, isLogEnabled: true);
    try {
      await mailClient.connect();
      logger.i('connected');
      final mailboxes =
          await mailClient.listMailboxesAsTree(createIntermediate: false);
      logger.i(mailboxes);
      await mailClient.selectInbox();
      final messages = await mailClient.fetchMessages(count: 20);
      messages.forEach(saveMessage);
      mailClient.eventBus.on<enough_mail.MailLoadEvent>().listen((event) {
        logger.i('New message at ${DateTime.now()}:');
        saveMessage(event.message);
      });
      await mailClient.startPolling();
      // generate and send email:
      final mimeMessage = buildMessage();
      await mailClient.sendMessage(mimeMessage);
    } on enough_mail.MailException catch (e) {
      logger.i('High level API failed with $e');
    }
  }

  /// Low level IMAP API usage example
  Future<void> imapReceive() async {
    final client = enough_mail.ImapClient(isLogEnabled: false);
    try {
      await client.connectToServer(_imapServerHost, _imapServerPort,
          isSecure: _imapServerSecure);
      await client.login(_userName, _password);
      final mailboxes = await client.listMailboxes();
      logger.i('mailboxes: $mailboxes');
      await client.selectInbox();
      // fetch 10 most recent messages:
      final fetchResult = await client.fetchRecentMessages(
          messageCount: 30, criteria: 'BODY.PEEK[]');
      fetchResult.messages.forEach(saveMessage);
      await client.logout();
    } on enough_mail.ImapException catch (e) {
      logger.i('IMAP failed with $e');
    }
  }

  /// Low level SMTP API example
  Future<void> smtpSend() async {
    final client = enough_mail.SmtpClient(_domain, isLogEnabled: true);
    try {
      await client.connectToServer(_smtpServerHost, _smtpServerPort,
          isSecure: _smtpServerSecure);
      await client.ehlo();
      if (client.serverInfo.supportsAuth(enough_mail.AuthMechanism.plain)) {
        await client.authenticate(
            _userName, _password, enough_mail.AuthMechanism.plain);
      } else if (client.serverInfo
          .supportsAuth(enough_mail.AuthMechanism.login)) {
        await client.authenticate(
            _userName, _password, enough_mail.AuthMechanism.login);
      } else {
        return;
      }
      // generate and send email:
      final mimeMessage = await buildMessageWithAttachment();
      final sendResponse = await client.sendMessage(mimeMessage);
      logger.i('message sent: ${sendResponse.isOkStatus}');
    } on enough_mail.SmtpException catch (e) {
      logger.e('SMTP failed with $e');
    }
  }

  /// Low level POP3 API example
  Future<void> popReceive() async {
    final client = enough_mail.PopClient(isLogEnabled: false);
    try {
      await client.connectToServer(_popServerHost, _popServerPort,
          isSecure: _popServerSecure);
      await client.login(_userName, _password);
      // alternative login:
      // await client.loginWithApop(userName, password);
      final status = await client.status();
      logger.i('status: messages count=${status.numberOfMessages}, '
          'messages size=${status.totalSizeInBytes}');
      final messageList = await client.list(status.numberOfMessages);
      logger.i('last message: id=${messageList.first.id} '
          'size=${messageList.first.sizeInBytes}');
      var message = await client.retrieve(status.numberOfMessages);
      saveMessage(message);
      message = await client.retrieve(status.numberOfMessages + 1);
      logger.i('trying to retrieve newer message succeeded');
      await client.quit();
    } on enough_mail.PopException catch (e) {
      logger.e('POP failed with $e');
    }
  }

  String generateHtml(enough_mail.MimeMessage mimeMessage) {
    return mimeMessage.transformToHtml(
      blockExternalImages: false,
      emptyMessageText: 'Nothing here, move on!',
    );
  }

  String generatePlainText(String htmlText) {
    return HtmlToPlainTextConverter.convert(htmlText);
  }

  void saveMessage(enough_mail.MimeMessage message) {
    logger.i('from: ${message.from} with subject "${message.decodeSubject()}"');
    if (!message.isTextPlainMessage()) {
      logger.i(' content-type: ${message.mediaType}');
    } else {
      final plainText = message.decodeTextPlainPart();
      if (plainText != null) {
        final lines = plainText.split('\r\n');
        for (final line in lines) {
          if (line.startsWith('>')) {
            // break when quoted text starts
            break;
          }
          logger.i(line);
        }
      }
    }
  }
}
