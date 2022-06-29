import 'dart:io';

import 'package:enough_mail/discover.dart';
import 'package:enough_mail/enough_mail.dart' as enough_mail;
import 'package:enough_mail/enough_mail.dart';
import 'package:enough_mail_html/enough_mail_html.dart';
import 'package:event_bus/event_bus.dart';

import '../constant/base.dart';
import '../datastore/datastore.dart';
import '../entity/chat/chat.dart';
import '../entity/chat/mailaddress.dart' as entity;
import '../provider/app_data_provider.dart';
import '../tool/util.dart';

class EmailMessageUtil {
  /// 创建带附件的消息
  static Future<enough_mail.MimeMessage> buildMessage({
    required List<enough_mail.MailAddress> from,
    required List<enough_mail.MailAddress> to,
    String? plainText,
    String? htmlText,
    enough_mail.TransferEncoding transferEncoding =
        enough_mail.TransferEncoding.eightBit,
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
    chatMessage.id = message.guid;
    chatMessage.messageId = message.uid.toString();
    chatMessage.messageType = MessageType.email.name;
    chatMessage.title = message.decodeSubject();
    var from = message.from;
    if (from != null && from.isNotEmpty) {
      chatMessage.senderName = from.first.personalName;
      chatMessage.senderAddress = from.first.email;
    }
    var to = message.to;
    if (to != null && to.isNotEmpty) {
      chatMessage.targetName = to.first.personalName;
      chatMessage.targetAddress = to.first.email;
    }
    chatMessage.contentType = message.mediaType.toString();
    chatMessage.content = message.renderMessage();
    //MimeMessage mimeMessage=MimeMessage.parseFromText(chatMessage.content);
    if (!message.isTextPlainMessage()) {
      chatMessage.attaches = <MessageAttachment>[];
      for (enough_mail.MimePart part in message.allPartsFlat) {
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

  static enough_mail.ClientConfig? buildDiscoverConfig(
      entity.MailAddress mailAddress) {
    enough_mail.ClientConfig config = enough_mail.ClientConfig();
    bool incoming = false;
    bool outcoming = false;
    var imapServerConfigStr = mailAddress.imapServerConfig;
    ConfigEmailProvider provider =
        ConfigEmailProvider(displayName: mailAddress.name);
    config.addEmailProvider(provider);
    if (imapServerConfigStr != null) {
      Map<String, dynamic> imapServerConfigMap =
          JsonUtil.toMap(imapServerConfigStr) as Map<String, dynamic>;
      ServerConfig imapServerConfig = ServerConfig();
      imapServerConfig.read(imapServerConfigMap);
      provider.addIncomingServer(imapServerConfig);
      incoming = true;
    }
    var popServerConfigStr = mailAddress.popServerConfig;
    if (popServerConfigStr != null) {
      Map<String, dynamic> popServerConfigMap =
          JsonUtil.toMap(popServerConfigStr) as Map<String, dynamic>;
      ServerConfig popServerConfig = ServerConfig();
      popServerConfig.read(popServerConfigMap);
      provider.addIncomingServer(popServerConfig);
      incoming = true;
    }
    var smtpServerConfigStr = mailAddress.smtpServerConfig;
    if (smtpServerConfigStr != null) {
      Map<String, dynamic> smtpServerConfigMap =
          JsonUtil.toMap(smtpServerConfigStr) as Map<String, dynamic>;
      ServerConfig smtpServerConfig = ServerConfig();
      smtpServerConfig.read(smtpServerConfigMap);
      ConfigEmailProvider provider = ConfigEmailProvider();
      provider.addIncomingServer(smtpServerConfig);
      outcoming = true;
    }
    if (incoming && outcoming) {
      return config;
    }
    return null;
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
      logger.e('Unable to auto-discover settings for $email');
    }

    return config;
  }

  ///自动发现邮件配置，产生新的邮件地址
  static entity.MailAddress buildDiscoverMailAddress(
      String email, String name, ClientConfig config) {
    logger.i('config displayName: ${config.displayName}.');
    entity.MailAddress mailAddress =
        entity.MailAddress(email: email, name: name);

    for (final provider in config.emailProviders!) {
      ServerConfig? imapServerConfig = provider.preferredIncomingImapServer;
      if (imapServerConfig != null) {
        mailAddress.imapServerSecure = imapServerConfig.isSecureSocket;
        int? port = imapServerConfig.port;
        if (port != null) {
          mailAddress.imapServerPort = port;
        }
        mailAddress.imapServerHost = imapServerConfig.hostname;
        Map<String, dynamic> attributes = {};
        imapServerConfig.write(attributes);
        mailAddress.imapServerConfig = JsonUtil.toJsonString(attributes);
      }
      ServerConfig? popServerConfig = provider.preferredIncomingPopServer;
      if (popServerConfig != null) {
        mailAddress.popServerSecure = popServerConfig.isSecureSocket;
        int? port = popServerConfig.port;
        if (port != null) {
          mailAddress.popServerPort = port;
        }
        mailAddress.popServerHost = popServerConfig.hostname;
        Map<String, dynamic> attributes = {};
        popServerConfig.write(attributes);
        mailAddress.popServerConfig = JsonUtil.toJsonString(attributes);
      }
      ServerConfig? smtpServerConfig = provider.preferredOutgoingSmtpServer;
      if (smtpServerConfig != null) {
        mailAddress.smtpServerSecure = smtpServerConfig.isSecureSocket;
        int? port = smtpServerConfig.port;
        if (port != null) {
          mailAddress.smtpServerPort = port;
        }
        mailAddress.smtpServerHost = smtpServerConfig.hostname;
        Map<String, dynamic> attributes = {};
        smtpServerConfig.write(attributes);
        mailAddress.smtpServerConfig = JsonUtil.toJsonString(attributes);
      }
      break;
    }

    return mailAddress;
  }

  static const clientId = Id(
      name: 'myname',
      version: '1.0.0',
      vendor: 'myclient',
      nonStandardFields: {'support-email': 'testmail@test.com'});

  ///用自动发现的配置创建邮件客户端
  static enough_mail.MailClient createMailClient(
      {required String name,
      required String email,
      required String password,
      required enough_mail.ClientConfig config}) {
    final account = enough_mail.MailAccount.fromDiscoveredSettings(
        name, email, password, config,
        outgoingClientDomain: '');

    final mailClient =
        enough_mail.MailClient(account, isLogEnabled: true, clientId: clientId);
    logger.i(mailClient.serverId);

    return mailClient;
  }
}

class EmailClient {
  entity.MailAddress mailAddress;

  ///mailClient是自动发现产生的客户端
  ClientConfig? config;
  enough_mail.MailClient? mailClient;
  enough_mail.ImapClient? imapClient;
  enough_mail.PopClient? popClient;
  enough_mail.SmtpClient? smtpClient;

  EmailClient({
    required this.mailAddress,
  });

  ///统一的连接方法，先用自动发现的参数连接，不成功再用imap等手工配置的参数
  Future<bool> connect(String? password, {ClientConfig? config}) async {
    if (password != null && mailAddress.password != password) {
      mailAddress.password = password;
    }
    bool success = false;
    if (mailClient == null) {
      success = await mailClientConnect(password: password, config: config);
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

  ///用mailaddress参数解析出自动发现的config进行连接
  Future<bool> mailClientConnect(
      {String? password, ClientConfig? config}) async {
    if (password != null && mailAddress.password != password) {
      mailAddress.password = password;
    }
    if (config != null) {
      this.config = config;
    }
    config = this.config;
    if (config == null) {
      this.config = EmailMessageUtil.buildDiscoverConfig(mailAddress);
      config = this.config;
      if (config == null) {
        logger.e('no discover config');
        return false;
      }
    }
    password = mailAddress.password;
    if (password == null) {
      logger.e('no password');
      return false;
    }
    final enough_mail.MailClient mailClient = EmailMessageUtil.createMailClient(
        name: mailAddress.name,
        email: mailAddress.email,
        password: password,
        config: config);
    try {
      await mailClient.connect();
      logger.i('connected successfully');
      this.mailClient = mailClient;

      return true;
    } on enough_mail.MailException catch (e) {
      logger.e('High level API failed with $e');
      this.mailClient = null;
    }
    return false;
  }

  ///用邮件客户端获取邮箱树，知道邮箱的概况
  Future<Tree<Mailbox?>?> listMailboxesAsTree(
      {bool createIntermediate = true,
      List<MailboxFlag> order =
          enough_mail.MailClient.defaultMailboxOrder}) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      final mailboxes = await mailClient.listMailboxesAsTree(
          createIntermediate: createIntermediate, order: order);
      logger.i(mailboxes);
      return mailboxes;
    }
    return null;
  }

  ///用邮件客户端获取邮箱，知道邮箱的概况
  Future<List<Mailbox>?> listMailboxes(
      {List<MailboxFlag> order =
          enough_mail.MailClient.defaultMailboxOrder}) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      final mailboxes = await mailClient.listMailboxes(order: order);
      logger.i(mailboxes);
      return mailboxes;
    }
    return null;
  }

  ///用邮件客户端获取收件箱
  Future<Mailbox?> selectInbox(
      {bool enableCondStore = false, QResyncParameters? qresync}) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      var mailbox = await mailClient.selectInbox(
          enableCondStore: enableCondStore, qresync: qresync);
      return mailbox;
    }
    return null;
  }

  ///创建收件箱
  Future<Mailbox?> createMailbox(String mailboxName,
      {Mailbox? parentMailbox}) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      var mailbox = await mailClient.createMailbox(mailboxName,
          parentMailbox: parentMailbox);
      return mailbox;
    }
    return null;
  }

  ///创建收件箱
  Future<void> deleteMailbox(Mailbox mailbox) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      await mailClient.deleteMailbox(mailbox);
      return;
    }
  }

  ///创建收件箱
  Mailbox? getMailbox(MailboxFlag flag, [List<Mailbox>? mailBoxes]) {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      var mailbox = mailClient.getMailbox(flag, mailBoxes);
      return mailbox;
    }
    return null;
  }

  Future<enough_mail.Mailbox?> selectMailbox(
    Mailbox mailbox, {
    bool enableCondStore = false,
    QResyncParameters? qresync,
  }) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      return await mailClient.selectMailbox(mailbox,
          enableCondStore: enableCondStore, qresync: qresync);
    }
    return null;
  }

  ///用邮件客户端获取消息
  Future<Page<MimeMessage>?> fetchMessages(
      {int limit = defaultLimit,
      FetchPreference fetchPreference = FetchPreference.fullWhenWithinSize,
      Mailbox? mailbox,
      int offset = defaultOffset}) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null && mailbox != null) {
      int total = mailbox.messagesExists;
      final messages = await mailClient.fetchMessages(
          count: limit,
          fetchPreference: fetchPreference,
          mailbox: mailbox,
          page: Page.getPage(offset, limit));
      return Page(total: total, data: messages, limit: limit, offset: offset);
    }
    return null;
  }

  Future<List<MimeMessage>?> fetchMessagesNextPage(
    PagedMessageSequence pagedSequence, {
    Mailbox? mailbox,
    FetchPreference fetchPreference = FetchPreference.fullWhenWithinSize,
    bool markAsSeen = false,
  }) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      return await mailClient.fetchMessagesNextPage(pagedSequence,
          mailbox: mailbox,
          fetchPreference: fetchPreference,
          markAsSeen: markAsSeen);
    }
    return null;
  }

  Future<DeleteResult?> deleteMessage(MimeMessage message,
      {bool expunge = false}) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      return await mailClient.deleteMessage(message, expunge: expunge);
    }
    return null;
  }

  Future<DeleteResult?> deleteMessages(MessageSequence sequence,
      {bool expunge = false, List<MimeMessage>? messages}) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      return await mailClient.deleteMessages(sequence,
          expunge: expunge, messages: messages);
    }
    return null;
  }

  Future<DeleteResult?> deleteAllMessages(Mailbox mailbox,
      {bool expunge = false}) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      return await mailClient.deleteAllMessages(mailbox, expunge: expunge);
    }
    return null;
  }

  Future<List<enough_mail.MimeMessage>?> fetchMessageSequence(
    MessageSequence sequence, {
    Mailbox? mailbox,
    FetchPreference fetchPreference = FetchPreference.fullWhenWithinSize,
    bool markAsSeen = false,
  }) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      return await mailClient.fetchMessageSequence(sequence,
          mailbox: mailbox,
          fetchPreference: fetchPreference,
          markAsSeen: markAsSeen);
    }
    return null;
  }

  Future<void> flagMessage(
    MimeMessage message, {
    bool? isSeen,
    bool? isFlagged,
    bool? isAnswered,
    bool? isForwarded,
    bool? isDeleted,
    bool? isMdnSent,
    bool? isReadReceiptSent,
  }) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      return await mailClient.flagMessage(message,
          isSeen: isSeen,
          isFlagged: isFlagged,
          isAnswered: isAnswered,
          isForwarded: isForwarded,
          isDeleted: isDeleted,
          isMdnSent: isMdnSent,
          isReadReceiptSent: isReadReceiptSent);
    }
  }

  Future<List<enough_mail.MimeMessage>?> searchMessagesNextPage(
      MailSearchResult searchResult) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      return await mailClient.searchMessagesNextPage(searchResult);
    }
    return null;
  }

  Future<enough_mail.MailSearchResult?> searchMessages(
      MailSearch search) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      return await mailClient.searchMessages(search);
    }
    return null;
  }

  Future<enough_mail.MoveResult?> moveMessage(
      MimeMessage message, Mailbox target) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      return await mailClient.moveMessage(message, target);
    }
    return null;
  }

  Future<enough_mail.MoveResult?> moveMessages(
    MessageSequence sequence,
    Mailbox target, {
    List<MimeMessage>? messages,
  }) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      return await mailClient.moveMessages(sequence, target,
          messages: messages);
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
    final enough_mail.MailClient? mailClient = this.mailClient;
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
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      await mailClient.startPolling(duration);
      return true;
    }
    return false;
  }

  Future<bool> stopPolling() async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      await mailClient.stopPolling();
      return true;
    }
    return false;
  }

  Future<bool> reconnect() async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      await mailClient.reconnect();
      return true;
    }
    return false;
  }

  Future<MoveResult?> junkMessage(MimeMessage message) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      return await mailClient.junkMessage(message);
    }
    return null;
  }

  Future<MoveResult?> junkMessages(MessageSequence sequence,
      {List<enough_mail.MimeMessage>? messages}) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      return await mailClient.junkMessages(sequence, messages: messages);
    }
    return null;
  }

  Future<enough_mail.DeleteResult?> undoDeleteMessages(
      DeleteResult deleteResult) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      return await mailClient.undoDeleteMessages(deleteResult);
    }
    return null;
  }

  Future<UidResponseCode?> saveDraftMessage(MimeMessage message,
      {Mailbox? draftsMailbox}) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      return await mailClient.saveDraftMessage(message,
          draftsMailbox: draftsMailbox);
    }
    return null;
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
    final enough_mail.MailClient? mailClient = this.mailClient;
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
    enough_mail.MailClient? mailClient = this.mailClient;
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
    if (client.serverInfo.supportsId) {
      final serverId = await client.id(clientId: EmailMessageUtil.clientId);
      logger.i(serverId);
    }
    try {
      if (mailAddress.imapServerHost != null) {
        await client.connectToServer(
            mailAddress.imapServerHost!, mailAddress.imapServerPort,
            isSecure: mailAddress.imapServerSecure);
        List<enough_mail.Capability> capabilities =
            await client.login(mailAddress.email, mailAddress.password!);
        logger.i('imap login successfully, $capabilities');

        imapClient = client;
      }
    } on enough_mail.ImapException catch (e) {
      logger.e('imap login failed with $e');
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
      logger.e('imapListMailboxes failed with $e');
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
      logger.e('imapSelectInbox failed with $e');
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
      logger.e('imap fetchRecentMessages failed with $e');
    }

    return null;
  }

  Future<bool> imapLogout() async {
    try {
      final imapClient = this.imapClient;
      if (imapClient != null) {
        var response = await imapClient.logout();
        if (response != null) {
          logger.i('imapLogout successfully');
        }
        this.imapClient = null;
        return true;
      }
    } on enough_mail.ImapException catch (e) {
      logger.e('imapLogout failed with $e');
    }
    return false;
  }

  /// smtp协议连接Connect
  Future<bool> smtpConnect() async {
    var client =
        enough_mail.SmtpClient(mailAddress.domain!, isLogEnabled: true);
    try {
      if (mailAddress.smtpServerHost != null) {
        var connectionInfo = await client.connectToServer(
            mailAddress.smtpServerHost!, mailAddress.smtpServerPort,
            isSecure: mailAddress.smtpServerSecure);
        SmtpResponse smtpResponse = await client.ehlo();
        if (!smtpResponse.isOkStatus) {
          return false;
        }
        if (client.serverInfo.supportsAuth(enough_mail.AuthMechanism.plain)) {
          SmtpResponse smtpResponse = await client.authenticate(
              mailAddress.email,
              mailAddress.password!,
              enough_mail.AuthMechanism.plain);
          if (!smtpResponse.isOkStatus) {
            return false;
          }
          logger.i('smtpConnect successfully: $connectionInfo');
          smtpClient = client;
          return true;
        }
      } else if (client.serverInfo
          .supportsAuth(enough_mail.AuthMechanism.login)) {
        SmtpResponse smtpResponse = await client.authenticate(mailAddress.email,
            mailAddress.password!, enough_mail.AuthMechanism.login);
        if (!smtpResponse.isOkStatus) {
          return false;
        }
        smtpClient = client;
        logger.i('smtpConnect successfully: $smtpResponse');
        return true;
      } else {
        return false;
      }
    } on enough_mail.SmtpException catch (e) {
      logger.e('smtpConnect failed with $e');
    }
    return false;
  }

  Future<bool> smtpSend(MimeMessage mimeMessage) async {
    var smtpClient = this.smtpClient;
    if (smtpClient != null) {
      final sendResponse = await smtpClient.sendMessage(mimeMessage);
      logger.i('smtpSend message: ${sendResponse.isOkStatus}');
      return sendResponse.isOkStatus;
    }
    return false;
  }

  /// POP3协议连接
  Future<PopStatus?> popConnect() async {
    final client = enough_mail.PopClient(isLogEnabled: false);
    try {
      if (mailAddress.popServerHost != null) {
        var connectionInfo = await client.connectToServer(
            mailAddress.popServerHost!, mailAddress.popServerPort,
            isSecure: mailAddress.popServerSecure);
        logger.i('connectToServer $connectionInfo');
        await client.login(mailAddress.email, mailAddress.password!);
        // alternative login:
        // await client.loginWithApop(username, password);
        final status = await client.status();
        logger
            .i('popConnect status: messages count=${status.numberOfMessages}, '
                'messages size=${status.totalSizeInBytes}');
        popClient = client;
        return status;
      }
    } on enough_mail.PopException catch (e) {
      logger.e('popConnect failed with $e');
    }
    return null;
  }

  Future<List<MessageListing>?> popList() async {
    final client = popClient;
    try {
      if (client != null) {
        final status = await client.status();
        logger.i('popList status: messages count=${status.numberOfMessages}, '
            'messages size=${status.totalSizeInBytes}');
        final messageList = await client.list(status.numberOfMessages);
        logger.i('last message: id=${messageList.first.id} '
            'size=${messageList.first.sizeInBytes}');
        return messageList;
      }
    } on enough_mail.PopException catch (e) {
      logger.e('popList failed with $e');
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
        logger.i('popReceive trying to retrieve newer message succeeded');
        await popClose();
        return messages;
      }
    } on enough_mail.PopException catch (e) {
      logger.e('popReceive failed with $e');
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
      logger.e('popClose failed with $e');
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

  ///在连接池中创建一个邮件的连接，必须连接成功才能创建
  ///传入的邮件地址参数必须含有email，或者有自动发现的配置，或者有imap和smtp的配置
  Future<EmailClient?> create(entity.MailAddress mailAddress, String password,
      {ClientConfig? config}) async {
    var emails = mailAddress.email.split('@');
    if (emails.length != 2) {
      logger.e('mailAddress email error');
      return null;
    }
    EmailClient? mailClient = mailClients[mailAddress.email];
    if (mailClient != null) {
      return mailClient;
    } else {
      mailClient = EmailClient(mailAddress: mailAddress);
      bool success = await mailClient.connect(password, config: config);
      if (success) {
        mailClients[mailAddress.email] = mailClient;

        return mailClient;
      }
    }

    return null;
  }

  ///如果池中的邮件客户端断开了，可以重新进行连接
  Future<bool> connect(String email, String? password) async {
    EmailClient? mailClient = get(email);
    bool success = false;
    if (mailClient != null) {
      success = await mailClient.connect(password);
      return success;
    }
    return success;
  }

  EmailClient? get(String email) {
    if (mailClients.containsKey(email)) {
      return mailClients[email];
    } else {
      return null;
    }
  }

  close(String email) async {
    if (mailClients.containsKey(email)) {
      var mailClient = mailClients[email];
      if (mailClient != null) {
        await mailClient.close();
      }
      mailClients.remove(email);
    }
  }

  EmailClient? get defaultMailClient {
    return _default;
  }

  EmailClient? setDefaultMailClient(String email) {
    EmailClient? mailClient;
    if (mailClients.containsKey(email)) {
      mailClient = mailClients[email];
    }
    _default = mailClient;

    return _default;
  }
}
