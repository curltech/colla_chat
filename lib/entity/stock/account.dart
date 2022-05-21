import 'package:colla_chat/app.dart';
import 'package:colla_chat/platform.dart';

import '../../service/base.dart';
import '../base.dart';
import '../../datastore/indexeddb.dart';
import '../../datastore/sqflite.dart';

class StockAccount extends StatusEntity {
  String? accountId;
  String? accountName;
  String? name;
  String? subscription;
  String? lastLoginDate;
  String? lastReadDate;
  String? roles = '';

  StockAccount();

  StockAccount.fromJson(Map json)
      : accountId = json['accountId'],
        accountName = json['accountName'],
        name = json['name'],
        subscription = json['subscription'],
        lastLoginDate = json['lastLoginDate'],
        roles = json['roles'],
        super.fromJson(json);

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
