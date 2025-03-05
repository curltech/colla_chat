import 'package:colla_chat/entity/stock/stock_account.dart';
import 'package:colla_chat/plugin/security_storage.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/date_util.dart';

class StockAccountService extends GeneralBaseService<StockAccount> {
  StockAccountService(
      {required super.tableName,
      required super.fields,
      super.uniqueFields,
      super.indexFields = const [
        'accountId',
        'accountName',
        'status',
        'updateDate'
      ],
      super.encryptFields}) {
    post = (Map map) {
      return StockAccount.fromJson(map);
    };
  }

  /// 根据用户的信息查询本地是否存在账号，存在更新账号信息，不存在，创建新的账号
  /// @param user
  Future<StockAccount?> getOrRegist(dynamic user) async {
    String where = 'accountId = ?';
    StockAccount account;
    var accounts = await find(where: where, whereArgs: [user['userId']]);
    if (accounts.isNotEmpty) {
      var acc = accounts[0];
      account = StockAccount.fromJson(acc as Map);
    } else {
      var subscription = await localSecurityStorage.get('StockSubscription');
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

final stockAccountService = StockAccountService(
  tableName: 'stk_account',
  fields: ServiceLocator.buildFields(StockAccount(), []),
);
