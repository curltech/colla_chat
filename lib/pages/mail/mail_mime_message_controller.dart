import 'dart:async';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/mail/mail_address.dart' as entity;
import 'package:colla_chat/entity/mail/mail_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/mail/mail_address.dart';
import 'package:colla_chat/service/mail/mail_message.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:enough_mail/enough_mail.dart' as enough_mail;
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

class DecryptedMimeMessage {
  //如果needDecrypt为true，payloadKey为空，则为linkman加密，否则是group的加密密钥
  String? payloadKey;

  //解密后的标题
  String? subject;
  MailAddress? sender;
  String? sendTime;

  //解密后的html
  String? html;
  bool needDecrypt;

  DecryptedMimeMessage(
      {this.needDecrypt = false,
      this.payloadKey,
      this.subject,
      this.sender,
      this.sendTime,
      this.html});
}

/// 邮件地址控制器，每个地址有多个邮箱，每个邮箱包含多个邮件
class MailMimeMessageController extends DataListController<entity.MailAddress> {
  Lock lock = Lock();

  ///邮件地址，邮箱名称和邮箱的映射
  final Map<String, Map<String, enough_mail.Mailbox>> _addressMailboxes = {};

  ///邮件地址，邮箱名称和邮件列表的映射
  final Map<String, Map<String, List<MailMessage>>> _addressMailMessages = {};

  ///缺省的邮件地址
  entity.MailAddress? defaultMailAddress;

  String? _currentMailboxName = 'INBOX';

  ///当前的邮箱名称,
  enough_mail.Mailbox? _currentMailbox;

  ///当前的邮件
  int _currentMailIndex = -1;

  final Map<String, IconData> _mailBoxIcons = {};

  @override
  clear({bool? notify}) {
    _addressMailboxes.clear();
    _addressMailMessages.clear();
    _currentMailboxName = null;
    _currentMailbox = null;
    return super.clear(notify: notify);
  }

  ///常用的邮箱名称
  static const Map<String, IconData> mailBoxeIcons = {
    'INBOX': Icons.inbox,
    'DRAFTS': Icons.drafts,
    'SENT': Icons.send,
    'TRASH': Icons.delete,
    'JUNK': Icons.restore_from_trash,
    'MARK': Icons.flag,
    'BACKUP': Icons.backup,
    'ADS': Icons.ads_click,
    'VIRUS': Icons.coronavirus,
    'SUBSCRIPT': Icons.subscript,
  };

  ///构造函数从数据库获取所有的邮件地址，初始化邮箱数据
  MailMimeMessageController() {
    for (var mailBoxeIcon in mailBoxeIcons.entries) {
      String name = mailBoxeIcon.key;
      String localeName = AppLocalizations.t(name);
      _mailBoxIcons[name] = mailBoxeIcon.value;
      _mailBoxIcons[localeName] = mailBoxeIcon.value;
    }
  }

  ///创建邮件地址的目录的图标
  IconData? findDirectoryIcon(String name) {
    IconData? iconData = _mailBoxIcons[name];

    return iconData ?? Icons.folder;
  }

  initAllMailAddress() async {
    data = await mailAddressService.findAllMailAddress();
    if (data.isNotEmpty) {
      for (var emailAddress in data) {
        String email = emailAddress.email;
        if (!_addressMailMessages.containsKey(email)) {
          Map<String, List<MailMessage>> addressMailMessages = {};
          _addressMailMessages[email] = addressMailMessages;
          for (var mailBoxeIcon in mailBoxeIcons.entries) {
            String name = mailBoxeIcon.key;
            if (!addressMailMessages.containsKey(name)) {
              addressMailMessages[name] = <MailMessage>[];
            }
          }
        }
      }

      connectAllMailAddress();
      currentIndex = 0;
    } else {
      currentIndex = -1;
    }
  }

  ///当前邮箱
  String? get currentMailboxName {
    return _currentMailboxName;
  }

  List<String>? getMailboxNames(String email) {
    Map<String, List<MailMessage>>? mailMessageMap =
        _addressMailMessages[email];
    if (mailMessageMap != null && mailMessageMap.isNotEmpty) {
      return mailMessageMap.keys.toList();
    }
    return null;
  }

  ///当前邮件位置
  int get currentMailIndex {
    return _currentMailIndex;
  }

  ///设置当前邮件位置
  set currentMailIndex(int currentMailIndex) {
    if (_currentMailIndex != currentMailIndex) {
      _currentMailIndex = currentMailIndex;
      notifyListeners();
    }
  }

  ///获取当前地址的当前邮箱的邮件
  List<MailMessage>? get currentMailMessages {
    if (current == null) {
      return null;
    }
    var email = current!.email;
    Map<String, List<MailMessage>>? mailboxMailMessages =
        _addressMailMessages[email];
    if (mailboxMailMessages == null) {
      return null;
    }
    List<MailMessage>? mailMessages = mailboxMailMessages[_currentMailboxName];

    return mailMessages;
  }

  MailMessage? get currentMailMessage {
    var currentMailMessages = this.currentMailMessages;
    if (currentMailMessages != null &&
        _currentMailIndex >= 0 &&
        _currentMailIndex < currentMailMessages.length) {
      return currentMailMessages[_currentMailIndex];
    }

    return null;
  }

  set currentMailMessage(MailMessage? mailMessage) {
    var currentMailMessages = this.currentMailMessages;
    if (currentMailMessages != null &&
        _currentMailIndex >= 0 &&
        _currentMailIndex < currentMailMessages.length) {
      currentMailMessages[_currentMailIndex] = mailMessage!;
    }
  }

  ///以下是从数据库取邮件的部分

  findCurrent() async {
    if (current == null) {
      return false;
    }
    String? currentMailboxName = this.currentMailboxName;
    if (currentMailboxName == null) {
      return false;
    }
    int? uid = currentMailMessage?.uid;
    if (uid != null) {
      MailMessage? mailMessage =
          await mailMessageService.findOne(where: 'uid=?', whereArgs: [uid]);
      if (mailMessage != null) {
        currentMailMessage = mailMessage;
      }
    }
  }

  Future<bool> findLatestMailMessages() async {
    return await lock.synchronized(() async {
      return await _findLatestMailMessages();
    });
  }

  Future<bool> _findLatestMailMessages() async {
    if (current == null) {
      return false;
    }
    String? currentMailboxName = this.currentMailboxName;
    if (currentMailboxName == null) {
      return false;
    }

    var currentMailMessages = this.currentMailMessages;
    List<MailMessage> emailMessages;
    if (currentMailMessages == null || currentMailMessages.isEmpty) {
      emailMessages = await mailMessageService.findLatestMessages(
          current!.email, currentMailboxName);
    } else {
      String? sendTime = currentMailMessages.first.sendTime;
      emailMessages = await mailMessageService.findLatestMessages(
          current!.email, currentMailboxName,
          sendTime: sendTime);
    }
    if (emailMessages.isNotEmpty) {
      currentMailMessages?.insertAll(0, emailMessages);
      notifyListeners();
      return true;
    }

    return false;
  }

  MimeMessage? convert(MailMessage emailMessage) {
    MimeMessage? mimeMessage;
    if (emailMessage.status == FetchPreference.envelope.name) {
      Envelope envelope = Envelope(
        date: DateUtil.toDateTime(emailMessage.sendTime!),
        subject: emailMessage.subject,
        from: emailMessage.senders,
        sender: emailMessage.sender,
        replyTo: emailMessage.replyTo,
        to: emailMessage.receivers,
        cc: emailMessage.cc,
        bcc: emailMessage.bcc,
        inReplyTo: emailMessage.inReplyTo,
        messageId: emailMessage.messageId,
      );
      mimeMessage = MimeMessage.fromEnvelope(envelope,
          uid: emailMessage.uid,
          guid: emailMessage.guid,
          sequenceId: emailMessage.sequenceId,
          flags: emailMessage.flags);
    } else {
      String? content = emailMessage.content;
      if (content != null) {
        mimeMessage = MimeMessage.parseFromText(content);
        mimeMessage.sender = emailMessage.sender;
      }
    }

    return mimeMessage;
  }

  Future<bool> findMailMessages() async {
    return await lock.synchronized(() async {
      return await _findMailMessages();
    });
  }

  Future<bool> _findMailMessages() async {
    if (current == null) {
      return false;
    }
    String? currentMailboxName = this.currentMailboxName;
    if (currentMailboxName == null) {
      return false;
    }

    var currentMailMessages = this.currentMailMessages;
    List<MailMessage> emailMessages;
    if (currentMailMessages == null || currentMailMessages.isEmpty) {
      emailMessages = await mailMessageService.findMessages(
          current!.email, currentMailboxName);
    } else {
      String? sendTime = currentMailMessages.last.sendTime;
      emailMessages = await mailMessageService
          .findMessages(current!.email, currentMailboxName, sendTime: sendTime);
    }
    if (emailMessages.isNotEmpty) {
      currentMailMessages?.insertAll(0, emailMessages);
      notifyListeners();

      return true;
    } else {
      int page = getPage(currentMailMessages?.length ?? 0);
      await _fetchMessages(page: page);
    }

    return false;
  }

  int getPage(int offset) {
    int mod = offset % 20;
    int page = offset ~/ 20;
    if (mod == 0) {
      page++;
    } else {
      page += 2;
    }

    return page;
  }

  ///以下是与邮件服务器相关的部分

  ///以下是与邮件地址相关的部分
  ///重新获取所有的邮件地址实体，对没有连接的进行连接，设置缺省邮件地址
  connectAllMailAddress() async {
    if (data.isNotEmpty) {
      for (var emailAddress in data) {
        bool isConnected = await _connectMailAddress(emailAddress);
        if (isConnected) {
          if (emailAddress.isDefault) {
            defaultMailAddress = emailAddress;
          }
        }
      }
    }
  }

  ///连接特定的邮件地址服务器，获取地址的所有的邮箱
  Future<bool> _connectMailAddress(entity.MailAddress emailAddress,
      {bool listen = true}) async {
    var password = emailAddress.password;
    if (password != null) {
      EmailClient? emailClient =
          await emailClientPool.create(emailAddress, password);
      if (emailClient != null) {
        List<enough_mail.Mailbox>? mailboxes =
            await emailClient.listMailboxes();
        if (mailboxes != null) {
          emailClient.startPolling(_onMessage);
          _setMailboxes(emailAddress.email, mailboxes, listen: listen);
          await fetchMessages();
          Timer.periodic(const Duration(minutes: 2), (timer) {
            fetchMessages();
          });

          return true;
        }
      }
    } else {
      logger.e('email address:${emailAddress.email} password is empty');
    }
    return false;
  }

  enough_mail.Mailbox? get currentMailbox {
    return _currentMailbox;
  }

  ///设置当前邮箱名称
  setCurrentMailbox(String? name) {
    if (current == null) {
      return;
    }
    if (_currentMailboxName != name) {
      _currentMailboxName = name;
      Map<String, enough_mail.Mailbox>? mailboxMap =
          _addressMailboxes[current!.email];
      if (mailboxMap != null && mailboxMap.isNotEmpty) {
        if (_currentMailbox?.name != name) {
          _currentMailbox = mailboxMap[name];
        }
      }

      notifyListeners();
    }
  }

  _onMessage(MimeMessage mimeMessage) {
    logger.i('Received mimeMessage:${mimeMessage.decodeSubject() ?? ''}');
  }

  ///获取邮件地址的邮箱
  List<enough_mail.Mailbox>? getMailboxes(String email) {
    Map<String, enough_mail.Mailbox>? mailboxMap = _addressMailboxes[email];
    if (mailboxMap != null && mailboxMap.isNotEmpty) {
      return mailboxMap.values.toList();
    }
    return null;
  }

  ///设置邮件地址的邮箱
  _setMailboxes(String email, List<enough_mail.Mailbox?> mailboxes,
      {bool listen = true}) {
    Map<String, List<MailMessage>>? addressMailMessages =
        _addressMailMessages[email];
    if (addressMailMessages == null) {
      return;
    }
    Map<String, enough_mail.Mailbox>? mailboxMap = _addressMailboxes[email];
    if (mailboxMap == null) {
      mailboxMap = {};
      _addressMailboxes[email] = mailboxMap;
    }
    if (mailboxes.isNotEmpty) {
      for (var mailbox in mailboxes) {
        if (mailbox != null) {
          mailboxMap[mailbox.name] = mailbox;
          if (!addressMailMessages.containsKey(mailbox.name)) {
            addressMailMessages[mailbox.name] = <MailMessage>[];
          }
        }
      }
      _currentMailboxName = mailboxes.first?.name;
      _currentMailbox = mailboxes.first;
    } else {
      _currentMailboxName = null;
      _currentMailbox = null;
    }
    if (listen) {
      notifyListeners();
    }
  }

  EmailClient? get currentEmailClient {
    if (current == null) {
      return null;
    }
    String email = current!.email;

    EmailClient? emailClient = emailClientPool.get(email);
    if (emailClient == null) {
      _connectMailAddress(current!);
    }

    return emailClient;
  }

  ///从邮件服务器中取当前地址当前邮箱的所有未取的最新邮件数据，放入数据提供者的数组中
  Future<void> fetchMessages({
    int count = 30,
    int page = 1,
    FetchPreference fetchPreference = FetchPreference.envelope,
  }) async {
    return await lock.synchronized(() async {
      return await _fetchMessages(
        count: count,
        page: page,
        fetchPreference: fetchPreference,
      );
    });
  }

  Future<void> _fetchMessages({
    int count = 30,
    int page = 1,
    FetchPreference fetchPreference = FetchPreference.envelope,
  }) async {
    EmailClient? emailClient = currentEmailClient;
    if (emailClient == null) {
      return;
    }
    Mailbox? currentMailbox = this.currentMailbox;
    if (currentMailbox == null) {
      return;
    }
    bool notify = false;
    bool isMore = true;
    while (isMore) {
      try {
        List<enough_mail.MimeMessage>? mimeMessages =
            await emailClient.fetchMessages(
                mailbox: currentMailbox,
                count: count,
                page: page,
                fetchPreference: fetchPreference);
        if (mimeMessages != null && mimeMessages.isNotEmpty) {
          for (int i = mimeMessages.length - 1; i >= 0; i--) {
            var mimeMessage = mimeMessages[i];
            bool success = await mailMessageService.storeMimeMessage(
                currentMailbox, mimeMessage, fetchPreference);
            if (success) {
              notify = true;
            } else {
              isMore = false;
              break;
            }
          }
          if (mimeMessages.length < count) {
            isMore = false;
          }
        }
      } catch (e) {
        isMore = false;
        break;
      }
    }
    if (notify) {
      notifyListeners();
    }
  }

  ///从邮件服务器中取当前地址当前邮箱的比指定消息更旧的消息，放入数据提供者的数组中
  Future<void> fetchMessagesNextPage(
    enough_mail.MimeMessage mimeMessage, {
    FetchPreference fetchPreference = FetchPreference.envelope,
  }) async {
    return await lock.synchronized(() async {
      return await _fetchMessagesNextPage(
        mimeMessage,
        fetchPreference: fetchPreference,
      );
    });
  }

  Future<void> _fetchMessagesNextPage(
    enough_mail.MimeMessage mimeMessage, {
    FetchPreference fetchPreference = FetchPreference.envelope,
  }) async {
    EmailClient? emailClient = currentEmailClient;
    if (emailClient == null) {
      return;
    }
    Mailbox? currentMailbox = this.currentMailbox;
    if (currentMailbox == null) {
      return;
    }
    List<enough_mail.MimeMessage>? mimeMessages =
        await emailClient.fetchMessagesNextPage(mimeMessage,
            mailbox: currentMailbox, fetchPreference: fetchPreference);
    if (mimeMessages != null && mimeMessages.isNotEmpty) {
      for (var mimeMessage in mimeMessages) {
        bool success = await mailMessageService.storeMimeMessage(
            currentMailbox, mimeMessage, fetchPreference);
        if (!success) {
          break;
        }
      }
    }
  }

  ///当前邮件获取全部内容，包括附件
  Future<enough_mail.MimeMessage?> fetchMessageContents(
      enough_mail.MimeMessage mimeMessage) async {
    EmailClient? emailClient = currentEmailClient;
    if (emailClient == null) {
      return null;
    }

    MimeMessage? mimeMessageContent = mimeMessage.decodeContentMessage();
    if (mimeMessageContent == null) {
      enough_mail.MimeMessage? mimeMsg =
          await emailClient.fetchMessageContents(mimeMessage);
      if (mimeMsg != null) {
        await mailMessageService.storeMimeMessage(
            _currentMailbox!, mimeMsg, FetchPreference.full);

        return mimeMsg;
      }
    }

    return mimeMessage;
  }

  ///当前邮件根据fetchId获取附件
  Future<MimePart?> fetchMessagePart(
    String fetchId, {
    Duration? responseTimeout,
  }) async {
    EmailClient? emailClient = currentEmailClient;
    if (emailClient == null) {
      return null;
    }

    if (currentMailMessage != null) {
      enough_mail.MimeMessage? mimeMessage = convert(currentMailMessage!);
      if (mimeMessage != null) {
        return await emailClient.fetchMessagePart(mimeMessage, fetchId,
            responseTimeout: responseTimeout);
      }
    }
    return null;
  }

  ///解密标题和文本
  Future<DecryptedMimeMessage> decryptMimeMessage(
      MimeMessage mimeMessage) async {
    String? subjects = mimeMessage.decodeSubject();
    String? text = mimeMessage.decodeTextPlainPart();
    MailAddress? sender = mimeMessage.sender;
    sender ??= mimeMessage.from?.firstOrNull;
    String? sendTime = mimeMessage.decodeDate()?.toIso8601String();
    DecryptedMimeMessage decryptedData =
        DecryptedMimeMessage(sender: sender, sendTime: sendTime);
    String? keys;
    String? subject = subjects;
    if (subjects != null) {
      int pos = subjects.indexOf('#{');
      if (pos > -1 && subjects.endsWith('}')) {
        //加密
        decryptedData.needDecrypt = true;
        subject = subjects.substring(0, pos);
        keys = subjects.substring(pos + 2, subjects.length - 1);
        subject = subject.replaceAll(' ', '');
        subject = subject.replaceAll('\r\n', '');
      }
    }
    if (decryptedData.needDecrypt) {
      if (keys != null && keys.isNotEmpty) {
        Map<String, dynamic> payloadKeys = JsonUtil.toJson(keys);
        if (payloadKeys.isEmpty) {
          //linkman加密
          decryptedData.payloadKey = null;
        } else {
          if (payloadKeys.containsKey(myself.peerId)) {
            //group加密
            var payloadKey = payloadKeys[myself.peerId]!;
            payloadKey = payloadKey.replaceAll(' ', '');
            payloadKey = payloadKey.replaceAll('\r\n', '');
            decryptedData.payloadKey = payloadKey;
          } else {
            logger.e('No myself payload key');
            decryptedData.payloadKey = null;
            decryptedData.subject = AppLocalizations.t('No myself payload key');
            decryptedData.html = AppLocalizations.t('No myself payload key');

            return decryptedData;
          }
        }
      } else {
        /// 如果没有key，则是自己发送给自己
        logger.e('needEncrypt but no keys');
        decryptedData.payloadKey = null;
      }

      List<int>? data;
      decryptedData.subject = subject;
      if (subject != null) {
        try {
          data = CryptoUtil.decodeBase64(subject);
          data = await mailAddressService.decrypt(data,
              payloadKey: decryptedData.payloadKey);
          decryptedData.subject = CryptoUtil.utf8ToString(data!);
        } catch (e) {
          logger.e('subject decrypt failure:$e');
        }
      }
      decryptedData.html = null;
      if (text != null) {
        try {
          text = text.replaceAll(' ', '');
          text = text.replaceAll('\r\n', '');
          data = CryptoUtil.decodeBase64(text);
          data = await mailAddressService.decrypt(data,
              payloadKey: decryptedData.payloadKey);
          text = CryptoUtil.utf8ToString(data!);
          decryptedData.html = EmailMessageUtil.convertToMimeMessageHtml(text);
        } catch (e) {
          logger.e('text decrypt failure:$e');
        }
      }
    } else {
      //不加密
      decryptedData.subject = subject;
      decryptedData.html = EmailMessageUtil.convertToHtml(mimeMessage);
    }

    return decryptedData;
  }
}

final MailMimeMessageController mailMimeMessageController =
    MailMimeMessageController();
