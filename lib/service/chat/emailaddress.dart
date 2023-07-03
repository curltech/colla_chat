import 'package:colla_chat/entity/chat/emailaddress.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';

class EmailAddressService extends GeneralBaseService<EmailAddress> {
  EmailAddressService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return EmailAddress.fromJson(map);
    };
  }

  Future<List<EmailAddress>> findAllMailAddress() async {
    var mailAddress = await find();
    return mailAddress;
  }

  Future<EmailAddress?> findByMailAddress(String email) async {
    var mailAddress = await findOne(
      where: 'email=?',
      whereArgs: [email],
    );
    return mailAddress;
  }

  store(EmailAddress mailAddress) async {
    EmailAddress? old = await findByMailAddress(mailAddress.email);
    if (old != null) {
      mailAddress.id = old.id;
      await update(mailAddress);
    } else {
      await insert(mailAddress);
    }
  }
}

final emailAddressService = EmailAddressService(
    tableName: "chat_mailaddress",
    indexFields: ['ownerPeerId', 'email', 'name'],
    fields: ServiceLocator.buildFields(EmailAddress(name: '', email: '@'), []));
