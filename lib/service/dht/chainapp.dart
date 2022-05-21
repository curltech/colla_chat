import '../../service/base.dart';
import '../base.dart';

class ChainAppService extends BaseService {
  static final ChainAppService _instance = ChainAppService();
  static bool initStatus = false;

  static ChainAppService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<ChainAppService> init(
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
