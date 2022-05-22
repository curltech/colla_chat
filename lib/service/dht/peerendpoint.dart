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
}

final peerEndpointService = PeerEndpointService.instance;
