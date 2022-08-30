import 'package:colla_chat/service/servicelocator.dart';

import '../../entity/dht/peerprofile.dart';
import '../../widgets/common/image_widget.dart';
import 'base.dart';

class PeerProfileService extends PeerEntityService<PeerProfile> {
  Map<String, Map<String, PeerProfile>> peerProfiles = {};

  PeerProfileService(
      {required String tableName,
      required List<String> fields,
      required List<String> indexFields})
      : super(tableName: tableName, fields: fields, indexFields: indexFields) {
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
        String? avatar = peerProfile_.avatar;
        if (avatar != null) {
          var avatarImage = ImageWidget(
            image: avatar,
            height: 32,
            width: 32,
          );
          peerProfile_.avatarImage = avatarImage;
        }
        if (!peerProfiles.containsKey(peerId)) {
          peerProfiles[peerId] = {};
        }
        peerProfiles[peerId]![clientId_] = peerProfile_;
        if (clientId == peerProfile_.clientId) {
          peerProfile = peerProfile_;
        }
      }
    }
    return peerProfile;
  }
}

final peerProfileService = PeerProfileService(
    tableName: "blc_peerprofile",
    fields: ServiceLocator.buildFields(PeerProfile('', ''), []),
    indexFields: ['peerId', 'clientId']);
