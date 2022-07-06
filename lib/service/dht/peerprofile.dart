import 'package:colla_chat/service/servicelocator.dart';

import '../../entity/dht/peerprofile.dart';
import 'base.dart';

class PeerProfileService extends PeerEntityService<PeerProfile> {
  PeerProfileService(
      {required String tableName,
      required List<String> fields,
      required List<String> indexFields})
      : super(tableName: tableName, fields: fields, indexFields: indexFields) {
    post = (Map map) {
      return PeerProfile.fromJson(map);
    };
  }
}

final peerProfileService = PeerProfileService(
    tableName: "blc_peerprofile",
    fields: ServiceLocator.buildFields(PeerProfile(), []),
    indexFields: ['peerId']);
