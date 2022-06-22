import '../../entity/chat/mailaddress.dart';
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

  Future<List<MailAddress>> findAllMailAddress() async {
    var mailAddress_ = await find(null, whereArgs: []);
    List<MailAddress> mailAddress = [];
    if (mailAddress_.isNotEmpty) {
      for (var mailAddr_ in mailAddress_) {
        var mailAddr = MailAddress.fromJson(mailAddr_);
        mailAddress.add(mailAddr);
      }
    }
    return mailAddress;
  }

  Future<MailAddress?> findByMailAddress(String email) async {
    var mailAddress_ = await findOne('email=?', whereArgs: [email]);
    if (mailAddress_ != null) {
      var mailAddr = MailAddress.fromJson(mailAddress_);
      return mailAddr;
    }
    return null;
  }

  store(MailAddress mailAddress) async {
    MailAddress? old = await findByMailAddress(mailAddress.email);
    if (old != null) {
      mailAddress.id = old.id;
      await update(mailAddress);
    } else {
      await insert(mailAddress);
    }
  }
}
