import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/chat/mailaddress.dart' as entity;
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/chat/mailaddress.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:enough_mail/enough_mail.dart' as enough_mail;
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';

/// 邮件地址控制器，每个地址有多个邮箱，每个邮箱包含多个邮件
class MailAddressController extends DataListController<entity.MailAddress> {
  ///缺省的邮件地址
  entity.MailAddress? defaultMailAddress;

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

  ///常用的邮箱名称
  static const Map<String, IconData> mailBoxeIcons = {
    'INBOX': Icons.inbox,
    'DRAFTS': Icons.drafts,
    'SENT': Icons.send,
    'TRASH': Icons.delete,
    'JUNK': Icons.garage,
    'MARK': Icons.flag,
    'BACKUP': Icons.backup,
    'ADS': Icons.ads_click,
    'VIRUS': Icons.coronavirus,
    'SUBSCRIPT': Icons.subscript,
  };

  ///构造函数从数据库获取所有的邮件地址，初始化邮箱数据
  MailAddressController() {
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
  refresh() async {
    data = await mailAddressService.findAllMailAddress();
    if (data.isNotEmpty) {
      for (var mailAddress in data) {
        String email = mailAddress.email;
        if (!_addressMimeMessages.containsKey(email)) {
          await connectMailAddress(mailAddress);
        }
        if (mailAddress.isDefault) {
          defaultMailAddress = mailAddress;
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
  connectMailAddress(entity.MailAddress mailAddress,
      {bool listen = true}) async {
    var password = mailAddress.password;
    if (password != null) {
      EmailClient? emailClient =
          await emailClientPool.create(mailAddress, password);
      if (emailClient != null) {
        List<enough_mail.Mailbox>? mailboxes =
            await emailClient.listMailboxes();
        if (mailboxes != null) {
          _setMailboxes(mailAddress.email, mailboxes, listen: listen);
          return;
        }
      }
    }
    _setMailboxes(mailAddress.email, [], listen: listen);
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
    if (currentMimeMessages != null && _currentMailIndex >= 0) {
      return currentMimeMessages[_currentMailIndex];
    }

    return null;
  }

  set currentMimeMessage(MimeMessage? mimeMessage) {
    var currentMimeMessages = this.currentMimeMessages;
    if (currentMimeMessages != null && _currentMailIndex >= 0) {
      currentMimeMessages[_currentMailIndex] = mimeMessage!;
    }
  }

  ///以下是从数据库取邮件的部分

  ///从邮件服务器中取当前地址当前邮箱的下一页的邮件数据，放入数据提供者的数组中
  findMoreMimeMessages({
    FetchPreference fetchPreference = FetchPreference.envelope,
  }) async {
    if (current == null) {
      return;
    }
    String email = current!.email;
    EmailClient? emailClient = emailClientPool.get(email);
    if (emailClient == null) {
      return;
    }
    enough_mail.Mailbox? currentMailbox = this.currentMailbox;
    if (currentMailbox == null) {
      return;
    }

    int offset = defaultOffset;
    var currentMimeMessages = this.currentMimeMessages;
    if (currentMimeMessages != null) {
      offset = currentMimeMessages.length;
      List<enough_mail.MimeMessage>? mimeMessages =
          await emailClient.fetchMessages(
              mailbox: currentMailbox,
              offset: offset,
              fetchPreference: fetchPreference);
      if (mimeMessages != null && mimeMessages.isNotEmpty) {
        currentMimeMessages.addAll(mimeMessages);
        currentMailIndex = currentMimeMessages.length - 1;
      }
    }
  }

  Future<void> updateMimeMessageContent() async {
    if (current == null) {
      return;
    }
    String email = current!.email;
    EmailClient? emailClient = emailClientPool.get(email);
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
        }
      }
    }
  }
}

final MailAddressController mailAddressController = MailAddressController();
