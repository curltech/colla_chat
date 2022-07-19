import 'package:colla_chat/service/dht/peerprofile.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:cryptography/cryptography.dart';

import '../../entity/dht/peerclient.dart';
import '../../entity/dht/peerprofile.dart';
import 'base.dart';

class PeerClientService extends PeerEntityService<PeerClient> {
  var peerClients = <String, Map<String, PeerClient>>{};
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
    var peerClient = await findCachedOneByPeerId(peerId);
    if (peerClient != null) {
      return publicKeys[peerId];
    }

    return null;
  }

  Future<PeerClient?> findCachedOneByPeerId(String peerId,
      {String? clientId}) async {
    if (peerClients.containsKey(peerId)) {
      var peerClients_ = peerClients[peerId];
      if (peerClients_ != null && peerClients_.containsKey(clientId)) {
        return peerClients_[clientId];
      }
    }
    PeerClient? peerClient;
    List<PeerClient> peerClients_ = await findByPeerId(peerId);
    if (peerClients_.isNotEmpty) {
      for (var peerClient_ in peerClients_) {
        var clientId_ = peerClient_.clientId;
        PeerProfile? peerProfile = await peerProfileService
            .findCachedOneByPeerId(peerId, clientId: clientId_!);
        if (peerProfile != null) {
          peerClient_.peerProfile = peerProfile;
        }
        if (!peerClients.containsKey(peerId)) {
          peerClients[peerId] = {};
        }
        peerClients[peerId]![clientId_] = peerClient_;
        if (clientId == clientId_) {
          peerClient = peerClient_;
        }
      }
    }
    return peerClient;
  }

  Future<PeerClient?> findOneByClientId(String peerId,
      {String? clientId}) async {
    var where = 'peerId=?';
    var whereArgs = [peerId];
    if (clientId != null) {
      where = '$where and clientId =?';
      whereArgs.add(clientId);
    }

    var peer = await findOne(where: where, whereArgs: whereArgs);

    return peer;
  }

  store(PeerClient peerClient) async {
    PeerClient? peerClient_ = await findOneByClientId(peerClient.peerId,
        clientId: peerClient.clientId);
    if (peerClient_ != null) {
      peerClient.id = peerClient_.id;
      update(peerClient);
    } else {
      insert(peerClient);
    }
    var peerId = peerClient.peerId;
    var clientId = peerClient.clientId;
    if (!peerClients.containsKey(peerId)) {
      peerClients[peerId] = {};
    }
    peerClients[peerId]![clientId] = peerClient;
  }
}

final peerClientService = PeerClientService(
    tableName: "blc_peerclient",
    indexFields: ['peerId', 'name', 'mobile'],
    fields: ServiceLocator.buildFields(PeerClient('', '', ''), []));
