import '../../entity/dht/peerendpoint.dart';
import '../servicelocator.dart';
import 'base.dart';

class PeerEndpointService extends PeerEntityService<PeerEndpoint> {
  PeerEndpointService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return PeerEndpoint.fromJson(map);
    };
  }

  Future<List<PeerEndpoint>> findAllPeerEndpoint() async {
    var peerEndpoints = await find(orderBy: 'priority');
    return peerEndpoints;
  }

  store(PeerEndpoint peerEndpoint) async {
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
    indexFields: ['ownerPeerId', 'priority', 'address']);
