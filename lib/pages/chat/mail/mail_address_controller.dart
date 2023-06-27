import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/mailaddress.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/mailaddress.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:enough_mail/enough_mail.dart' as enough_mail;
import 'package:flutter/material.dart';

/// 邮件地址控制器，每个地址有多个邮箱，每个邮箱包含多个邮件
class MailAddressController with ChangeNotifier {
  final Map<String, MailAddress> _mailAddress = {};
  final Map<String, Map<String, enough_mail.Mailbox?>> _addressMailboxes = {};
  final Map<String, Map<String, List<ChatMessage>>> _addressChatMessagePages =
      {};
  final Map<String, Map<String, List<enough_mail.MimeMessage>>>
      _addressMimeMessagePages = {};
  MailAddress? _currentMailAddress;
  String? _currentMailboxName;
  int _currentIndex = 0;

  ///构造函数从数据库获取所有的邮件地址，初始化邮箱数据
  MailAddressController() {
    mailAddressService
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
      var currentMailboxName = _currentMailboxName;
      if (currentMailboxName == null) {
        return null;
      }
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

  ///获取当前地址的邮箱名称的邮件
  List<ChatMessage>? getMailboxChatMessages(String mailboxName) {
    var currentMailAddress = this.currentMailAddress;
    if (currentMailAddress == null) {
      return null;
    }
    var email = currentMailAddress.email;
    Map<String, List<ChatMessage>>? mailboxChatMessagePages =
        _addressChatMessagePages[email];
    if (mailboxChatMessagePages == null) {
      return null;
    }
    List<ChatMessage>? chatMessages = mailboxChatMessagePages[mailboxName];
    return chatMessages;
  }

  ///获取当前地址的当前邮箱的邮件
  List<ChatMessage>? get currentChatMessagePage {
    var currentMailboxName = _currentMailboxName;
    if (currentMailboxName == null) {
      return null;
    }
    List<ChatMessage>? chatMessagePage =
        getMailboxChatMessages(currentMailboxName);
    return chatMessagePage;
  }

  ///获取当前地址的当前邮箱的邮件
  set currentChatMessagePage(List<ChatMessage>? chatMessagePage) {
    var currentMailAddress = this.currentMailAddress;
    if (currentMailAddress == null) {
      return;
    }
    var email = currentMailAddress.email;
    Map<String, List<ChatMessage>>? mailboxChatMessagePages =
        _addressChatMessagePages[email];
    if (mailboxChatMessagePages == null) {
      return;
    }
    var currentMailboxName = _currentMailboxName;
    if (currentMailboxName == null) {
      return;
    }
    if (chatMessagePage == null) {
      mailboxChatMessagePages.remove(currentMailboxName);
    } else {
      mailboxChatMessagePages[currentMailboxName] = chatMessagePage;
    }
  }

  ///获取当前地址的当前邮箱的邮件
  List<enough_mail.MimeMessage>? get currentMimeMessagePage {
    var currentMailAddress = this.currentMailAddress;
    if (currentMailAddress == null) {
      return null;
    }
    var email = currentMailAddress.email;
    Map<String, List<enough_mail.MimeMessage>>? mailboxMimeMessagePages =
        _addressMimeMessagePages[email];
    if (mailboxMimeMessagePages == null) {
      return null;
    }
    var currentMailboxName = _currentMailboxName;
    if (currentMailboxName == null) {
      return null;
    }
    List<enough_mail.MimeMessage>? mimeMessagePage =
        mailboxMimeMessagePages[currentMailboxName];
    return mimeMessagePage;
  }

  ///获取当前地址的当前邮箱的邮件
  set currentMimeMessagePage(List<enough_mail.MimeMessage>? mimeMessagePage) {
    var currentMailAddress = this.currentMailAddress;
    if (currentMailAddress == null) {
      return;
    }
    var email = currentMailAddress.email;
    Map<String, List<enough_mail.MimeMessage>>? mailboxMimeMessagePages =
        _addressMimeMessagePages[email];
    if (mailboxMimeMessagePages == null) {
      return;
    }
    var currentMailboxName = _currentMailboxName;
    if (currentMailboxName == null) {
      return;
    }
    if (mimeMessagePage == null) {
      mailboxMimeMessagePages.remove(currentMailboxName);
    } else {
      mailboxMimeMessagePages[currentMailboxName] = mimeMessagePage;
    }
  }

  ///获取当前地址的当前邮箱的当前邮件
  ChatMessage? get currentChatMessage {
    var currentChatMessagePage = this.currentChatMessagePage;
    if (currentChatMessagePage != null) {
      return currentChatMessagePage[_currentIndex];
    }
    return null;
  }

  ///以下是从数据库取邮件的部分

  ///从邮件服务器中取当前地址当前邮箱的下一页的邮件数据，放入数据提供者的数组中
  ///而且转换成charMessage,放入数据提供者的数组中
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

    var currentMimeMessagePage = this.currentMimeMessagePage;
    List<enough_mail.MimeMessage>? mimeMessagePage;
    if (currentMimeMessagePage == null) {
      mimeMessagePage =
          await emailClient.fetchMessages(mailbox: currentMailbox);
      currentMimeMessagePage = mimeMessagePage;
    } else {
      mimeMessagePage = await emailClient.fetchMessages(
        mailbox: currentMailbox,
      );
      if (mimeMessagePage != null) {
        currentMimeMessagePage.addAll(mimeMessagePage);
      }
    }
    this.currentMimeMessagePage = currentMimeMessagePage;
    if (mimeMessagePage != null && mimeMessagePage.isNotEmpty) {
      var currentChatMessagePage = this.currentChatMessagePage;
      if (currentChatMessagePage == null) {
        currentChatMessagePage = <ChatMessage>[];
        this.currentChatMessagePage = currentChatMessagePage;
      }
      for (var mimeMessage in mimeMessagePage) {
        var chatMessage = EmailMessageUtil.convertToChatMessage(mimeMessage);
        chatMessage.subMessageType = currentMailboxName!;
        chatMessage.senderAddress = email;
        chatMessage.receiveTime = DateUtil.currentDate();
        var old = await chatMessageService.get(mimeMessage.guid!);
        if (old == null) {
          await chatMessageService.insert(chatMessage);
        }
        try {
          enough_mail.DeleteResult? deleteResult =
              await emailClient.deleteMessage(mimeMessage);
          logger.i(deleteResult);
        } catch (e) {
          logger.e(e);
        }
        currentChatMessagePage.add(chatMessage);
      }

      notifyListeners();
    }
  }

  ///从数据库中取当前地址当前邮箱的下一页的邮件数据，放入数据提供者的数组中
  loadChatMessages() {
    var currentMailAddress = this.currentMailAddress;
    if (currentMailAddress == null) {
      return;
    }
    String email = currentMailAddress.email;
    enough_mail.Mailbox? currentMailbox = this.currentMailbox;
    if (currentMailbox == null) {
      return;
    }
    var currentMailboxName = _currentMailboxName;
    if (currentMailboxName == null) {
      return null;
    }
    var currentChatMessagePage = this.currentChatMessagePage;
    if (currentChatMessagePage == null) {
      chatMessageService
          .findByMessageType(ChatMessageType.email.name,
              targetAddress: email, subMessageType: currentMailboxName)
          .then((chatMessagePage) {
        currentChatMessagePage = chatMessagePage;
        this.currentChatMessagePage = chatMessagePage;
        if (currentChatMessagePage != null) {
          currentChatMessagePage!.addAll(chatMessagePage);
          notifyListeners();
        }
      });
    } else {
      chatMessageService
          .findByMessageType(
        ChatMessageType.email.name,
        targetAddress: email,
        subMessageType: currentMailboxName,
      )
          .then((chatMessagePage) {
        if (currentChatMessagePage != null) {
          currentChatMessagePage!.addAll(chatMessagePage);
          notifyListeners();
        }
      });
    }
  }
}

final mailAddressController = MailAddressController();
