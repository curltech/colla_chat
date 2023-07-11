import 'dart:io';

import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/emailaddress.dart' as entity;
import 'package:colla_chat/entity/chat/message_attachment.dart';
import 'package:colla_chat/pages/chat/mail/address/email_service_provider.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:enough_mail/enough_mail.dart' as enough_mail;
import 'package:enough_mail/enough_mail.dart';
import 'package:enough_mail_html/enough_mail_html.dart';
import 'package:event_bus/event_bus.dart';
import 'package:synchronized/synchronized.dart';

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
  static String convertToHtml(
    enough_mail.MimeMessage mimeMessage, {
    bool blockExternalImages = false,
    bool preferPlainText = false,
    bool enableDarkMode = false,
    int? maxImageWidth,
    String? emptyMessageText,
    TransformConfiguration? transformConfiguration,
  }) {
    return mimeMessage.transformToHtml(
        blockExternalImages: blockExternalImages,
        preferPlainText: preferPlainText,
        enableDarkMode: enableDarkMode,
        maxImageWidth: maxImageWidth,
        emptyMessageText: emptyMessageText,
        transformConfiguration: transformConfiguration);
  }

  ///把html转换成普通文本
  static String convertToPlainText(String htmlText) {
    return HtmlToPlainTextConverter.convert(htmlText);
  }

  ///转换邮件消息为平台消息，整个邮件通过序列化方法转换成平台消息的content部分
  static ChatMessage convertToChatMessage(enough_mail.MimeMessage message) {
    ChatMessage chatMessage = ChatMessage();
    chatMessage.id = message.guid;
    chatMessage.messageId = message.uid.toString();
    chatMessage.messageType = ChatMessageType.email.name;
    chatMessage.title = message.decodeSubject();
    var from = message.from;
    if (from != null && from.isNotEmpty) {
      chatMessage.senderName = from.first.personalName;
      chatMessage.senderAddress = from.first.email;
    }
    var to = message.to;
    if (to != null && to.isNotEmpty) {
      chatMessage.receiverName = to.first.personalName;
      chatMessage.receiverAddress = to.first.email;
    }
    chatMessage.contentType = message.mediaType.toString();
    chatMessage.content = message.renderMessage();
    //MimeMessage mimeMessage=MimeMessage.parseFromText(chatMessage.content);
    if (!message.isTextPlainMessage()) {
      chatMessage.attaches = <MessageAttachment>[];
      for (enough_mail.MimePart part in message.allPartsFlat) {
        MessageAttachment attach = MessageAttachment();
        attach.content = part.decodeContentText();
        chatMessage.attaches.add(attach);
      }
    }

    return chatMessage;
  }

  ///转换平台的消息到邮件消息，平台消息的content部分反序列化成邮件消息
  static enough_mail.MimeMessage convertToMimeMessage(ChatMessage chatMessage) {
    enough_mail.MimeMessage message =
        enough_mail.MimeMessage.parseFromText(chatMessage.content!);

    return message;
  }

  ///把外部的html字符串转换成邮件生成的html
  static String convertToMimeMessageHtml(String text) {
    MessageBuilder builder =
        MessageBuilder.prepareMultipartAlternativeMessage();
    builder.addTextHtml(text);
    MimeMessage mimeMessage = builder.buildMimeMessage();

    return convertToHtml(mimeMessage);
  }

  ///转换邮件地址实体信息到邮件地址配置
  static enough_mail.ClientConfig? buildDiscoverConfig(
      entity.EmailAddress mailAddress) {
    enough_mail.ClientConfig config = enough_mail.ClientConfig();
    bool incoming = false;
    bool outcoming = false;
    var imapServerConfigStr = mailAddress.imapServerConfig;
    ConfigEmailProvider provider =
        ConfigEmailProvider(displayName: mailAddress.name);
    config.addEmailProvider(provider);
    if (imapServerConfigStr != null) {
      Map<String, dynamic> imapServerConfigMap =
          JsonUtil.toJson(imapServerConfigStr) as Map<String, dynamic>;
      ServerConfig imapServerConfig =
          ServerConfig.fromJson(imapServerConfigMap);
      provider.addIncomingServer(imapServerConfig);
      incoming = true;
    }
    var popServerConfigStr = mailAddress.popServerConfig;
    if (popServerConfigStr != null) {
      Map<String, dynamic> popServerConfigMap =
          JsonUtil.toJson(popServerConfigStr) as Map<String, dynamic>;
      ServerConfig popServerConfig = ServerConfig.fromJson(popServerConfigMap);
      provider.addIncomingServer(popServerConfig);
      incoming = true;
    }
    var smtpServerConfigStr = mailAddress.smtpServerConfig;
    if (smtpServerConfigStr != null) {
      Map<String, dynamic> smtpServerConfigMap =
          JsonUtil.toJson(smtpServerConfigStr) as Map<String, dynamic>;
      ServerConfig smtpServerConfig =
          ServerConfig.fromJson(smtpServerConfigMap);
      provider.addOutgoingServer(smtpServerConfig);
      outcoming = true;
    }
    if (incoming && outcoming) {
      return config;
    }
    return null;
  }

  /// 寻找email的邮件服务提供商，先搜索著名的提供商列表，如果存在直接返回
  /// 否则，自动发现邮件地址配置，然后加入服务商提供商列表
  static Future<EmailServiceProvider?> discover(String email) async {
    final emailDomain = email.substring(email.indexOf('@') + 1);
    final emailServiceProvider = platformEmailServiceProvider.domainNameServiceProviders[emailDomain];
    if (emailServiceProvider != null) {
      return emailServiceProvider;
    }
    try {
      final clientConfig = await Discover.discover(email,
          forceSslConnection: true, isLogEnabled: true);
      if (clientConfig == null ||
          clientConfig.preferredIncomingServer == null) {
        return null;
      }
      final hostName = clientConfig.preferredIncomingServer!.hostname!;
      final providerHostName = platformEmailServiceProvider.domainNameServiceProviders[hostName];
      if (providerHostName != null) {
        return providerHostName;
      }
      final domainName = email.substring(email.indexOf('@') + 1);

      return EmailServiceProvider(domainName, hostName, clientConfig);
    } catch (e, s) {
      logger.e('Unable to discover settings for [$email]: $e $s');
      return null;
    }
  }

  ///传入email，name和邮件地址配置参数，产生新的邮件地址实体
  static entity.EmailAddress buildDiscoverEmailAddress(
      String email, String name, ClientConfig config) {
    entity.EmailAddress mailAddress =
        entity.EmailAddress(email: email, name: name);

    for (final provider in config.emailProviders!) {
      ServerConfig? imapServerConfig = provider.preferredIncomingImapServer;
      if (imapServerConfig != null) {
        mailAddress.imapServerSecure = imapServerConfig.isSecureSocket;
        int? port = imapServerConfig.port;
        if (port != null) {
          mailAddress.imapServerPort = port;
        }
        mailAddress.imapServerHost = imapServerConfig.hostname;
        Map<String, dynamic> attributes = imapServerConfig.toJson();
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
        Map<String, dynamic> attributes = popServerConfig.toJson();
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
        Map<String, dynamic> attributes = smtpServerConfig.toJson();
        mailAddress.smtpServerConfig = JsonUtil.toJsonString(attributes);
      }
      break;
    }

    return mailAddress;
  }

  ///识别本APP的客户端Id
  static const clientId = Id(
      name: 'CollaChat',
      version: '1.2.0',
      vendor: 'curltech.io',
      nonStandardFields: {'support-email': 'hujs@curltech.io'});

  ///用邮件地址配置创建邮件客户端
  static enough_mail.MailClient createMailClient(
      {required String name,
      required String email,
      required String password,
      required enough_mail.ClientConfig config}) {
    final account = enough_mail.MailAccount.fromDiscoveredSettings(
        name: name,
        email: email,
        password: password,
        config: config,
        outgoingClientDomain: 'curltech.io',
        userName: email);

    final mailClient =
        enough_mail.MailClient(account, isLogEnabled: true, clientId: clientId);

    return mailClient;
  }
}

class EmailClient {
  entity.EmailAddress emailAddress;
  Lock lock = Lock();

  ///mailClient是自动发现产生的客户端
  ClientConfig? config;
  enough_mail.MailClient? mailClient;
  enough_mail.ImapClient? imapClient;
  enough_mail.PopClient? popClient;
  enough_mail.SmtpClient? smtpClient;

  EmailClient({
    required this.emailAddress,
  });

  ///统一的连接方法，先用邮件地址参数连接，不成功再用imap和pop手工配置的参数连接
  Future<bool> connect(String? password, {ClientConfig? config}) async {
    if (password != null && emailAddress.password != password) {
      emailAddress.password = password;
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

  ///邮件客户端连接，可以传入密码和邮件地址参数，如果没有则使用当前邮件客户端的数据
  Future<bool> mailClientConnect(
      {String? password, ClientConfig? config}) async {
    if (password != null && emailAddress.password != password) {
      emailAddress.password = password;
    }
    if (config != null) {
      this.config = config;
    }
    config = this.config;
    if (config == null) {
      this.config = EmailMessageUtil.buildDiscoverConfig(emailAddress);
      config = this.config;
      if (config == null) {
        logger.e('no discover config');
        return false;
      }
    }
    password = emailAddress.password;
    if (password == null) {
      logger.e('no password');
      return false;
    }
    final enough_mail.MailClient mailClient = EmailMessageUtil.createMailClient(
        name: emailAddress.name,
        email: emailAddress.email,
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

  Future<List<enough_mail.MimeMessage>?> fetchMessages(
      {int limit = defaultLimit,
      FetchPreference fetchPreference = FetchPreference.fullWhenWithinSize,
      Mailbox? mailbox,
      int offset = defaultOffset}) async {
    return await lock.synchronized(() async {
      return await _fetchMessages(
          limit: limit,
          fetchPreference: fetchPreference,
          mailbox: mailbox,
          offset: offset);
    });
  }

  ///用邮件客户端获取消息，可以设定完全获取，或者部分获取
  ///默认是在尺寸内的完全获取，或者只获取封面
  Future<List<enough_mail.MimeMessage>?> _fetchMessages(
      {int limit = defaultLimit,
      FetchPreference fetchPreference = FetchPreference.fullWhenWithinSize,
      Mailbox? mailbox,
      int offset = defaultOffset}) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null && mailbox != null) {
      int total = mailbox.messagesExists;
      int page = Pagination.getPage(offset, limit);
      try {
        final messages = await mailClient.fetchMessages(
            count: limit,
            fetchPreference: fetchPreference,
            mailbox: mailbox,
            page: page);
        return messages;
      } catch (e) {
        logger.e('fetch messages failure:$e');
      }
    }
    return null;
  }

  ///获取完整的消息，用于先前获取了消息的FetchPreference.envelope情况下
  Future<enough_mail.MimeMessage?> fetchMessageContents(
    MimeMessage message, {
    int? maxSize,
    bool markAsSeen = false,
    List<MediaToptype>? includedInlineTypes,
    Duration? responseTimeout,
  }) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      message = await mailClient.fetchMessageContents(message,
          maxSize: maxSize,
          markAsSeen: markAsSeen,
          includedInlineTypes: includedInlineTypes,
          responseTimeout: responseTimeout);

      return message;
    }
    return null;
  }

  Future<List<enough_mail.MimeMessage>?> fetchMessagesNextPage(
    PagedMessageSequence pagedSequence, {
    Mailbox? mailbox,
    FetchPreference fetchPreference = FetchPreference.fullWhenWithinSize,
    bool markAsSeen = false,
  }) async {
    return await lock.synchronized(() async {
      return await _fetchMessagesNextPage(pagedSequence,
          fetchPreference: fetchPreference,
          mailbox: mailbox,
          markAsSeen: markAsSeen);
    });
  }

  ///取给定的页号的下一页
  Future<List<enough_mail.MimeMessage>?> _fetchMessagesNextPage(
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

  ///根据fetchId获取邮件的部分，fetchId是由邮件的findContentInfo方法获取的
  Future<MimePart?> fetchMessagePart(
    MimeMessage message,
    String fetchId, {
    Duration? responseTimeout,
  }) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      return await mailClient.fetchMessagePart(message, fetchId,
          responseTimeout: responseTimeout);
    }
  }

  ///删除邮件
  Future<DeleteResult?> deleteMessage(enough_mail.MimeMessage message,
      {bool expunge = false}) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      return await mailClient.deleteMessage(message, expunge: expunge);
    }
    return null;
  }

  Future<DeleteResult?> deleteMessages(MessageSequence sequence,
      {bool expunge = false, List<enough_mail.MimeMessage>? messages}) async {
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
    return await lock.synchronized(() async {
      return await _fetchMessageSequence(sequence,
          fetchPreference: fetchPreference,
          mailbox: mailbox,
          markAsSeen: markAsSeen);
    });
  }

  Future<List<enough_mail.MimeMessage>?> _fetchMessageSequence(
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
    return await lock.synchronized(() async {
      return await _searchMessagesNextPage(searchResult);
    });
  }

  Future<List<enough_mail.MimeMessage>?> _searchMessagesNextPage(
      MailSearchResult searchResult) async {
    final enough_mail.MailClient? mailClient = this.mailClient;
    if (mailClient != null) {
      return await mailClient.searchMessagesNextPage(searchResult);
    }
    return null;
  }

  Future<enough_mail.MailSearchResult?> searchMessages(
      MailSearch search) async {
    return await lock.synchronized(() async {
      return await _searchMessages(search);
    });
  }

  Future<enough_mail.MailSearchResult?> _searchMessages(
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
      try {
        return await mailClient.saveDraftMessage(message,
            draftsMailbox: draftsMailbox);
      } catch (e) {
        logger.e('save draft message failure:$e');
      }
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
      try {
        await mailClient.sendMessage(mimeMessage,
            from: from,
            appendToSent: appendToSent,
            sentMailbox: sentMailbox,
            use8BitEncoding: use8BitEncoding,
            recipients: recipients);
        return true;
      } catch (e) {
        logger.e('send message failure:$e');
      }
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
      if (emailAddress.imapServerHost != null) {
        await client.connectToServer(
            emailAddress.imapServerHost!, emailAddress.imapServerPort,
            isSecure: emailAddress.imapServerSecure);
        List<enough_mail.Capability> capabilities =
            await client.login(emailAddress.email, emailAddress.password!);
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
  Future<bool> _smtpConnect() async {
    var client = enough_mail.SmtpClient('curltech.io', isLogEnabled: true);
    try {
      if (emailAddress.smtpServerHost != null) {
        var connectionInfo = await client.connectToServer(
            emailAddress.smtpServerHost!, emailAddress.smtpServerPort,
            isSecure: emailAddress.smtpServerSecure);
        SmtpResponse smtpResponse = await client.ehlo();
        if (!smtpResponse.isOkStatus) {
          logger.e('smtpConnect failure: ${smtpResponse.errorMessage}');
          return false;
        }
        if (client.serverInfo.supportsAuth(enough_mail.AuthMechanism.plain)) {
          SmtpResponse smtpResponse = await client.authenticate(
              emailAddress.email,
              emailAddress.password!,
              enough_mail.AuthMechanism.plain);
          if (!smtpResponse.isOkStatus) {
            logger.e('smtpConnect failure: ${smtpResponse.errorMessage}');
            return false;
          }
          logger.i('smtpConnect successfully: ${smtpResponse.message}');
          smtpClient = client;
          return true;
        }
      } else if (client.serverInfo
          .supportsAuth(enough_mail.AuthMechanism.login)) {
        SmtpResponse smtpResponse = await client.authenticate(
            emailAddress.email,
            emailAddress.password!,
            enough_mail.AuthMechanism.login);
        if (!smtpResponse.isOkStatus) {
          logger.e('smtpConnect failure: ${smtpResponse.errorMessage}');
          return false;
        }
        smtpClient = client;
        logger.i('smtpConnect successfully: $smtpResponse');
        return true;
      } else {
        logger.e('smtpConnect failure: error authMechanism');
        return false;
      }
    } on enough_mail.SmtpException catch (e) {
      logger.e('smtpConnect failed with $e');
    }
    return false;
  }

  Future<bool> smtpSend(
    MimeMessage mimeMessage, {
    bool use8BitEncoding = false,
    MailAddress? from,
    List<MailAddress>? recipients,
  }) async {
    var smtpClient = this.smtpClient;
    if (smtpClient == null || !smtpClient.isConnected) {
      bool success = await _smtpConnect();
      smtpClient = this.smtpClient;
      if (!success) {
        return false;
      }
    }
    if (smtpClient != null && smtpClient.isConnected) {
      try {
        final sendResponse = await smtpClient.sendMessage(mimeMessage,
            use8BitEncoding: use8BitEncoding,
            from: from,
            recipients: recipients);
        logger.i('smtpSend message: ${sendResponse.isOkStatus}');
        smtpClient.disconnect();
        this.smtpClient = null;

        return sendResponse.isOkStatus;
      } catch (e) {
        logger.i('smtpSend message failure: $e');
        smtpClient.disconnect();
        this.smtpClient = null;
      }
    }
    return false;
  }

  /// POP3协议连接
  Future<PopStatus?> popConnect() async {
    final client = enough_mail.PopClient(isLogEnabled: false);
    try {
      if (emailAddress.popServerHost != null) {
        var connectionInfo = await client.connectToServer(
            emailAddress.popServerHost!, emailAddress.popServerPort,
            isSecure: emailAddress.popServerSecure);
        logger.i('connectToServer $connectionInfo');
        await client.login(emailAddress.email, emailAddress.password!);
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
  var emailClients = <String, EmailClient>{};
  EmailClient? _default;

  EmailClientPool();

  ///在连接池中创建一个邮件的连接，必须连接成功才能创建
  ///传入的邮件地址实体参数必须含有email字段，或者有自动发现的配置，或者有imap和smtp的配置
  Future<EmailClient?> create(entity.EmailAddress mailAddress, String password,
      {ClientConfig? config}) async {
    var emails = mailAddress.email.split('@');
    if (emails.length != 2) {
      logger.e('mailAddress email error');
      return null;
    }
    EmailClient? emailClient = emailClients[mailAddress.email];
    if (emailClient != null) {
      return emailClient;
    } else {
      emailClient = EmailClient(emailAddress: mailAddress);
      bool success = await emailClient.connect(password, config: config);
      if (success) {
        emailClients[mailAddress.email] = emailClient;

        return emailClient;
      }
    }

    return null;
  }

  ///如果池中的邮件客户端断开了，可以重新进行连接
  Future<bool> connect(String email, String? password) async {
    EmailClient? emailClient = get(email);
    bool success = false;
    if (emailClient != null) {
      success = await emailClient.connect(password);
      return success;
    }
    return success;
  }

  EmailClient? get(String email) {
    if (emailClients.containsKey(email)) {
      return emailClients[email];
    } else {
      return null;
    }
  }

  close(String email) async {
    if (emailClients.containsKey(email)) {
      var mailClient = emailClients[email];
      if (mailClient != null) {
        await mailClient.close();
      }
      emailClients.remove(email);
    }
  }

  EmailClient? get defaultMailClient {
    return _default;
  }

  EmailClient? setDefaultMailClient(String email) {
    EmailClient? mailClient;
    if (emailClients.containsKey(email)) {
      mailClient = emailClients[email];
    }
    _default = mailClient;

    return _default;
  }
}

final EmailClientPool emailClientPool = EmailClientPool();
