import '../../entity/base.dart';
import '../../service/base.dart';
import '../base.dart';
import 'base.dart';

class PeerProfileService extends PeerEntityService {
  static final PeerProfileService _instance = PeerProfileService();
  static bool initStatus = false;

  static PeerProfileService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<PeerProfileService> init(
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

final peerProfileService = PeerProfileService.instance;
