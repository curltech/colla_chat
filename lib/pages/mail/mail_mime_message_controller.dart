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
import 'package:get/get.dart';
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

class MailAddressController extends DataListController<entity.MailAddress> {
  ///缺省的邮件地址
  Rx<entity.MailAddress?> defaultMailAddress = Rx<entity.MailAddress?>(null);

  MailAddressController() {
    _initAllMailAddress();
  }

  _initAllMailAddress() async {
    data.assignAll(await mailAddressService.findAllMailAddress());
    if (data.isNotEmpty) {
      mailboxController.currentMailboxName = mailboxController.init();
      for (var emailAddress in data) {
        String email = emailAddress.email;
        mailMimeMessageController.init(email);
      }
      setCurrentIndex = 0;
      connectAllMailAddress();
      mailMimeMessageController.findMailMessages();
    } else {
      setCurrentIndex = null;
    }
  }

  connectAllMailAddress() async {
    if (data.isNotEmpty) {
      for (var emailAddress in data) {
        EmailClient? emailClient = await connectMailAddress(emailAddress);
        if (emailClient != null) {
          if (emailAddress.isDefault) {
            defaultMailAddress(emailAddress);
          }
        }
      }
    }
  }

  Future<EmailClient?> connectMailAddress(
      entity.MailAddress emailAddress) async {
    var password = emailAddress.password;
    if (password != null) {
      EmailClient? emailClient =
          await emailClientPool.create(emailAddress, password);
      if (emailClient != null) {
        List<enough_mail.Mailbox>? mailboxes =
            await emailClient.listMailboxes();
        if (mailboxes != null) {
          emailClient.startPolling(mailMimeMessageController._onMessage);
          mailboxController.setMailboxes(emailAddress.email, mailboxes);
          await mailMimeMessageController.fetchMessages();
          Timer.periodic(const Duration(minutes: 2), (timer) {
            mailMimeMessageController.fetchMessages();
          });

          return emailClient;
        }
      }
    } else {
      logger.e('email address:${emailAddress.email} password is empty');
    }
    return null;
  }
}

final MailAddressController mailAddressController = MailAddressController();

class MailboxController {
  ///邮件地址，邮箱名称和邮箱的映射
  final RxMap<String, Map<String, enough_mail.Mailbox>> _addressMailboxes =
      RxMap<String, Map<String, enough_mail.Mailbox>>({});
  final Rx<String?> _currentMailboxName = Rx<String?>(null);

  ///当前的邮箱名称,
  final Rx<enough_mail.Mailbox?> _currentMailbox =
      Rx<enough_mail.Mailbox?>(null);

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

  final Map<String, IconData> _mailBoxIcons = {};

  MailboxController() {
    for (var mailBoxeIcon in mailBoxeIcons.entries) {
      String name = mailBoxeIcon.key;
      String localeName = AppLocalizations.t(name);
      _mailBoxIcons[name] = mailBoxeIcon.value;
      _mailBoxIcons[localeName] = mailBoxeIcon.value;
    }
  }

  init() {
    currentMailboxName = _mailBoxIcons.keys.firstOrNull;
  }

  ///创建邮件地址的目录的图标
  IconData? findDirectoryIcon(String name) {
    IconData? iconData = _mailBoxIcons[name];

    return iconData ?? Icons.folder;
  }

  List<String>? getMailboxNames(String email) {
    Map<String, enough_mail.Mailbox>? mailboxMap = _addressMailboxes[email];
    if (mailboxMap != null && mailboxMap.isNotEmpty) {
      return mailboxMap.keys.toList();
    }
    if (_currentMailboxName.value != null) {
      return [_currentMailboxName.value!];
    }
    return null;
  }

  String? get currentMailboxName {
    return _currentMailboxName.value;
  }

  set currentMailboxName(String? currentMailboxName) {
    _currentMailboxName(currentMailboxName);
  }

  enough_mail.Mailbox? get currentMailbox {
    return _currentMailbox.value;
  }

  ///设置当前邮箱名称
  setCurrentMailbox(String? name) {
    if (mailAddressController.current == null) {
      return;
    }
    _currentMailboxName(name);
    Map<String, enough_mail.Mailbox>? mailboxMap =
        _addressMailboxes[mailAddressController.current!.email];
    if (mailboxMap != null && mailboxMap.isNotEmpty) {
      _currentMailbox(mailboxMap[name]);
    }
    //修改邮箱，抓取数据
    mailMimeMessageController.findMailMessages();
  }

  ///获取邮件地址的邮箱
  List<enough_mail.Mailbox>? getMailboxes(String email) {
    Map<String, enough_mail.Mailbox>? mailboxMap = _addressMailboxes[email];
    if (mailboxMap != null && mailboxMap.isNotEmpty) {
      return mailboxMap.values.toList();
    }
    return null;
  }

  enough_mail.Mailbox? getMailbox(String email, String mailboxName) {
    Map<String, enough_mail.Mailbox>? mailboxMap = _addressMailboxes[email];
    if (mailboxMap != null && mailboxMap.isNotEmpty) {
      return mailboxMap[mailboxName];
    }
    return null;
  }

  ///设置邮件地址的邮箱
  setMailboxes(String email, List<enough_mail.Mailbox?> mailboxes) {
    Map<String, List<MailMessage>>? addressMailMessages =
        mailMimeMessageController._addressMailMessages[email];
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
      _currentMailboxName(mailboxes.first?.name);
      _currentMailbox(mailboxes.first);
    } else {
      _currentMailboxName(null);
      _currentMailbox(null);
    }
  }
}

final MailboxController mailboxController = MailboxController();

/// 邮件地址控制器，每个地址有多个邮箱，每个邮箱包含多个邮件
class MailMimeMessageController {
  Lock lock = Lock();

  ///邮件地址，邮箱名称和邮件列表的映射
  final RxMap<String, Map<String, List<MailMessage>>> _addressMailMessages =
      RxMap<String, Map<String, List<MailMessage>>>({});

  ///当前的邮件
  final Rx<int?> currentMailIndex = Rx<int?>(null);

  ///构造函数从数据库获取所有的邮件地址，初始化邮箱数据
  MailMimeMessageController();

  init(String email) {
    var currentMailboxName = mailboxController.currentMailboxName;
    if (!_addressMailMessages.containsKey(email) &&
        currentMailboxName != null) {
      Map<String, List<MailMessage>> addressMailMessages = {
        currentMailboxName: []
      };
      mailMimeMessageController._addressMailMessages[email] =
          addressMailMessages;
    }
  }

  ///获取当前地址的当前邮箱的邮件
  List<MailMessage>? get currentMailMessages {
    var current = mailAddressController.current;
    if (current == null) {
      return null;
    }
    var email = current.email;
    Map<String, List<MailMessage>>? mailboxMailMessages =
        _addressMailMessages[email];
    if (mailboxMailMessages == null) {
      return null;
    }
    List<MailMessage>? mailMessages =
        mailboxMailMessages[mailboxController._currentMailboxName.value];

    return mailMessages;
  }

  MailMessage? get currentMailMessage {
    var currentMailIndex = this.currentMailIndex.value;
    var currentMailMessages = this.currentMailMessages;
    if (currentMailMessages != null &&
        currentMailIndex != null &&
        currentMailIndex >= 0 &&
        currentMailIndex < currentMailMessages.length) {
      return currentMailMessages[currentMailIndex];
    }

    return null;
  }

  set currentMailMessage(MailMessage? mailMessage) {
    var currentMailIndex = this.currentMailIndex.value;
    var currentMailMessages = this.currentMailMessages;
    if (currentMailMessages != null &&
        currentMailIndex != null &&
        currentMailIndex >= 0 &&
        currentMailIndex < currentMailMessages.length) {
      currentMailMessages[currentMailIndex] = mailMessage!;
    }
  }

  findCurrent() async {
    var current = mailAddressController.current;
    if (current == null) {
      return false;
    }
    String? currentMailboxName = mailboxController._currentMailboxName.value;
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

  /// 取本地存储中更新的邮件
  Future<bool> findLatestMailMessages() async {
    return await lock.synchronized(() async {
      return await _findLatestMailMessages();
    });
  }

  Future<bool> _findLatestMailMessages() async {
    var current = mailAddressController.current;
    if (current == null) {
      return false;
    }
    String? currentMailboxName = mailboxController._currentMailboxName.value;
    if (currentMailboxName == null) {
      return false;
    }

    var currentMailMessages = this.currentMailMessages;
    List<MailMessage> emailMessages;
    if (currentMailMessages == null || currentMailMessages.isEmpty) {
      emailMessages = await mailMessageService.findLatestMessages(
          current.email, currentMailboxName);
    } else {
      String? sendTime = currentMailMessages.first.sendTime;
      emailMessages = await mailMessageService.findLatestMessages(
          current.email, currentMailboxName,
          sendTime: sendTime);
    }
    if (emailMessages.isNotEmpty) {
      currentMailMessages?.insertAll(0, emailMessages);
      return true;
    }

    return false;
  }

  Future<enough_mail.MimeMessage?> convert(MailMessage emailMessage) async {
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
      try {
        mimeMessage = MimeMessage.fromEnvelope(envelope,
            uid: emailMessage.uid,
            guid: emailMessage.guid,
            sequenceId: emailMessage.sequenceId,
            flags: emailMessage.flags);
      } catch (e) {
        logger.e('fromEnvelope mimeMessage failure:$e');
      }
    } else {
      String? content = emailMessage.content;
      if (content != null) {
        try {
          mimeMessage = MimeMessage.parseFromText(content);
          mimeMessage.sender = emailMessage.decodeSender();
        } catch (e) {
          logger.e('parseFromText mimeMessage failure:$e');
          int uid = emailMessage.uid;
          List<MimeMessage>? mimeMessages = await fetchMessageSequence([uid]);
          if (mimeMessages != null && mimeMessages.isNotEmpty) {
            mimeMessage = mimeMessages[0];
          }
        }
      }
    }

    return mimeMessage;
  }

  /// 取本地存储中更旧的邮件
  Future<bool> findMailMessages() async {
    return await lock.synchronized(() async {
      return await _findMailMessages();
    });
  }

  Future<bool> _findMailMessages() async {
    var current = mailAddressController.current;
    if (current == null) {
      return false;
    }
    String? currentMailboxName = mailboxController.currentMailboxName;
    if (currentMailboxName == null) {
      return false;
    }

    var currentMailMessages = this.currentMailMessages;
    List<MailMessage> emailMessages;
    if (currentMailMessages == null || currentMailMessages.isEmpty) {
      emailMessages = await mailMessageService.findMessages(
          current.email, currentMailboxName);
    } else {
      String? sendTime = currentMailMessages.last.sendTime;
      emailMessages = await mailMessageService
          .findMessages(current.email, currentMailboxName, sendTime: sendTime);
    }
    if (emailMessages.isNotEmpty) {
      currentMailMessages?.addAll(emailMessages);

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

  _onMessage(MimeMessage mimeMessage) {
    logger.i('Received mimeMessage:${mimeMessage.decodeSubject() ?? ''}');
  }

  Future<EmailClient?> get currentEmailClient async {
    var current = mailAddressController.current;
    if (current == null) {
      return null;
    }
    String email = current.email;
    EmailClient? emailClient = emailClientPool.get(email);
    emailClient ??= await mailAddressController.connectMailAddress(current);

    return emailClient;
  }

  /// 从邮件服务器中取当前地址当前邮箱的所有未取的最新邮件数据，放入数据提供者的数组中
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
    var current = mailAddressController.current;
    if (current == null) {
      return;
    }
    EmailClient? emailClient = await currentEmailClient;
    if (emailClient == null) {
      return;
    }
    Mailbox? currentMailbox = mailboxController.currentMailbox;
    if (currentMailbox == null) {
      return;
    }
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
          mimeMessages.sort((a, b) {
            DateTime? aDate = a.decodeDate();
            DateTime? bDate = b.decodeDate();
            if (aDate == null) {
              return -1;
            }
            if (bDate == null) {
              return 1;
            }
            if (aDate.isAfter(bDate)) {
              return 1;
            }
            return -1;
          });
          for (int i = mimeMessages.length - 1; i >= 0; i--) {
            var mimeMessage = mimeMessages[i];
            bool success = await mailMessageService.storeMimeMessage(
                current.email, currentMailbox, mimeMessage, fetchPreference);
            if (!success) {
              isMore = false;
              break;
            }
          }
          if (mimeMessages.length < count) {
            isMore = false;
          }
        } else {
          isMore = false;
        }
      } catch (e) {
        isMore = false;
        break;
      }
    }
  }

  Future<List<MimeMessage>?> fetchMessageSequence(
    List<int> ids, {
    Mailbox? mailbox,
    FetchPreference fetchPreference = FetchPreference.full,
    bool markAsSeen = false,
  }) async {
    EmailClient? emailClient = await currentEmailClient;
    if (emailClient == null) {
      return null;
    }
    MessageSequence sequence = MessageSequence.fromIds(ids, isUid: true);
    List<enough_mail.MimeMessage>? mimeMessages =
        await emailClient.fetchMessageSequence(sequence,
            mailbox: mailboxController.currentMailbox,
            fetchPreference: fetchPreference,
            markAsSeen: markAsSeen);

    return mimeMessages;
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
    var current = mailAddressController.current;
    if (current != null) {
      return;
    }
    EmailClient? emailClient = await currentEmailClient;
    if (emailClient == null) {
      return;
    }
    Mailbox? currentMailbox = mailboxController.currentMailbox;
    if (currentMailbox == null) {
      return;
    }
    List<enough_mail.MimeMessage>? mimeMessages =
        await emailClient.fetchMessagesNextPage(mimeMessage,
            mailbox: currentMailbox, fetchPreference: fetchPreference);
    if (mimeMessages != null && mimeMessages.isNotEmpty) {
      for (var mimeMessage in mimeMessages) {
        bool success = await mailMessageService.storeMimeMessage(
            current!.email, currentMailbox, mimeMessage, fetchPreference);
        if (!success) {
          break;
        }
      }
    }
  }

  ///当前邮件获取全部内容，包括附件
  Future<enough_mail.MimeMessage?> fetchMessageContents(
      enough_mail.MimeMessage mimeMessage) async {
    EmailClient? emailClient = await currentEmailClient;
    if (emailClient == null) {
      return null;
    }
    var current = mailAddressController.current;
    if (current != null) {
      return null;
    }
    MimeMessage? mimeMessageContent = mimeMessage.decodeContentMessage();
    if (mimeMessageContent == null) {
      enough_mail.MimeMessage? mimeMsg =
          await emailClient.fetchMessageContents(mimeMessage);
      if (mimeMsg != null) {
        await mailMessageService.storeMimeMessage(current!.email,
            mailboxController.currentMailbox!, mimeMsg, FetchPreference.full);

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
    EmailClient? emailClient = await currentEmailClient;
    if (emailClient == null) {
      return null;
    }

    if (currentMailMessage != null) {
      enough_mail.MimeMessage? mimeMessage = await convert(currentMailMessage!);
      if (mimeMessage != null) {
        return await emailClient.fetchMessagePart(mimeMessage, fetchId,
            responseTimeout: responseTimeout);
      }
    }
    return null;
  }

  /// 解密标题和文本
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
        keys = keys.replaceAll(' ', '');
        keys = keys.replaceAll('\r\n', '');
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
        logger.e('needEncrypt but no keys, self send');
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

  deleteMessage(int index, {bool expunge = false}) async {
    EmailClient? emailClient = await currentEmailClient;
    if (emailClient == null) {
      return null;
    }
    List<MailMessage>? currentMailMessages = this.currentMailMessages;
    if (currentMailMessages != null && currentMailMessages.isNotEmpty) {
      if (index >= 0 && index < currentMailMessages.length) {
        MailMessage mailMessage = currentMailMessages[index];
        currentMailMessages.removeAt(index);
        int uid = mailMessage.uid;
        MessageSequence sequence = MessageSequence.fromIds([uid], isUid: true);
        mailMessageService.delete(where: 'id=?', whereArgs: [mailMessage.id!]);
        emailClient.deleteMessages(sequence, expunge: expunge);
      }
    }
  }

  flagMessage(
    int index, {
    bool? isSeen,
    bool? isFlagged,
    bool? isAnswered,
    bool? isForwarded,
    bool? isDeleted,
    bool? isReadReceiptSent,
  }) async {
    EmailClient? emailClient = await currentEmailClient;
    if (emailClient == null) {
      return null;
    }
    List<MailMessage>? currentMailMessages = this.currentMailMessages;
    if (currentMailMessages != null && currentMailMessages.isNotEmpty) {
      if (index >= 0 && index < currentMailMessages.length) {
        MailMessage mailMessage = currentMailMessages[index];
        MimeMessage? mimeMessage = await convert(mailMessage);
        if (mimeMessage != null) {
          await emailClient.flagMessage(mimeMessage,
              isSeen: isSeen,
              isFlagged: isFlagged,
              isAnswered: isAnswered,
              isForwarded: isForwarded,
              isDeleted: isDeleted,
              isReadReceiptSent: isReadReceiptSent);
          String flags = JsonUtil.toJsonString(mimeMessage.flags);
          mailMessage.flags = mimeMessage.flags;
          mailMessageService.update({'flags': flags},
              where: 'id=?', whereArgs: [mailMessage.id!]);
        }
      }
    }
  }

  Future<MoveResult?> junkMessage(int index) async {
    EmailClient? emailClient = await currentEmailClient;
    if (emailClient == null) {
      return null;
    }
    List<MailMessage>? currentMailMessages = this.currentMailMessages;
    if (currentMailMessages != null && currentMailMessages.isNotEmpty) {
      if (index >= 0 && index < currentMailMessages.length) {
        MailMessage mailMessage = currentMailMessages[index];
        MimeMessage? mimeMessage = await convert(mailMessage);
        if (mimeMessage != null) {
          MoveResult? moveResult = await emailClient.junkMessage(mimeMessage);
          if (moveResult != null) {
            mailMessageService.update(
                {'mailboxName': moveResult.targetMailbox?.name},
                where: 'id=?',
                whereArgs: [mailMessage.id!]);
          }
        }
      }
    }
    return null;
  }
}

final MailMimeMessageController mailMimeMessageController =
    MailMimeMessageController();
