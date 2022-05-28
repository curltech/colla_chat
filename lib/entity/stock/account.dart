import 'package:colla_chat/app.dart';
import 'package:colla_chat/platform.dart';
import 'package:floor/floor.dart';

import '../../service/base.dart';
import '../base.dart';
import '../../datastore/sqflite.dart';

@Entity(tableName: 'stk_account')
class StockAccount extends StatusEntity {
  @ColumnInfo() //创建索引
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
