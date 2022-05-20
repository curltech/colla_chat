import 'package:colla_chat/app.dart';
import 'package:colla_chat/platform.dart';

import '../../datastore/base.dart';
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

class StockAccountService extends BaseService {
  static StockAccountService instance = StockAccountService();
  static bool initStatus = false;

  static StockAccountService getInstance() {
    if (!initStatus) {
      throw 'please init!';
    }
    return instance;
  }

  static Future<StockAccountService> init(
      {required String tableName,
      required List<String> fields,
      List<String>? indexFields}) async {
    if (!initStatus) {
      await BaseService.init(instance,
          tableName: tableName, fields: fields, indexFields: indexFields);
      initStatus = true;
    }
    return instance;
  }

  /**
   * 根据用户的信息查询本地是否存在账号，存在更新账号信息，不存在，创建新的账号
   * @param user
   */
  Future<StockAccount?> getOrRegist(dynamic user) async {
    String where = 'accountId = ?';
    StockAccount account;
    var accounts = await find(where, whereArgs: [user['userId']]);
    if (accounts != null && accounts.isNotEmpty && accounts[0] != null) {
      var acc = accounts[0];
      account = StockAccount.fromJson(acc as Map);
    } else {
      LocalStorage localStorage = await LocalStorage.getInstance();
      var subscription = await localStorage.get('StockSubscription');
      account = StockAccount();
      account.status = user['status'];
      account.accountId = user['userId'];
      account.accountName = user['userName'];
      account.name = user['name'];
      if (subscription != null) {
        account.subscription = subscription;
      }
      var currentDate = DateTime.now().toIso8601String();
      account.statusDate = currentDate;
    }
    account.lastLoginDate = user['lastLoginDate'];
    account.roles = user['roles'];
    await upsert(account);

    return account;
  }
}
