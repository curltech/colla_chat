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
    if (data.isNotEmpty && _defaultIndex > -1 && _defaultIndex < data.length) {
      return data[_defaultIndex];
    }
    return null;
  }

  int? get defaultIndex {
    return _defaultIndex;
  }

  set defaultIndex(int? defaultIndex) {
    if (data.isNotEmpty &&
        defaultIndex != null &&
        defaultIndex > -1 &&
        defaultIndex < data.length) {
      _defaultIndex = defaultIndex;
    }
  }

  Future<void> init() async {
    data.clear();
    for (var peerEndpoint in nodeAddressOptions.values) {
      peerEndpointService.store(peerEndpoint);
      add(peerEndpoint);
    }
    List<PeerEndpoint> peerEndpoints =
        await peerEndpointService.findAllPeerEndpoint();
    if (peerEndpoints.isNotEmpty) {
      for (var peerEndpoint in peerEndpoints) {
        if (!nodeAddressOptions.containsKey(peerEndpoint.name)) {
          add(peerEndpoint);
        }
      }
    }
  }

  PeerEndpoint? find({String? peerId, String? address}) {
    if (peerId != null) {
      for (var peerEndpoint in data) {
        if (peerEndpoint.peerId == peerId) {
          return peerEndpoint;
        }
      }
    } else if (address != null) {
      for (var peerEndpoint in data) {
        if (peerEndpoint.wsConnectAddress == address) {
          return peerEndpoint;
        }
      }
    }

    return defaultPeerEndpoint;
  }
}

final PeerEndpointController peerEndpointController = PeerEndpointController();
