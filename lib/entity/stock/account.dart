import 'package:colla_chat/config.dart';

import '../../datastore/base.dart';

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
  AccountService(String tableName, List<String> fields,
      [List<String>? indexFields])
      : super(tableName, fields, indexFields);

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
      var subscription = LocalStorage.get('StockSubscription');
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

var accountService = AccountService(
    'stk_account', ['accountId', 'accountName', 'status', 'updateDate'], []);
