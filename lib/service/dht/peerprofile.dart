import 'package:colla_chat/service/servicelocator.dart';

import '../../entity/dht/peerprofile.dart';
import 'base.dart';

class PeerProfileService extends PeerEntityService<PeerProfile> {
  Map<String, Map<String, PeerProfile>> peerProfiles = {};

  PeerProfileService(
      {required super.tableName,
      required super.fields,
      super.uniqueFields = const ['peerId'],
      super.indexFields = const ['clientId'],
      super.encryptFields}) {
    post = (Map map) {
      return PeerProfile.fromJson(map);
    };
  }

  Future<PeerProfile?> findOneByClientId(String peerId,
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

  Future<PeerProfile?> findCachedOneByPeerId(String peerId,
      {String? clientId}) async {
    if (peerProfiles.containsKey(peerId)) {
      var peerProfiles_ = peerProfiles[peerId];
      if (peerProfiles_ != null) {
        if (clientId == null) {
          return peerProfiles_.values.first;
        }
        if (peerProfiles_.containsKey(clientId)) {
          return peerProfiles_[clientId];
        }
      }
    }
    List<PeerProfile> peerProfiles_ = await findByPeerId(peerId);
    PeerProfile? peerProfile;
    if (peerProfiles_.isNotEmpty) {
      for (var peerProfile_ in peerProfiles_) {
        String clientId_ = peerProfile_.clientId;
        if (!peerProfiles.containsKey(peerId)) {
          peerProfiles[peerId] = {};
        }
        peerProfiles[peerId]![clientId_] = peerProfile_;
        if (clientId == null || clientId == peerProfile_.clientId) {
          peerProfile = peerProfile_;
        }
      }
    }
    return peerProfile;
  }

  ///保存MyselfPeer，同时保存对应的PeerClient和Linkman
  Future<void> store(PeerProfile peerProfile) async {
    PeerProfile? old =
        await findOne(where: 'peerId=?', whereArgs: [peerProfile.peerId]);
    if (old == null) {
      await insert(peerProfile);
    } else {
      peerProfile.id = old.id;
      await update(peerProfile);
    }
  }
}

final PeerProfileService peerProfileService = PeerProfileService(
  tableName: "blc_peerprofile",
  fields: ServiceLocator.buildFields(PeerProfile(''), []),
);
