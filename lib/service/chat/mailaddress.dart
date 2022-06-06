import '../base.dart';

class MailAddressService extends BaseService {
  static final MailAddressService _instance = MailAddressService();
  static bool initStatus = false;

  static MailAddressService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<MailAddressService> init(
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
