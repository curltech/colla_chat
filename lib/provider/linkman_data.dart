import 'package:colla_chat/service/chat/contact.dart';
import 'package:flutter/material.dart';

import '../entity/chat/contact.dart';

class LinkmenDataProvider with ChangeNotifier {
  List<Linkman> _linkmen = [];

  LinkmenDataProvider() {
    linkmanService.findAllLinkmen().then((linkmen) {
      _linkmen = linkmen;
      notifyListeners();
    });
  }

  List<Linkman> get linkmen {
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
}
