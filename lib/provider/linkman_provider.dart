import 'package:colla_chat/service/chat/contact.dart';
import 'package:flutter/material.dart';

import '../entity/chat/contact.dart';

/// 好友的状态管理器，维护了好友列表，当前好友
class LinkmanProvider with ChangeNotifier {
  List<Linkman> _linkmen = [];
  int _currentIndex = 0;
  bool initStatus = false;

  LinkmanProvider();

  init() {
    LinkmanService.instance.findAllLinkmen().then((linkmen) {
      _linkmen.addAll(linkmen);
      initStatus = true;
      notifyListeners();
    });
  }

  List<Linkman> get linkmen {
    if (!initStatus) {
      init();
    }
    return _linkmen;
  }

  set linkmen(List<Linkman> linkmen) {
    _linkmen = linkmen;
    notifyListeners();
  }

  add(List<Linkman> linkmen) {
    _linkmen.addAll(linkmen);
    notifyListeners();
  }

  Linkman get linkman {
    return _linkmen[_currentIndex];
  }

  int get currentIndex {
    return _currentIndex;
  }

  set currentIndex(int currentIndex) {
    _currentIndex = currentIndex;
    notifyListeners();
  }
}
