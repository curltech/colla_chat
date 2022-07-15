import '../../entity/dht/peerendpoint.dart';
import '../general_base.dart';
import '../servicelocator.dart';

class PeerEndpointService extends GeneralBaseService<PeerEndpoint> {
  PeerEndpointService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return PeerEndpoint.fromJson(map);
    };
  }

  Future<List<PeerEndpoint>> findAllPeerEndpoint() async {
    var peerEndpoints = await find();
    return peerEndpoints;
  }
}

final peerEndpointService = PeerEndpointService(
    tableName: "blc_peerendpoint",
    fields: ServiceLocator.buildFields(PeerEndpoint('', ''), []),
    indexFields: ['ownerPeerId', 'priority', 'address']);
