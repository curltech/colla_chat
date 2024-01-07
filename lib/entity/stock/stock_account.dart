import 'package:colla_chat/entity/base.dart';

class StockAccount extends StatusEntity {
  String? accountId;
  String? accountName;
  String? name;
  String? subscription;
  String? lastLoginDate;
  String? lastReadDate;
  String? roles = '';

  StockAccount();

  StockAccount.fromJson(super.json)
      : accountId = json['accountId'],
        accountName = json['accountName'],
        name = json['name'],
        subscription = json['subscription'],
        lastLoginDate = json['lastLoginDate'],
        roles = json['roles'],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'accountId': accountId,
      'accountName': accountName,
      'name': name,
      'subscription': subscription,
      'lastLoginDate': lastLoginDate,
      'roles': roles,
    });
    return json;
  }
}
