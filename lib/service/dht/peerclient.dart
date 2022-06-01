import 'package:cryptography/cryptography.dart';

import '../../entity/dht/peerclient.dart';
import '../base.dart';
import 'base.dart';

class PeerClientService extends PeerEntityService {
  static final PeerClientService _instance = PeerClientService();
  static bool initStatus = false;

  static PeerClientService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<PeerClientService> init(
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

  var peerClients = <String, PeerClient>{};
  var publicKeys = <String, SimplePublicKey>{};

  Future<SimplePublicKey?> getPublicKey(String peerId) async {
    var peerClient = getPeerClientFromCache(peerId);
    if (peerClient != null) {
      return publicKeys[peerId];
    }

    return null;
  }

  PeerClient? getPeerClientFromCache(String peerId) {
    if (peerClients.containsKey(peerId)) {
      return peerClients[peerId];
    }

    return null;
  }

/**
 * Connect
 */
//  connect() async {
//   var appParams=await AppParams.instance;
//   var connectPeerId = appParams.connectPeerId[0];
//   var activeStatus = ActiveStatus.Up.toString();
//   var peerClient = await this.preparePeerClient(connectPeerId, activeStatus);
//   if (peerClient) {
//     logger.i('connect:' + peerClient.peerId + ';connectPeerId:' + connectPeerId);
//     var result = await connectAction.connect(connectPeerId, peerClient);
//     return result;
//   }
// }
}

final peerClientService = PeerClientService.instance;
