import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/service/dht/base.dart';
import 'package:colla_chat/service/servicelocator.dart';

class PeerEndpointService extends PeerEntityService<PeerEndpoint> {
  PeerEndpointService({
    required super.tableName,
    required super.fields,
    super.uniqueFields,
    super.indexFields = const ['ownerPeerId', 'priority', 'address'],
    super.encryptFields = const [
      'uriKey',
      'uriSecret',
    ],
  }) {
    post = (Map map) {
      return PeerEndpoint.fromJson(map);
    };
  }

  Future<List<PeerEndpoint>> findAllPeerEndpoint() async {
    var peerEndpoints = await find(orderBy: 'priority');
    return peerEndpoints;
  }

  Future<void> store(PeerEndpoint peerEndpoint) async {
    PeerEndpoint? peerEndpoint_ = await findOneByPeerId(peerEndpoint.peerId);
    if (peerEndpoint_ != null) {
      peerEndpoint.id = peerEndpoint_.id;
      update(peerEndpoint);
    } else {
      insert(peerEndpoint);
    }
  }
}

final peerEndpointService = PeerEndpointService(
  tableName: "blc_peerendpoint",
  fields: ServiceLocator.buildFields(PeerEndpoint(name: '', peerId: ''), []),
);
