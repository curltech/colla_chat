import 'dart:io';

import 'package:enough_mail/enough_mail.dart' as enough_mail;
import 'package:enough_mail_html/enough_mail_html.dart';

import '../provider/app_data.dart';

class MailMessageUtil {
  /// Builds a simple example message
  static enough_mail.MimeMessage buildMessage() {
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
  static Future<enough_mail.MimeMessage> buildMessageWithAttachment() async {
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

  static String generateHtml(enough_mail.MimeMessage mimeMessage) {
    return mimeMessage.transformToHtml(
      blockExternalImages: false,
      emptyMessageText: 'Nothing here, move on!',
    );
  }

  static String generatePlainText(String htmlText) {
    return HtmlToPlainTextConverter.convert(htmlText);
  }

  static void saveMessage(enough_mail.MimeMessage message) {
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

class MailClient {
  String personalName;
  String username;
  String password;
  String domain;

  late String email = '$username@$domain';

  String imapServerHost;
  int imapServerPort;
  bool imapServerSecure = true;

  String popServerHost;
  int popServerPort;
  bool popServerSecure = true;

  String smtpServerHost;
  int smtpServerPort;
  bool smtpServerSecure = true;

  enough_mail.ImapClient? imapClient;
  enough_mail.PopClient? popClient;
  enough_mail.SmtpClient? smtpClient;

  MailClient(
      {required this.personalName,
      required this.username,
      required this.domain,
      required this.password,
      required this.imapServerHost,
      required this.imapServerPort,
      required this.popServerHost,
      required this.popServerPort,
      required this.smtpServerHost,
      required this.smtpServerPort});

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

  /// High level mail API example
  Future<void> autoMail() async {
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
        'my account', email, password, config);
    final mailClient = enough_mail.MailClient(account, isLogEnabled: true);
    try {
      await mailClient.connect();
      logger.i('connected');
      final mailboxes =
          await mailClient.listMailboxesAsTree(createIntermediate: false);
      logger.i(mailboxes);
      await mailClient.selectInbox();
      final messages = await mailClient.fetchMessages(count: 20);
      messages.forEach(MailMessageUtil.saveMessage);
      mailClient.eventBus.on<enough_mail.MailLoadEvent>().listen((event) {
        logger.i('New message at ${DateTime.now()}:');
        MailMessageUtil.saveMessage(event.message);
      });
      await mailClient.startPolling();
      // generate and send email:
      final mimeMessage = MailMessageUtil.buildMessage();
      await mailClient.sendMessage(mimeMessage);
    } on enough_mail.MailException catch (e) {
      logger.i('High level API failed with $e');
    }
  }

  imapConnect() async {
    final client = enough_mail.ImapClient(isLogEnabled: false);
    try {
      await client.connectToServer(imapServerHost, imapServerPort,
          isSecure: imapServerSecure);
      await client.login(username, password);

      imapClient = client;
    } on enough_mail.ImapException catch (e) {
      logger.i('IMAP failed with $e');
    }
  }

  Future<List<enough_mail.Mailbox>?> selectInbox() async {
    try {
      final imapClient = this.imapClient;
      if (imapClient != null) {
        final mailboxes = await imapClient.listMailboxes();
        logger.i('mailboxes: $mailboxes');
        await imapClient.selectInbox();
        return mailboxes;
      }
    } on enough_mail.ImapException catch (e) {
      logger.i('IMAP failed with $e');
    }
    return null;
  }

  fetchRecentMessages() async {
    try {
      final imapClient = this.imapClient;
      if (imapClient != null) {
        // fetch 10 most recent messages:
        final fetchResult = await imapClient.fetchRecentMessages(
            messageCount: 30, criteria: 'BODY.PEEK[]');
        fetchResult.messages.forEach(MailMessageUtil.saveMessage);
      }
    } on enough_mail.ImapException catch (e) {
      logger.i('IMAP failed with $e');
    }
  }

  imapLogout() async {
    try {
      final imapClient = this.imapClient;
      if (imapClient != null) {
        await imapClient.logout();
        this.imapClient = null;
      }
    } on enough_mail.ImapException catch (e) {
      logger.i('IMAP failed with $e');
    }
  }

  /// Low level SMTP API example
  Future<void> smtpConnect() async {
    var client = enough_mail.SmtpClient(domain, isLogEnabled: true);
    try {
      await client.connectToServer(smtpServerHost, smtpServerPort,
          isSecure: smtpServerSecure);
      await client.ehlo();
      if (client.serverInfo.supportsAuth(enough_mail.AuthMechanism.plain)) {
        await client.authenticate(
            username, password, enough_mail.AuthMechanism.plain);
      } else if (client.serverInfo
          .supportsAuth(enough_mail.AuthMechanism.login)) {
        await client.authenticate(
            username, password, enough_mail.AuthMechanism.login);
      } else {
        return;
      }
      smtpClient = client;
    } on enough_mail.SmtpException catch (e) {
      logger.e('SMTP failed with $e');
    }
  }

  Future<void> smtpSend() async {
    // generate and send email:
    final mimeMessage = await MailMessageUtil.buildMessageWithAttachment();
    final sendResponse = await smtpClient?.sendMessage(mimeMessage);
    logger.i('message sent: ${sendResponse?.isOkStatus}');
  }

  /// Low level POP3 API example
  Future<void> popConnect() async {
    final client = enough_mail.PopClient(isLogEnabled: false);
    try {
      await client.connectToServer(popServerHost, popServerPort,
          isSecure: popServerSecure);
      await client.login(username, password);
      // alternative login:
      // await client.loginWithApop(userName, password);
      final status = await client.status();
      logger.i('status: messages count=${status.numberOfMessages}, '
          'messages size=${status.totalSizeInBytes}');
      popClient = client;
    } on enough_mail.PopException catch (e) {
      logger.e('POP failed with $e');
    }
  }

  Future<void> popReceive() async {
    final client = popClient;
    try {
      if (client != null) {
        final status = await client.status();
        logger.i('status: messages count=${status.numberOfMessages}, '
            'messages size=${status.totalSizeInBytes}');
        final messageList = await client.list(status.numberOfMessages);
        logger.i('last message: id=${messageList.first.id} '
            'size=${messageList.first.sizeInBytes}');
        var message = await client.retrieve(status.numberOfMessages);
        MailMessageUtil.saveMessage(message);
        message = await client.retrieve(status.numberOfMessages + 1);
        logger.i('trying to retrieve newer message succeeded');
        await client.quit();
      }
    } on enough_mail.PopException catch (e) {
      logger.e('POP failed with $e');
    }
  }

  Future<void> popClose() async {
    final client = popClient;
    try {
      if (client != null) {
        await client.quit();
        popClient = null;
      }
    } on enough_mail.PopException catch (e) {
      logger.e('POP failed with $e');
    }
  }

  close() {
    imapLogout();
    popClose();
  }
}

class MailClientPool {
  static final MailClientPool _instance = MailClientPool();
  static bool initStatus = false;

  /// 初始化连接池，设置缺省mailClientclient，返回连接池
  static MailClientPool get instance {
    if (!initStatus) {
      initStatus = true;
    }
    return _instance;
  }

  var mailClients = <String, MailClient>{};
  MailClient? _default;

  MailClientPool();

  MailClient? create(
      {required String username,
      required String domain,
      required String personalName,
      required String password,
      required String imapServerHost,
      required int imapServerPort,
      required String popServerHost,
      required int popServerPort,
      required String smtpServerHost,
      required int smtpServerPort}) {
    var address = '$username@$domain';
    if (mailClients.containsKey(address)) {
      return mailClients[address];
    } else {
      var mailClient = MailClient(
          username: username,
          domain: domain,
          personalName: personalName,
          password: password,
          imapServerHost: imapServerHost,
          imapServerPort: imapServerPort,
          popServerHost: popServerHost,
          popServerPort: popServerPort,
          smtpServerHost: smtpServerHost,
          smtpServerPort: smtpServerPort);
      mailClients[address] = mailClient;
      mailClient.imapConnect();
      mailClient.popConnect();

      return mailClient;
    }
  }

  MailClient? get(String address) {
    if (mailClients.containsKey(address)) {
      return mailClients[address];
    } else {
      return null;
    }
  }

  close(String address) {
    if (mailClients.containsKey(address)) {
      var mailClient = mailClients[address];
      if (mailClient != null) {
        mailClient.close();
      }
      mailClients.remove(address);
    }
  }

  MailClient? get defaultMailClient {
    return _default;
  }

  setMailClient(String address) {
    MailClient? mailClient;
    if (mailClients.containsKey(address)) {
      mailClient = mailClients[address];
    }
  }

  MailClient? setDefaultMailClient(String address) {
    MailClient? mailClient;
    if (mailClients.containsKey(address)) {
      mailClient = mailClients[address];
    }
    _default = mailClient;

    return _default;
  }
}
