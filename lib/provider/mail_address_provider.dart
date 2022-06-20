import 'package:flutter/material.dart';

import '../entity/chat/mailaddress.dart';
import '../service/chat/mailaddress.dart';

/// 好友的状态管理器，维护了好友列表，当前好友
class MailAddressProvider with ChangeNotifier {
  List<MailAddress> _mailAddresses = [];
  int _currentIndex = 0;
  bool initStatus = false;

  MailAddressProvider();

  init() {
    MailAddressService.instance.findAllMailAddress().then((mailAddress) {
      _mailAddresses.addAll(mailAddress);
      initStatus = true;
      notifyListeners();
    });
  }

  List<MailAddress> get mailAddresses {
    if (!initStatus) {
      init();
    }
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
