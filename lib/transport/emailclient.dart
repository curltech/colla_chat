import 'dart:io';

import 'package:enough_mail/codecs.dart';
import 'package:enough_mail/enough_mail.dart' as enough_mail;
import 'package:enough_mail/enough_mail.dart';
import 'package:enough_mail_html/enough_mail_html.dart';
import 'package:event_bus/event_bus.dart';

import '../entity/chat/chat.dart';
import '../provider/app_data_provider.dart';

class EmailMessageUtil {
  /// 创建带附件的消息
  static Future<enough_mail.MimeMessage> buildMessage({
    required List<enough_mail.MailAddress> from,
    required List<enough_mail.MailAddress> to,
    String? plainText,
    String? htmlText,
    TransferEncoding transferEncoding = TransferEncoding.eightBit,
    List<File>? files,
    List<enough_mail.MediaSubtype>? mediaTypes,
  }) async {
    final builder = enough_mail.MessageBuilder();

    builder.from = from;
    builder.to = to;
    builder.addMultipartAlternative(
      plainText: plainText,
      htmlText: htmlText,
    );
    //final file = File.fromUri(Uri.parse('file://./document.pdf'));
    //enough_mail.MediaSubtype.applicationPdf.mediaType
    if (files != null &&
        files.isNotEmpty &&
        mediaTypes != null &&
        mediaTypes.isNotEmpty &&
        mediaTypes.length == files.length) {
      for (int i = 0; i < files.length; ++i) {
        var file = files[i];
        var mediaType = mediaTypes[i];
        await builder.addFile(file, mediaType.mediaType);
      }
    }
    return builder.buildMimeMessage();
  }

  ///把邮件消息转换成html
  static String convertToHtml(enough_mail.MimeMessage mimeMessage) {
    return mimeMessage.transformToHtml(
      blockExternalImages: false,
      emptyMessageText: 'Nothing here, move on!',
    );
  }

  ///把html转换成普通文本
  static String convertToPlainText(String htmlText) {
    return HtmlToPlainTextConverter.convert(htmlText);
  }

  ///转换邮件信息为聊天信息
  static ChatMessage convertToChatMessage(enough_mail.MimeMessage message) {
    ChatMessage chatMessage = ChatMessage();
    chatMessage.title = message.decodeSubject();
    chatMessage.senderName = message.from.toString();
    chatMessage.contentType = message.mediaType.toString();
    chatMessage.content = message.renderMessage();
    //MimeMessage mimeMessage=MimeMessage.parseFromText(chatMessage.content);
    if (!message.isTextPlainMessage()) {
      chatMessage.attaches = <MessageAttachment>[];
      for (MimePart part in message.allPartsFlat) {
        MessageAttachment attach = MessageAttachment();
        attach.content = part.decodeContentText();
        attach.contentType = part.mediaType.text;
        chatMessage.attaches.add(attach);
      }
    }

    return chatMessage;
  }

  static enough_mail.MimeMessage convertToMimeMessage(ChatMessage chatMessage) {
    enough_mail.MimeMessage message =
        enough_mail.MimeMessage.parseFromText(chatMessage.content);

    return message;
  }

  /// 自动发现邮件地址配置
  static Future<enough_mail.ClientConfig?> discover(String email) async {
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
    } else {
      logger.i('Unable to auto-discover settings for $email');
    }

    return config;
  }

  ///用自动发现的配置创建邮件客户端
  static enough_mail.MailClient getMailClient(
      {required String email,
      required String password,
      required enough_mail.ClientConfig config}) {
    final account = enough_mail.MailAccount.fromDiscoveredSettings(
        'my account', email, password, config);
    final mailClient = enough_mail.MailClient(account, isLogEnabled: true);

    return mailClient;
  }
}

class EmailClient {
  String personalName;
  String username;
  late String password;
  String domain;

  late String email = '$username@$domain';

  String? imapServerHost;
  int imapServerPort = 993;
  bool imapServerSecure = true;

  String? popServerHost;
  int popServerPort = 995;
  bool popServerSecure = true;

  String? smtpServerHost;
  int smtpServerPort = 465;
  bool smtpServerSecure = true;

  ///mailClient是自动发现产生的客户端
  ClientConfig? config;
  enough_mail.MailClient? mailClient;
  enough_mail.ImapClient? imapClient;
  enough_mail.PopClient? popClient;
  enough_mail.SmtpClient? smtpClient;

  EmailClient(
      {required this.personalName,
      required this.username,
      required this.domain,
      this.imapServerHost,
      this.imapServerPort = 993,
      this.popServerHost,
      this.popServerPort = 995,
      this.smtpServerHost,
      this.smtpServerPort = 465});

  Future<bool> connect(String? password) async {
    bool success = false;
    if (mailClient != null) {
      success = await mailClientConnect();
      if (!success) {
        success = await imapConnect();
        logger.i('imapConnect $success');
        if (success) {
          PopStatus? status = await popConnect();
          if (status != null) {
            success = true;
          }
        }
      }
    }
    return success;
  }

  bool get status {
    return (mailClient != null ||
        (smtpClient != null && (imapClient != null || popClient != null)));
  }

  Future<ClientConfig?> mailClientDiscover() async {
    final config = await EmailMessageUtil.discover(email);
    if (config == null) {
      return null;
    }
    logger.i('connecting to ${config.displayName}.');
    this.config = config;

    return config;
  }

  ///用email自动发现和连接
  Future<bool> mailClientConnect({String? password}) async {
    if (password != null && this.password != password) {
      this.password = password;
    }
    var config = this.config;
    if (config == null) {
      return false;
    }
    final mailClient = EmailMessageUtil.getMailClient(
        email: email, password: this.password, config: config);
    try {
      await mailClient.connect();
      logger.i('connected');
      this.mailClient = mailClient;
      return true;
    } on enough_mail.MailException catch (e) {
      logger.i('High level API failed with $e');
      this.mailClient = null;
    }
    return false;
  }

  ///用邮件客户端获取邮箱树，知道邮箱的概况
  Future<Tree<Mailbox?>?> listMailboxesAsTree(
      {bool createIntermediate = true,
      List<MailboxFlag> order =
          enough_mail.MailClient.defaultMailboxOrder}) async {
    final mailClient = this.mailClient;
    if (mailClient != null) {
      final mailboxes = await mailClient.listMailboxesAsTree(
          createIntermediate: createIntermediate, order: order);
      logger.i(mailboxes);
      return mailboxes;
    }
    return null;
  }

  ///用邮件客户端获取邮箱，知道邮箱的概况
  Future<Mailbox?> selectInbox(
      {bool enableCondStore = false, QResyncParameters? qresync}) async {
    final mailClient = this.mailClient;
    if (mailClient != null) {
      var mailbox = await mailClient.selectInbox(
          enableCondStore: enableCondStore, qresync: qresync);
      return mailbox;
    }
    return null;
  }

  ///用邮件客户端获取消息
  Future<List<MimeMessage>?> fetchMessages(
      {int count = 20,
      FetchPreference fetchPreference = FetchPreference.fullWhenWithinSize,
      Mailbox? mailbox,
      int page = 1}) async {
    final mailClient = this.mailClient;
    if (mailClient != null) {
      final messages = await mailClient.fetchMessages(
          count: count,
          fetchPreference: fetchPreference,
          mailbox: mailbox,
          page: page);
      return messages;
    }
    return null;
  }

  ///用邮件客户端监听消息
  bool listen(
    Function(MimeMessage message)? onMessage, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final mailClient = this.mailClient;
    if (mailClient != null) {
      mailClient.eventBus.on<enough_mail.MailLoadEvent>().listen((event) {
        logger.i('New message at ${DateTime.now()}:');
        if (onMessage != null) {
          onMessage(event.message);
        }
      }, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
      return true;
    }

    return false;
  }

  ///用邮件客户端开始监听消息
  Future<bool> startPolling(
      [Duration duration =
          enough_mail.MailClient.defaultPollingDuration]) async {
    final mailClient = this.mailClient;
    if (mailClient != null) {
      await mailClient.startPolling(duration);
      return true;
    }
    return false;
  }

  ///用邮件客户端发送消息
  Future<bool> sendMessage(
    MimeMessage mimeMessage, {
    MailAddress? from,
    bool appendToSent = true,
    Mailbox? sentMailbox,
    bool use8BitEncoding = false,
    List<MailAddress>? recipients,
  }) async {
    final mailClient = this.mailClient;
    if (mailClient != null) {
      await mailClient.sendMessage(mimeMessage,
          from: from,
          appendToSent: appendToSent,
          sentMailbox: sentMailbox,
          use8BitEncoding: use8BitEncoding,
          recipients: recipients);
      return true;
    }
    return false;
  }

  disconnect() async {
    var mailClient = this.mailClient;
    if (mailClient != null) {
      await mailClient.disconnect();
    }
  }

  ///采用imap配置和协议连接
  imapConnect({
    EventBus? bus,
    bool isLogEnabled = false,
    String? logName,
    Duration? defaultWriteTimeout,
    Duration? defaultResponseTimeout,
    bool Function(X509Certificate)? onBadCertificate,
  }) async {
    final client = enough_mail.ImapClient(
        bus: bus,
        isLogEnabled: isLogEnabled,
        logName: logName,
        defaultWriteTimeout: defaultWriteTimeout,
        defaultResponseTimeout: defaultResponseTimeout);
    try {
      if (imapServerHost != null && imapServerPort != null) {
        await client.connectToServer(imapServerHost!, imapServerPort!,
            isSecure: imapServerSecure);
        await client.login(username, password);

        imapClient = client;
      }
    } on enough_mail.ImapException catch (e) {
      logger.i('IMAP failed with $e');
    }
  }

  Future<List<enough_mail.Mailbox>?> imapListMailboxes({
    String path = '""',
    bool recursive = false,
    List<String>? mailboxPatterns,
    List<String>? selectionOptions,
    List<ReturnOption>? returnOptions,
  }) async {
    try {
      final imapClient = this.imapClient;
      if (imapClient != null) {
        final mailboxes = await imapClient.listMailboxes(
            path: path,
            recursive: recursive,
            mailboxPatterns: mailboxPatterns,
            selectionOptions: selectionOptions,
            returnOptions: returnOptions);
        logger.i('mailboxes: $mailboxes');
        return mailboxes;
      }
    } on enough_mail.ImapException catch (e) {
      logger.i('IMAP failed with $e');
    }
    return null;
  }

  Future<Mailbox?> imapSelectInbox(
      {bool enableCondStore = false, QResyncParameters? qresync}) async {
    try {
      final imapClient = this.imapClient;
      if (imapClient != null) {
        var mailbox = await imapClient.selectInbox(
            enableCondStore: enableCondStore, qresync: qresync);
        return mailbox;
      }
    } on enough_mail.ImapException catch (e) {
      logger.i('IMAP failed with $e');
    }
    return null;
  }

  Future<FetchImapResult?> fetchRecentMessages({
    int messageCount = 30,
    String criteria = '(FLAGS BODY[])',
    Duration? responseTimeout,
  }) async {
    try {
      final imapClient = this.imapClient;
      if (imapClient != null) {
        // fetch 10 most recent messages:
        final fetchResult = await imapClient.fetchRecentMessages(
            messageCount: messageCount,
            criteria: 'BODY.PEEK[]',
            responseTimeout: responseTimeout);
        return fetchResult;
      }
    } on enough_mail.ImapException catch (e) {
      logger.i('IMAP failed with $e');
    }

    return null;
  }

  Future<bool> imapLogout() async {
    try {
      final imapClient = this.imapClient;
      if (imapClient != null) {
        await imapClient.logout();
        this.imapClient = null;
        return true;
      }
    } on enough_mail.ImapException catch (e) {
      logger.i('IMAP failed with $e');
    }
    return false;
  }

  /// smtp协议连接Connect
  Future<bool> smtpConnect() async {
    var client = enough_mail.SmtpClient(domain, isLogEnabled: true);
    bool result = false;
    try {
      if (smtpServerHost != null && smtpServerPort != null) {
        var connectionInfo = await client.connectToServer(
            smtpServerHost!, smtpServerPort!,
            isSecure: smtpServerSecure);
        logger.i(connectionInfo);
        SmtpResponse smtpResponse = await client.ehlo();
        if (!smtpResponse.isOkStatus) {
          return false;
        }
        if (client.serverInfo.supportsAuth(enough_mail.AuthMechanism.plain)) {
          SmtpResponse smtpResponse = await client.authenticate(
              username, password, enough_mail.AuthMechanism.plain);
          if (!smtpResponse.isOkStatus) {
            return false;
          }
          smtpClient = client;
          return true;
        }
      } else if (client.serverInfo
          .supportsAuth(enough_mail.AuthMechanism.login)) {
        SmtpResponse smtpResponse = await client.authenticate(
            username, password, enough_mail.AuthMechanism.login);
        if (!smtpResponse.isOkStatus) {
          return false;
        }
        smtpClient = client;
        return true;
      } else {
        return false;
      }
    } on enough_mail.SmtpException catch (e) {
      logger.e('SMTP failed with $e');
    }
    return false;
  }

  Future<bool> smtpSend(MimeMessage mimeMessage) async {
    var smtpClient = this.smtpClient;
    if (smtpClient != null) {
      final sendResponse = await smtpClient.sendMessage(mimeMessage);
      logger.i('message sent: ${sendResponse.isOkStatus}');
      return sendResponse.isOkStatus;
    }
    return false;
  }

  /// POP3协议连接
  Future<PopStatus?> popConnect() async {
    final client = enough_mail.PopClient(isLogEnabled: false);
    try {
      if (popServerHost != null && popServerPort != null) {
        var connectionInfo = await client.connectToServer(
            popServerHost!, popServerPort!,
            isSecure: popServerSecure);
        logger.i(connectionInfo);
        await client.login(username, password);
        // alternative login:
        // await client.loginWithApop(username, password);
        final status = await client.status();
        logger.i('status: messages count=${status.numberOfMessages}, '
            'messages size=${status.totalSizeInBytes}');
        popClient = client;
        return status;
      }
    } on enough_mail.PopException catch (e) {
      logger.e('POP failed with $e');
    }
    return null;
  }

  Future<List<MessageListing>?> popList() async {
    final client = popClient;
    try {
      if (client != null) {
        final status = await client.status();
        logger.i('status: messages count=${status.numberOfMessages}, '
            'messages size=${status.totalSizeInBytes}');
        final messageList = await client.list(status.numberOfMessages);
        logger.i('last message: id=${messageList.first.id} '
            'size=${messageList.first.sizeInBytes}');
        return messageList;
      }
    } on enough_mail.PopException catch (e) {
      logger.e('POP failed with $e');
    }
    return null;
  }

  Future<List<MimeMessage>?> popReceive() async {
    final client = popClient;
    try {
      if (client != null) {
        final status = await client.status();
        logger.i('status: messages count=${status.numberOfMessages}, '
            'messages size=${status.totalSizeInBytes}');
        List<MimeMessage> messages = [];
        for (int i = 0; i < status.numberOfMessages; ++i) {
          var message = await client.retrieve(status.numberOfMessages + i);
          messages.add(message);
        }
        logger.i('trying to retrieve newer message succeeded');
        await popClose();
        return messages;
      }
    } on enough_mail.PopException catch (e) {
      logger.e('POP failed with $e');
    }
    return null;
  }

  Future<bool> popClose() async {
    final client = popClient;
    try {
      if (client != null) {
        await client.quit();
        popClient = null;
        return true;
      }
    } on enough_mail.PopException catch (e) {
      logger.e('POP failed with $e');
    }
    return false;
  }

  close() async {
    await disconnect();
    await imapLogout();
    await popClose();
  }
}

class EmailClientPool {
  static final EmailClientPool _instance = EmailClientPool();
  static bool initStatus = false;

  /// 初始化连接池，设置缺省mailClientclient，返回连接池
  static EmailClientPool get instance {
    if (!initStatus) {
      initStatus = true;
    }
    return _instance;
  }

  var mailClients = <String, EmailClient>{};
  EmailClient? _default;

  EmailClientPool();

  Future<EmailClient?> create(
      {required String address,
      required String personalName,
      String? imapServerHost,
      int imapServerPort = 993,
      String? popServerHost,
      int popServerPort = 995,
      String? smtpServerHost,
      int smtpServerPort = 465}) async {
    var emails = address.split('@');
    if (emails.length != 2) {
      return null;
    }
    var username = emails[0];
    var domain = emails[1];
    EmailClient? mailClient = mailClients[address];
    if (mailClient != null) {
      return mailClient;
    } else {
      mailClient = EmailClient(
          username: username,
          domain: domain,
          personalName: personalName,
          imapServerHost: imapServerHost,
          imapServerPort: imapServerPort,
          popServerHost: popServerHost,
          popServerPort: popServerPort,
          smtpServerHost: smtpServerHost,
          smtpServerPort: smtpServerPort);
      await mailClient.mailClientDiscover();
      mailClients[address] = mailClient;

      return mailClient;
    }
  }

  Future<bool> connect(String address, String? password) async {
    EmailClient? mailClient = get(address);
    bool success = false;
    if (mailClient != null) {
      success = await mailClient.connect(password);
      return success;
    }
    return success;
  }

  EmailClient? get(String address) {
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

  EmailClient? get defaultMailClient {
    return _default;
  }

  setMailClient(String address) {
    EmailClient? mailClient;
    if (mailClients.containsKey(address)) {
      mailClient = mailClients[address];
    }
  }

  EmailClient? setDefaultMailClient(String address) {
    EmailClient? mailClient;
    if (mailClients.containsKey(address)) {
      mailClient = mailClients[address];
    }
    _default = mailClient;

    return _default;
  }
}
