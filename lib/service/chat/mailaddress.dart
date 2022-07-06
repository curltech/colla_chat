import 'package:colla_chat/service/servicelocator.dart';

import '../../entity/chat/mailaddress.dart';
import '../general_base.dart';

class MailAddressService extends GeneralBaseService<MailAddress> {
  MailAddressService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return MailAddress.fromJson(map);
    };
  }

  Future<List<MailAddress>> findAllMailAddress() async {
    var mailAddress = await find();
    return mailAddress;
  }

  Future<MailAddress?> findByMailAddress(String email) async {
    var mailAddress = await findOne(
      where: 'email=?',
      whereArgs: [email],
    );
    return mailAddress;
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

final mailAddressService = MailAddressService(
    tableName: "chat_mailaddress",
    indexFields: ['ownerPeerId', 'email', 'name'],
    fields: ServiceLocator.buildFields(
        MailAddress(ownerPeerId: '', name: '', email: '@'), []));
