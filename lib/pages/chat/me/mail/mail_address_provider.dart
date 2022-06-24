import 'package:colla_chat/entity/chat/chat.dart';
import 'package:flutter/material.dart';

import '../../../../entity/chat/mailaddress.dart';
import '../../../../provider/app_data_provider.dart';
import '../../../../service/chat/mailaddress.dart';
import '../../../../widgets/common/data_listtile.dart';

final List<TileData> mailAddrTileData = [
  TileData(
      icon: Icon(Icons.inbox,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'Inbox'),
  TileData(
      icon: Icon(Icons.mark_as_unread,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'Unread'),
  TileData(
      icon: Icon(Icons.drafts,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'Draft'),
  TileData(
      icon: Icon(Icons.send,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'Sent'),
  TileData(
      icon: Icon(Icons.flag,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'Mark'),
  TileData(
      icon: Icon(Icons.delete,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'Trash'),
  TileData(
      icon: Icon(Icons.bug_report,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'Junk'),
  TileData(
      icon: Icon(Icons.ads_click,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: 'Ads'),
];

/// 邮件地址的状态管理器
class MailAddressProvider with ChangeNotifier {
  final Map<MailAddress, List<ChatMessage>> _mailAddresses = {};
  MailAddress? _currentMailAddress;
  int _currentIndex = 0;

  MailAddressProvider() {
    MailAddressService.instance
        .findAllMailAddress()
        .then((List<MailAddress> mailAddresses) {
      this.mailAddresses = mailAddresses;
    });
  }

  List<MailAddress> get mailAddresses {
    return _mailAddresses.keys.toList();
  }

  set mailAddresses(List<MailAddress> mailAddress) {
    if (mailAddresses.isNotEmpty) {
      for (var mailAddress in mailAddresses) {
        _mailAddresses[mailAddress] = [];
        if (mailAddress.isDefault) {
          _currentMailAddress = mailAddress;
        }
      }
    }
    if (_currentMailAddress == null && _mailAddresses.isEmpty) {
      _currentMailAddress = _mailAddresses.keys.first;
    }
    notifyListeners();
  }

  add(List<MailAddress> mailAddresses) {
    if (mailAddresses.isNotEmpty) {
      for (var mailAddress in mailAddresses) {
        if (!_mailAddresses.containsKey(mailAddress)) {
          _mailAddresses[mailAddress] = [];
        }
      }
    }
    notifyListeners();
  }

  MailAddress? get currentMailAddress {
    return _currentMailAddress;
  }

  set currentMailAddress(MailAddress? mailAddress) {
    _currentMailAddress = mailAddress;
    notifyListeners();
  }

  int get currentIndex {
    return _currentIndex;
  }

  set currentIndex(int currentIndex) {
    _currentIndex = currentIndex;
    notifyListeners();
  }

  List<ChatMessage>? get currentChatMessages {
    List<ChatMessage>? chatMessages = _mailAddresses[currentMailAddress];

    return chatMessages;
  }

  ChatMessage? get currentChatMessage {
    List<ChatMessage>? chatMessages = _mailAddresses[currentMailAddress];
    if (chatMessages != null && chatMessages.isNotEmpty) {
      return chatMessages[_currentIndex];
    }
    return null;
  }
}

final mailAddressProvider = MailAddressProvider();
