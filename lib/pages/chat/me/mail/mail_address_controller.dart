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

/// 邮件地址的状态管理器，维护了好友列表，当前好友
class MailAddressController with ChangeNotifier {
  List<MailAddress> _mailAddresses = [];
  int _currentIndex = 0;

  MailAddressController() {
    MailAddressService.instance.findAllMailAddress().then((mailAddress) {
      _mailAddresses.addAll(mailAddress);
      notifyListeners();
    });
  }

  List<MailAddress> get mailAddresses {
    return _mailAddresses;
  }

  set mailAddresses(List<MailAddress> mailAddress) {
    _mailAddresses = mailAddress;
    notifyListeners();
  }

  add(List<MailAddress> mailAddresses) {
    _mailAddresses.addAll(mailAddresses);
    notifyListeners();
  }

  MailAddress get mailAddress {
    return _mailAddresses[_currentIndex];
  }

  int get currentIndex {
    return _currentIndex;
  }

  set currentIndex(int currentIndex) {
    _currentIndex = currentIndex;
    notifyListeners();
  }
}
