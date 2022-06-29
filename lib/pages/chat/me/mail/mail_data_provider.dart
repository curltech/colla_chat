import 'package:colla_chat/datastore/datastore.dart' as datastore;
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:enough_mail/enough_mail.dart' as enough_mail;
import 'package:flutter/material.dart';

import '../../../../entity/chat/mailaddress.dart';
import '../../../../provider/app_data_provider.dart';
import '../../../../service/chat/chat.dart';
import '../../../../service/chat/mailaddress.dart';
import '../../../../tool/util.dart';
import '../../../../transport/emailclient.dart';

/// 邮件数据的状态管理器，每个地址有多个邮箱，每个邮箱包含多个邮件
class MailDataProvider with ChangeNotifier {
  final Map<String, MailAddress> _mailAddress = {};
  final Map<String, Map<String, enough_mail.Mailbox?>> _addressMailboxes = {};
  final Map<String, Map<String, datastore.Page<ChatMessage>>>
      _addressChatMessagePages = {};
  final Map<String, Map<String, datastore.Page<enough_mail.MimeMessage>>>
      _addressMimeMessagePages = {};
  MailAddress? _currentMailAddress;
  String? _currentMailboxName;
  int _currentIndex = 0;

  ///构造函数从数据库获取所有的邮件地址，初始化邮箱数据
  MailDataProvider() {
    MailAddressService.instance
        .findAllMailAddress()
        .then((List<MailAddress> mailAddresses) {
      this.mailAddresses = mailAddresses;
      connect(mailAddresses);
    });
  }

  ///以下是与邮件地址相关的部分

  ///获取当前的邮件地址
  MailAddress? get currentMailAddress {
    return _currentMailAddress;
  }

  ///设置当前邮件地址
  set currentMailAddress(MailAddress? mailAddress) {
    _currentMailAddress = mailAddress;
    notifyListeners();
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
        _addressChatMessagePages[mailAddress.email] = {};
        _addressMimeMessagePages[mailAddress.email] = {};
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
  addMailAddress(List<MailAddress> mailAddresses) {
    bool needNotify = false;
    if (mailAddresses.isNotEmpty) {
      for (var mailAddress in mailAddresses) {
        if (!_addressChatMessagePages.containsKey(mailAddress)) {
          _mailAddress[mailAddress.email] = mailAddress;
          _addressChatMessagePages[mailAddress.email] = {};
          _addressMimeMessagePages[mailAddress.email] = {};
          needNotify = true;
        }
      }
    }
    if (needNotify) {
      notifyListeners();
    }
  }

  ///以下是与邮件邮箱相关的部分

  ///连接服务器，设置所有地址的邮箱
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

  ///连接邮件服务器，获取地址的所有的邮箱
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

  ///设置当前邮箱名称,从服务器获取新的邮件，将新邮件存入数据库，并放入邮件数组中
  setCurrentMailboxName(String? currentMailboxName) async {
    _currentMailboxName = currentMailboxName;
    var currentMailAddress = _currentMailAddress;
    if (currentMailAddress == null) {
      return;
    }
    if (currentMailboxName == null) {
      return;
    }
    var currentMailbox = this.currentMailbox;
    if (currentMailbox == null) {
      return;
    }
    loadMimeMessages();
    notifyListeners();
  }

  ///以下是与邮件的部分

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
  datastore.Page<ChatMessage>? getMailboxChatMessages(String mailboxName) {
    Map<String, datastore.Page<ChatMessage>>? mailboxChatMessages =
        _addressChatMessagePages[currentMailAddress];
    if (mailboxChatMessages != null && mailboxChatMessages.isNotEmpty) {
      datastore.Page<ChatMessage>? chatMessages =
          mailboxChatMessages[mailboxName];
      return chatMessages;
    }
    return null;
  }

  ///获取当前地址的当前邮箱的邮件
  datastore.Page<ChatMessage>? get currentChatMessagePage {
    Map<String, datastore.Page<ChatMessage>>? mailboxChatMessages =
        _addressChatMessagePages[currentMailAddress];
    var currentMailboxName = _currentMailboxName;
    if (currentMailboxName != null &&
        mailboxChatMessages != null &&
        mailboxChatMessages.isNotEmpty) {
      datastore.Page<ChatMessage>? chatMessagePage =
          mailboxChatMessages[currentMailboxName];
      if (chatMessagePage == null) {
        chatMessagePage = datastore.Page(total: 0, data: []);
        mailboxChatMessages[currentMailboxName] = chatMessagePage;
      }
      return chatMessagePage;
    }
    return null;
  }

  ///获取当前地址的当前邮箱的邮件
  datastore.Page<enough_mail.MimeMessage>? get currentMineMessagePage {
    Map<String, datastore.Page<enough_mail.MimeMessage>>? mailboxMimeMessages =
        _addressMimeMessagePages[currentMailAddress];
    var currentMailboxName = _currentMailboxName;
    if (currentMailboxName != null &&
        mailboxMimeMessages != null &&
        mailboxMimeMessages.isNotEmpty) {
      datastore.Page<enough_mail.MimeMessage>? mimeMessagePage =
          mailboxMimeMessages[currentMailboxName];
      if (mimeMessagePage == null) {
        mimeMessagePage = datastore.Page(total: 0, data: []);
        mailboxMimeMessages[currentMailboxName] = mimeMessagePage;
      }
      return mimeMessagePage;
    }
    return null;
  }

  ///获取当前地址的当前邮箱的当前邮件
  ChatMessage? get currentChatMessage {
    var currentChatMessagePage = this.currentChatMessagePage;
    if (currentChatMessagePage != null &&
        currentChatMessagePage.data.isNotEmpty) {
      return currentChatMessagePage.data[_currentIndex];
    }
    return null;
  }

  ///以下是从数据库取邮件的部分

  ///从邮件服务器中取当前地址当前邮箱的下一页的邮件数据，放入数据提供者的数组中
  loadMimeMessages() async {
    var currentMailAddress = this.currentMailAddress;
    if (currentMailAddress == null) {
      return;
    }
    String email = currentMailAddress.email;
    EmailClient? emailClient = EmailClientPool.instance.get(email);
    if (emailClient == null) {
      return;
    }
    enough_mail.Mailbox? currentMailbox = this.currentMailbox;
    if (currentMailbox == null) {
      return;
    }

    var currentMineMessagePage = this.currentMineMessagePage;
    datastore.Page<enough_mail.MimeMessage>? mineMessagePage;
    if (currentMineMessagePage == null) {
      mineMessagePage =
          await emailClient.fetchMessages(mailbox: currentMailbox);
    } else {
      int offset = currentMineMessagePage.next();
      mineMessagePage = await emailClient.fetchMessages(
          mailbox: currentMailbox, offset: offset);
      if (mineMessagePage != null) {
        currentMineMessagePage.data.addAll(mineMessagePage.data);
        currentMineMessagePage.page++;
      }
    }
    if (mineMessagePage != null && mineMessagePage.data.isNotEmpty) {
      for (var mimeMessage in mineMessagePage.data) {
        var chatMessage = EmailMessageUtil.convertToChatMessage(mimeMessage);
        chatMessage.subMessageType = currentMailboxName;
        chatMessage.targetAddress = email;
        chatMessage.actualReceiveTime = DateUtil.currentDate();
        var old = await ChatMessageService.instance.get(mimeMessage.guid!);
        if (old == null) {
          await ChatMessageService.instance.insert(chatMessage);
        }
        emailClient.deleteMessage(mimeMessage);
        var currentChatMessagePage = this.currentChatMessagePage;
        if (currentChatMessagePage != null) {
          currentChatMessagePage.data.add(chatMessage);
        }
      }
    }
  }

  ///从数据库中取当前地址当前邮箱的下一页的邮件数据，放入数据提供者的数组中
  loadChatMessages() {
    var currentChatMessagePage = this.currentChatMessagePage;
    if (currentChatMessagePage == null) {
      return;
    }
    if (currentChatMessagePage.limit == 0) {
      ChatMessageService.instance
          .findByMessageType('', MessageType.email.name, '')
          .then((chatMessages) {
        currentChatMessagePage.data.addAll(chatMessages.data);
        notifyListeners();
      });
    } else {
      var offset = currentChatMessagePage.next();
      ChatMessageService.instance
          .findByMessageType('', MessageType.email.name, '', offset: offset)
          .then((chatMessagePage) {
        currentChatMessagePage.data.addAll(chatMessagePage.data);
        currentChatMessagePage.page++;
        notifyListeners();
      });
    }
  }
}

final mailDataProvider = MailDataProvider();
