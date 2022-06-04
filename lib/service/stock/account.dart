import 'package:colla_chat/provider/app_data.dart';
import 'package:colla_chat/platform.dart';

import '../../entity/stock/account.dart';
import '../../service/base.dart';
import '../../tool/util.dart';
import '../base.dart';
import '../../datastore/sqflite.dart';

class StockAccountService extends BaseService {
  static final StockAccountService _instance = StockAccountService();
  static bool initStatus = false;

  static StockAccountService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<StockAccountService> init(
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

  /// 根据用户的信息查询本地是否存在账号，存在更新账号信息，不存在，创建新的账号
  /// @param user
  Future<StockAccount?> getOrRegist(dynamic user) async {
    String where = 'accountId = ?';
    StockAccount account;
    var accounts = await find(where, whereArgs: [user['userId']]);
    if (accounts != null && accounts.isNotEmpty && accounts[0] != null) {
      var acc = accounts[0];
      account = StockAccount.fromJson(acc as Map);
    } else {
      LocalStorage localStorage = await LocalStorage.instance;
      var subscription = await localStorage.get('StockSubscription');
      account = StockAccount();
      account.status = user['status'];
      account.accountId = user['userId'];
      account.accountName = user['userName'];
      account.name = user['name'];
      if (subscription != null) {
        account.subscription = subscription;
      }
      var currentDate = DateUtil.currentDate();
      account.statusDate = currentDate;
    }
    account.lastLoginDate = user['lastLoginDate'];
    account.roles = user['roles'];
    await upsert(account);

    return account;
  }
}

final stockAccountService = StockAccountService.instance;
