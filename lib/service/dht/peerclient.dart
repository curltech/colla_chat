import 'package:colla_chat/service/servicelocator.dart';
import 'package:cryptography/cryptography.dart';

import '../../entity/dht/peerclient.dart';
import 'base.dart';

class PeerClientService extends PeerEntityService<PeerClient> {
  var peerClients = <String, PeerClient>{};
  var publicKeys = <String, SimplePublicKey>{};

  PeerClientService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return PeerClient.fromJson(map);
    };
  }

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

final peerClientService = PeerClientService(
    tableName: "blc_peerclient",
    indexFields: ['peerId', 'name', 'mobile'],
    fields: ServiceLocator.buildFields(PeerClient(''), []));
