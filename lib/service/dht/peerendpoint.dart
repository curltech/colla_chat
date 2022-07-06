import '../../entity/dht/peerendpoint.dart';
import '../base.dart';

class PeerEndpointService extends BaseService {
  static final PeerEndpointService _instance = PeerEndpointService();
  static bool initStatus = false;

  static PeerEndpointService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<PeerEndpointService> init(
      {required String tableName,
      required List<String> fields,
      List<String>? indexFields}) async {
    if (!initStatus) {
      await BaseService.init(_instance,
          tableName: tableName, fields: fields, indexFields: indexFields);
      initStatus = true;
    }
    return _instance;
  }

  Future<List<PeerEndpoint>> findAllPeerEndpoint() async {
    var peerEndpoints_ = await find();
    List<PeerEndpoint> peerEndpoints = [];
    if (peerEndpoints_.isNotEmpty) {
      for (var peerEndpoint_ in peerEndpoints_) {
        var peerEndpoint = PeerEndpoint.fromJson(peerEndpoint_);
        peerEndpoints.add(peerEndpoint);
      }
    }
    return peerEndpoints;
  }
}

final peerEndpointService = PeerEndpointService.instance;
