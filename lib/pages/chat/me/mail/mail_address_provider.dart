import 'package:colla_chat/entity/chat/chat.dart';
import 'package:enough_mail/enough_mail.dart' as enough_mail;
import 'package:flutter/material.dart';

import '../../../../entity/chat/mailaddress.dart';
import '../../../../provider/app_data_provider.dart';
import '../../../../service/chat/chat.dart';
import '../../../../service/chat/mailaddress.dart';
import '../../../../transport/emailclient.dart';

/// 邮件地址的状态管理器
class MailAddressProvider with ChangeNotifier {
  final Map<String, MailAddress> _mailAddress = {};
  final Map<String, Map<String, enough_mail.Mailbox?>> _addressMailboxes = {};
  final Map<String, Map<String, List<ChatMessage>>> _addressMessages = {};
  MailAddress? _currentMailAddress;
  String? _currentMailboxName;
  int _currentIndex = 0;

  ///构造函数从数据库获取所有的邮件地址，初始化数据
  MailAddressProvider() {
    MailAddressService.instance
        .findAllMailAddress()
        .then((List<MailAddress> mailAddresses) {
      this.mailAddresses = mailAddresses;
      connect(mailAddresses);
    });
  }

  ///获取所有的邮件地址
  List<MailAddress> get mailAddresses {
    return _mailAddress.values.toList();
  }

  ///设置邮件地址
  set mailAddresses(List<MailAddress> mailAddresses) {
    bool needNotify = false;
    if (mailAddresses.isNotEmpty) {
      for (var mailAddress in mailAddresses) {
        _mailAddress[mailAddress.email] = mailAddress;
        _addressMessages[mailAddress.email] = {};
        if (mailAddress.isDefault) {
          _currentMailAddress = mailAddress;
        }
        needNotify = true;
      }
    }
    if (_currentMailAddress == null && _mailAddress.isNotEmpty) {
      _currentMailAddress = _mailAddress.values.first;
      needNotify = true;
    }
    if (needNotify) {
      notifyListeners();
    }
  }

  ///增加邮件地址
  add(List<MailAddress> mailAddresses) {
    bool needNotify = false;
    if (mailAddresses.isNotEmpty) {
      for (var mailAddress in mailAddresses) {
        if (!_addressMessages.containsKey(mailAddress)) {
          _mailAddress[mailAddress.email] = mailAddress;
          _addressMessages[mailAddress.email] = {};
          needNotify = true;
        }
      }
    }
    if (needNotify) {
      notifyListeners();
    }
  }

  connect(List<MailAddress> mailAddresses) async {
    bool needNotify = false;
    if (mailAddresses.isNotEmpty) {
      for (var mailAddress in mailAddresses) {
        EmailClient? emailClient =
            EmailClientPool.instance.get(mailAddress.email);
        if (emailClient == null) {
          var mailboxes = await connectMailAddress(mailAddress, listen: false);
          if (mailboxes.isNotEmpty) {
            Map<String, enough_mail.Mailbox> mailboxMap = {};
            for (var mailbox in mailboxes) {
              if (mailbox != null) {
                mailboxMap[mailbox.name] = mailbox;
              }
            }
            _addressMailboxes[mailAddress.email] = mailboxMap;
            needNotify = true;
          }
        }
      }
    }
    if (needNotify) {
      notifyListeners();
    }
    return addressMailBoxes;
  }

  Future<List<enough_mail.Mailbox?>> connectMailAddress(MailAddress mailAddress,
      {bool listen = true}) async {
    var password = mailAddress.password;
    if (password != null) {
      EmailClient? emailClient =
          await EmailClientPool.instance.create(mailAddress, password);
      if (emailClient != null) {
        List<enough_mail.Mailbox?>? mailboxes =
            await emailClient.listMailboxes();
        logger.i(mailboxes!);
        setMailboxes(mailAddress.email, mailboxes, listen: listen);

        return mailboxes;
        // enough_mail.Mailbox? mailbox = await emailClient.selectInbox();
        // logger.i(mailbox!);
        // List<enough_mail.MimeMessage>? mimeMessages =
        //     await emailClient.fetchMessages(mailbox: mailbox);
      }
    }
    setMailboxes(mailAddress.email, [], listen: listen);

    return [];
  }

  ///获取所有的邮件地址的邮箱
  Map<String, Map<String, enough_mail.Mailbox?>> get addressMailBoxes {
    return _addressMailboxes;
  }

  ///设置邮件地址邮箱
  set addressMailBoxes(
      Map<String, Map<String, enough_mail.Mailbox?>> addressMailBoxes) {
    bool needNotify = false;
    if (addressMailBoxes.isNotEmpty) {
      for (var entry in addressMailBoxes.entries) {
        var mailAddress = entry.key;
        var mailBoxes = entry.value;
        _addressMailboxes[mailAddress] = mailBoxes;
        needNotify = true;
      }
    }
    if (needNotify) {
      notifyListeners();
    }
  }

  ///获取邮件地址的邮箱
  List<enough_mail.Mailbox?>? getMailboxes(String email) {
    Map<String, enough_mail.Mailbox?>? mailboxMap = _addressMailboxes[email];
    if (mailboxMap != null && mailboxMap.isNotEmpty) {
      return mailboxMap.values.toList();
    }
    return null;
  }

  ///设置邮件地址邮箱
  setMailboxes(String email, List<enough_mail.Mailbox?> mailboxes,
      {bool listen = true}) {
    Map<String, enough_mail.Mailbox> mailboxMap = {};
    for (var mailbox in mailboxes) {
      if (mailbox != null) {
        mailboxMap[mailbox.name] = mailbox;
      }
    }
    _addressMailboxes[email] = mailboxMap;
    if (listen) {
      notifyListeners();
    }
  }

  ///当前的邮件地址
  MailAddress? get currentMailAddress {
    return _currentMailAddress;
  }

  ///设置当前邮件地址
  set currentMailAddress(MailAddress? mailAddress) {
    _currentMailAddress = mailAddress;
    notifyListeners();
  }

  ///当前的邮箱名称
  String? get currentMailboxName {
    return _currentMailboxName;
  }

  enough_mail.Mailbox? get currentMailbox {
    var currentMailAddress = _currentMailAddress;
    if (currentMailAddress == null) {
      return null;
    }
    String email = currentMailAddress.email;
    var mailboxes = _addressMailboxes[email];
    if (mailboxes != null && mailboxes.isNotEmpty) {
      enough_mail.Mailbox? mailbox = mailboxes[_currentMailboxName];
      return mailbox;
    }
    return null;
  }

  ///设置当前邮箱名称
  setCurrentMailboxName(String? currentMailboxName) async {
    _currentMailboxName = currentMailboxName;
    var currentMailAddress = _currentMailAddress;
    if (currentMailAddress == null) {
      return;
    }
    String email = currentMailAddress.email;
    EmailClient? emailClient = EmailClientPool.instance.get(email);
    if (emailClient != null) {
      enough_mail.Mailbox? currentMailbox = this.currentMailbox;
      if (currentMailbox != null) {
        List<enough_mail.MimeMessage>? mimeMessages =
            await emailClient.fetchMessages(mailbox: currentMailbox);
        if (mimeMessages != null && mimeMessages.isNotEmpty) {
          for (var mimeMessage in mimeMessages) {
            var chatMessage =
                EmailMessageUtil.convertToChatMessage(mimeMessage);
            var old = await ChatMessageService.instance.get(mimeMessage.guid!);
            if (old == null) {
              await ChatMessageService.instance.insert(chatMessage);
            }
            emailClient.deleteMessage(mimeMessage);
            var currentChatMessages = this.currentChatMessages;
            if (currentChatMessages != null) {
              currentChatMessages.add(chatMessage);
            }
          }
        }
      }
    }
    notifyListeners();
  }

  ///当前邮件位置
  int get currentIndex {
    return _currentIndex;
  }

  ///设置当前邮件位置
  set currentIndex(int currentIndex) {
    _currentIndex = currentIndex;
    notifyListeners();
  }

  ///获取当前地址的当前邮箱的邮件
  List<ChatMessage>? getMailboxChatMessages(String mailboxName) {
    Map<String, List<ChatMessage>>? mailboxChatMessages =
        _addressMessages[currentMailAddress];
    if (mailboxChatMessages != null && mailboxChatMessages.isNotEmpty) {
      List<ChatMessage>? chatMessages = mailboxChatMessages![mailboxName];
      return chatMessages;
    }
    return null;
  }

  ///获取当前地址的当前邮箱的邮件
  List<ChatMessage>? get currentChatMessages {
    Map<String, List<ChatMessage>>? mailboxChatMessages =
        _addressMessages[currentMailAddress];
    var currentMailboxName = _currentMailboxName;
    if (currentMailboxName != null &&
        mailboxChatMessages != null &&
        mailboxChatMessages.isNotEmpty) {
      List<ChatMessage>? chatMessages = mailboxChatMessages[currentMailboxName];
      if (chatMessages == null) {
        chatMessages = [];
        mailboxChatMessages[currentMailboxName] = chatMessages;
      }
      return chatMessages;
    }
    return null;
  }

  ///获取当前地址的当前邮箱的当前邮件
  ChatMessage? get currentChatMessage {
    List<ChatMessage>? chatMessages = currentChatMessages;
    if (chatMessages != null && chatMessages.isNotEmpty) {
      return chatMessages[_currentIndex];
    }
    return null;
  }
}

final mailAddressProvider = MailAddressProvider();
