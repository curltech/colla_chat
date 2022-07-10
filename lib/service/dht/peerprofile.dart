import 'package:colla_chat/service/servicelocator.dart';

import '../../entity/dht/peerprofile.dart';
import '../../widgets/common/image_widget.dart';
import 'base.dart';

class PeerProfileService extends PeerEntityService<PeerProfile> {
  Map<String, PeerProfile> peerProfiles = {};
  PeerProfileService(
      {required String tableName,
      required List<String> fields,
      required List<String> indexFields})
      : super(tableName: tableName, fields: fields, indexFields: indexFields) {
    post = (Map map) {
      return PeerProfile.fromJson(map);
    };
  }

  Future<PeerProfile?> findCachedOneByPeerId(String peerId) async {
    if (peerProfiles.containsKey(peerId)) {
      return peerProfiles[peerId];
    }
    PeerProfile? peerProfile = await findOneByPeerId(peerId);
    if (peerProfile != null) {
      String? avatar = peerProfile.avatar;
      if (avatar != null) {
        var avatarImage = ImageWidget(
          image: avatar,
          height: 32,
          width: 32,
        );
        peerProfile.avatarImage = avatarImage;
      }
      peerProfiles[peerId] = peerProfile;
    }
    return peerProfile;
  }
}

final peerProfileService = PeerProfileService(
    tableName: "blc_peerprofile",
    fields: ServiceLocator.buildFields(PeerProfile(), []),
    indexFields: ['peerId']);
