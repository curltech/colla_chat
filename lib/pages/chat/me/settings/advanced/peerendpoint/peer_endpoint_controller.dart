import 'package:colla_chat/constant/address.dart';
import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/dht/peerendpoint.dart';

// 定位器，初始化后按照优先级排序
class PeerEndpointController extends DataListController<PeerEndpoint> {
  int _defaultIndex = 0;

  PeerEndpointController() {
    init();
  }

  PeerEndpoint? get defaultPeerEndpoint {
    if (_defaultIndex > -1) {
      return data[_defaultIndex];
    }
    return null;
  }

  int? get defaultIndex {
    return _defaultIndex;
  }

  set defaultIndex(int? defaultIndex) {
    if (defaultIndex != null && defaultIndex > -1) {
      _defaultIndex = defaultIndex;
      notifyListeners();
    }
  }

  init() {
    peerEndpointService
        .findAllPeerEndpoint()
        .then((List<PeerEndpoint> peerEndpoints) {
      clear();
      if (peerEndpoints.isNotEmpty) {
        addAll(peerEndpoints);
      } else {
        for (var peerEndpoint in nodeAddressOptions.values) {
          peerEndpointService.insert(peerEndpoint);
          data.add(peerEndpoint);
        }
        notifyListeners();
      }
    });
  }
}

final PeerEndpointController peerEndpointController = PeerEndpointController();
