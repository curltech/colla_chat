import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/mail/email_address.dart' as entity;
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/mail/email_address.dart';
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

  //解密后的html
  String? html;
  bool needDecrypt;

  DecryptedMimeMessage(
      {this.needDecrypt = false, this.payloadKey, this.subject, this.html});
}

/// 邮件地址控制器，每个地址有多个邮箱，每个邮箱包含多个邮件
class MailMimeMessageController
    extends DataListController<entity.EmailAddress> {
  Lock lock = Lock();

  ///缺省的邮件地址
  entity.EmailAddress? defaultMailAddress;

  ///邮件地址，邮箱名称和邮箱的映射
  final Map<String, Map<String, enough_mail.Mailbox>> _addressMailboxes = {};

  ///邮件地址，邮箱名称和邮件列表的映射
  final Map<String, Map<String, List<enough_mail.MimeMessage>>>
      _addressMimeMessages = {};

  ///当前的邮箱名称
  String? _currentMailboxName;

  ///当前的邮件
  int _currentMailIndex = -1;

  final Map<String, IconData> _mailBoxIcons = {};

  @override
  clear({bool? notify}) {
    _addressMailboxes.clear();
    _addressMimeMessages.clear();
    _currentMailboxName = null;
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

  ///以下是与邮件地址相关的部分
  ///重新获取所有的邮件地址实体，对没有连接的进行连接，设置缺省邮件地址
  connectAllMailAddress() async {
    data = await emailAddressService.findAllMailAddress();
    if (data.isNotEmpty) {
      for (var emailAddress in data) {
        String email = emailAddress.email;
        if (!_addressMimeMessages.containsKey(email)) {
          connectMailAddress(emailAddress).then((isConnected) {
            if (isConnected) {
              if (emailAddress.isDefault) {
                defaultMailAddress = emailAddress;
              }
            }
          });
        }
      }
    }
    if (data.isNotEmpty) {
      currentIndex = 0;
    } else {
      currentIndex = -1;
    }
  }

  ///以下是与邮件邮箱相关的部分

  ///当前邮箱名称
  String? get currentMailboxName {
    return _currentMailboxName;
  }

  ///设置当前邮箱名称
  set currentMailboxName(String? currentMailboxName) {
    if (_currentMailboxName != currentMailboxName) {
      _currentMailboxName = currentMailboxName;
      notifyListeners();
    }
  }

  ///连接特定的邮件地址服务器，获取地址的所有的邮箱
  Future<bool> connectMailAddress(entity.EmailAddress emailAddress,
      {bool listen = true}) async {
    var password = emailAddress.password;
    if (password != null) {
      EmailClient? emailClient =
          await emailClientPool.create(emailAddress, password);
      if (emailClient != null) {
        List<enough_mail.Mailbox>? mailboxes =
            await emailClient.listMailboxes();
        if (mailboxes != null) {
          _setMailboxes(emailAddress.email, mailboxes, listen: listen);

          return true;
        }
      }
    } else {
      logger.e('email address:${emailAddress.email} password is empty');
    }
    return false;
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
    Map<String, List<enough_mail.MimeMessage>>? addressMimeMessages =
        _addressMimeMessages[email];
    if (addressMimeMessages == null) {
      addressMimeMessages = {};
      _addressMimeMessages[email] = addressMimeMessages;
    }
    Map<String, enough_mail.Mailbox> mailboxMap = {};
    if (mailboxes.isNotEmpty) {
      for (var mailbox in mailboxes) {
        if (mailbox != null) {
          mailboxMap[mailbox.name] = mailbox;
          if (!addressMimeMessages.containsKey(mailbox.name)) {
            addressMimeMessages[mailbox.name] = <enough_mail.MimeMessage>[];
          }
        }
      }
      _currentMailboxName = mailboxes.first?.name;
    } else {
      _currentMailboxName = null;
    }
    _addressMailboxes[email] = mailboxMap;
    if (listen) {
      notifyListeners();
    }
  }

  ///当前地址的当前邮箱
  enough_mail.Mailbox? get currentMailbox {
    if (current == null) {
      return null;
    }
    String email = current!.email;
    var mailboxes = _addressMailboxes[email];
    if (mailboxes != null && mailboxes.isNotEmpty) {
      enough_mail.Mailbox? mailbox = mailboxes[currentMailboxName];

      return mailbox;
    }
    return null;
  }

  ///以下是与邮件的部分

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
  List<enough_mail.MimeMessage>? get currentMimeMessages {
    if (current == null) {
      return null;
    }
    var email = current!.email;
    Map<String, List<enough_mail.MimeMessage>>? mailboxMimeMessages =
        _addressMimeMessages[email];
    if (mailboxMimeMessages == null) {
      return null;
    }
    List<enough_mail.MimeMessage>? mimeMessages =
        mailboxMimeMessages[currentMailboxName];

    return mimeMessages;
  }

  MimeMessage? get currentMimeMessage {
    var currentMimeMessages = this.currentMimeMessages;
    if (currentMimeMessages != null &&
        _currentMailIndex >= 0 &&
        _currentMailIndex < currentMimeMessages.length) {
      return currentMimeMessages[_currentMailIndex];
    }

    return null;
  }

  set currentMimeMessage(MimeMessage? mimeMessage) {
    var currentMimeMessages = this.currentMimeMessages;
    if (currentMimeMessages != null &&
        _currentMailIndex >= 0 &&
        _currentMailIndex < currentMimeMessages.length) {
      currentMimeMessages[_currentMailIndex] = mimeMessage!;
    }
  }

  EmailClient? get currentEmailClient {
    if (current == null) {
      return null;
    }
    String email = current!.email;

    return emailClientPool.get(email);
  }

  ///以下是从数据库取邮件的部分

  ///从邮件服务器中取当前地址当前邮箱的下一页的邮件数据，放入数据提供者的数组中
  findMoreMimeMessages({
    FetchPreference fetchPreference = FetchPreference.envelope,
  }) async {
    return await lock.synchronized(() async {
      return await _findMoreMimeMessages(
        fetchPreference: fetchPreference,
      );
    });
  }

  _findMoreMimeMessages({
    FetchPreference fetchPreference = FetchPreference.envelope,
  }) async {
    EmailClient? emailClient = currentEmailClient;
    if (emailClient == null) {
      return;
    }
    enough_mail.Mailbox? currentMailbox = this.currentMailbox;
    if (currentMailbox == null) {
      return;
    }

    var currentMimeMessages = this.currentMimeMessages;
    List<enough_mail.MimeMessage>? mimeMessages;
    if (currentMimeMessages == null || currentMimeMessages.isEmpty) {
      mimeMessages = await emailClient.fetchMessages(
          mailbox: currentMailbox, fetchPreference: fetchPreference);
    } else {
      var offset = currentMimeMessages.length;
      int mod = offset % 20;
      int page = offset ~/ 20;
      if (mod == 0) {
        page++;
      } else {
        page += 2;
      }
      mimeMessages = await emailClient.fetchMessages(
          page: page,
          mailbox: currentMailbox,
          fetchPreference: fetchPreference);
    }
    if (mimeMessages != null && mimeMessages.isNotEmpty) {
      mimeMessages.sort((a, b) {
        DateTime? aDate = a.envelope?.date;
        DateTime? bDate = b.envelope?.date;
        if (aDate == null && bDate == null) {
          return 0;
        } else if (aDate != null && bDate != null) {
          return bDate.compareTo(aDate);
        } else if (aDate == null) {
          return 1;
        }
        return -1;
      });
      if (currentMimeMessages != null) {
        currentMimeMessages.addAll(mimeMessages);
        if (currentMailIndex != 0) {
          currentMailIndex = 0;
        } else {
          notifyListeners();
        }
      }
    }
  }

  ///当前邮件获取全部内容，包括附件
  Future<void> fetchMessageContents() async {
    EmailClient? emailClient = currentEmailClient;
    if (emailClient == null) {
      return;
    }

    enough_mail.MimeMessage? mimeMessage = currentMimeMessage;
    if (mimeMessage != null) {
      MimeMessage? mimeMessageContent = mimeMessage.decodeContentMessage();
      if (mimeMessageContent == null) {
        enough_mail.MimeMessage? mimeMsg =
            await emailClient.fetchMessageContents(mimeMessage);
        if (mimeMsg != null) {
          mimeMsg.envelope = mimeMessage.envelope;
          currentMimeMessage = mimeMsg;
          notifyListeners();
        }
      }
    }
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

    enough_mail.MimeMessage? mimeMessage = currentMimeMessage;
    if (mimeMessage != null) {
      return await emailClient.fetchMessagePart(mimeMessage, fetchId,
          responseTimeout: responseTimeout);
    }
    return null;
  }

  ///解密标题和文本
  Future<DecryptedMimeMessage> decryptMimeMessage(
      MimeMessage mimeMessage) async {
    String? subjects = mimeMessage.decodeSubject();
    String? text = mimeMessage.decodeTextPlainPart();
    DecryptedMimeMessage decryptedData = DecryptedMimeMessage();
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
          data = await emailAddressService.decrypt(data,
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
          data = await emailAddressService.decrypt(data,
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
