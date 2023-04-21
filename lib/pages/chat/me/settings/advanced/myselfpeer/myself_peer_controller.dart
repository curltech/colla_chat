import 'package:colla_chat/entity/dht/myselfpeer.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';

// 本机定位器，初始化后按照优先级排序
class MyselfPeerController extends DataListController<MyselfPeer> {
  MyselfPeerController();

  init() async {
    List<MyselfPeer> myselfPeers = await myselfPeerService.findAll();
    clear();
    if (myselfPeers.isNotEmpty) {
      addAll(myselfPeers);
    }
    notifyListeners();
  }
}

final MyselfPeerController myselfPeerController = MyselfPeerController();
