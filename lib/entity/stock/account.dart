import 'package:colla_chat/app.dart';
import 'package:colla_chat/platform.dart';

import '../../datastore/base.dart';
import '../../datastore/indexeddb.dart';
import '../../datastore/sqflite.dart';

class Account extends StatusEntity {
  String? accountId;
  String? accountName;
  String? name;
  String? subscription;
  DateTime? lastLoginDate;
  DateTime? lastReadDate;
  String? roles = '';
}

class AccountService extends BaseService {
  static AccountService instance = AccountService();
  static bool initStatus = false;

  static AccountService getInstance() {
    if (!initStatus) {
      throw 'please init!';
    }
    return instance;
  }

  static Future<AccountService> init(
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
  Future<Account?> getOrRegist(dynamic user) async {
    String where = 'accountId = ?';
    Account? account;
    var accounts = await find(where, whereArgs: [user['userId']]);
    if (accounts != null && accounts.isNotEmpty && accounts[0] != null) {
      account = accounts[0] as Account?;
    } else {
      LocalStorage localStorage = await LocalStorage.getInstance();
      var subscription = await localStorage.get('StockSubscription');
      account = Account();
      account.status = user['status'];
      account.accountId = user['userId'];
      account.accountName = user['userName'];
      account.name = user['name'];
      if (subscription != null) {
        account.subscription = subscription;
      }
      var currentDate = DateTime.now();
      account.createDate = currentDate;
      account.updateDate = currentDate;
      account.statusDate = currentDate;
    }
    account?.lastLoginDate = user['lastLoginDate'];
    account?.roles = user.roles;
    await upsert(account);

    return account;
  }
}
