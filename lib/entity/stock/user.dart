import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/type_util.dart';

import '../../service/stock/account.dart';
import '../../transport/webclient.dart';
import 'account.dart';

class StockUser {
  //登录用户的基本信息
  StockAccount? account;

  //登录状态
  bool loginStatus = false;

  //用户令牌
  String token = '';

  //用户自选，当前指定(显示在标题上)
  List<Map<String, dynamic>> shares = <Map<String, dynamic>>[];
  Map<String, dynamic>? _share;
  int? tradeDate;

  //用户自选股的当前股票，修改将同时修改share
  int _currentIndex = -1;

  //多选选择的股票代码,注意share有可能不在shares中
  List<Map<String, dynamic>> selectedShares = <Map<String, dynamic>>[];
  List<int> terms = [0];

  //用户在index页的选择
  String _drawer = 'me';

  //用户的当前页的选择
  String tab = 'selfselection';
  String error = 'error';

  constructor() {}

  Map<String, dynamic>? getShare() {
    return _share;
  }

  set share(Map<String, dynamic> val) {
    _share = val;
    if (shares.isNotEmpty) {
      for (var i = 0; i < shares.length; ++i) {
        var sh = shares[i];
        if (sh == val) {
          _currentIndex = i;
          return;
        }
      }
    }
    _currentIndex = -1;
  }

  String get drawer {
    return _drawer;
  }

  set drawer(String val) {
    _drawer = val;
    if (_drawer == 'me') {
      tab = 'selfselection';
    } else if (_drawer == 'value') {
      tab = 'scoresearch';
    } else if (_drawer == 'trade') {
      tab = 'inout';
    } else if (_drawer == 'portfolio') {
      tab = 'sector';
    } else if (_drawer == 'setting') {
      tab = 'schedule';
    }
  }

  String? getSubscription() {
    return account?.subscription;
  }

  set subscription(String val) {
    if (val.startsWith(',')) {
      val = val.substring(1, val.length);
    }
    if (val.endsWith(',')) {
      val = val.substring(0, val.length - 1);
    }
    account?.subscription = val;
  }

  addSubscription(String tsCode) {
    final account = this.account;
    if (account != null) {
      var subscription = account.subscription;
      subscription ??= '';
      var pos = subscription.indexOf(tsCode);
      if (pos == -1) {
        if (subscription == '') {
          account.subscription = (subscription + tsCode);
        } else {
          account.subscription = '$subscription,$tsCode';
        }
        stockAccountService.upsert(account);
      }
    }
  }

  removeSubscription(String tsCode) {
    final account = this.account;
    if (account != null) {
      var subscription = account.subscription;
      subscription ??= '';
      var pos = subscription.indexOf(tsCode);
      if (pos != -1) {
        account.subscription = subscription.replaceAll(',$tsCode', '');
        account.subscription = subscription.replaceAll(tsCode, '');
        stockAccountService.upsert(account);
      }
    }
  }

  bool canbeAdd(String tsCode) {
    final account = this.account;
    if (account != null) {
      account.subscription ??= '';
      var subscription = account.subscription;
      var pos = subscription?.indexOf(tsCode);
      if (pos == -1) {
        return true;
      }
    }
    return false;
  }

  bool canbenRemove(String tsCode) {
    final account = this.account;
    if (account != null) {
      account.subscription ??= '';
      var subscription = account.subscription;
      var pos = subscription?.indexOf(tsCode);
      if (pos != -1) {
        return true;
      }
    }
    return false;
  }

  /// 自选股中的当前指示器，用于在自选股中遍历，修改会同时修改指定股票
  int get currentIndex {
    return _currentIndex;
  }

  set currentIndex(int val) {
    if (shares.isNotEmpty) {
      if (val > -1 && val < shares.length) {
        _currentIndex = val;
        _share = shares[_currentIndex];
      } else if (val <= -1) {
        _currentIndex = 0;
        _share = shares[_currentIndex];
      } else {
        _currentIndex = shares.length - 1;
        _share = shares[_currentIndex];
      }
    } else {
      _currentIndex = -1;
      _share = null;
    }
  }

  /// 向服务器注册账号，成功后更新本地账号记录
  /// @param url
  /// @param params
  Future<StockAccount?> regist(String url, dynamic params) async {
    var response = await webClient.send(url, params);
    if (response != null) {
      var data = response.message;
      if (data != null) {
        if (TypeUtil.isString(data)) {
          error = data;
        } else {
          var account = await stockAccountService.getOrRegist(data);
          account = account;
          return account;
        }
      }
    }
    return null;
  }

  Future<StockUser> login(String url, dynamic params) async {
    var response = await webClient.send(url, params);
    if (response != null) {
      var data = response.message;
      if (data != null) {
        if (TypeUtil.isString(data)) {
          error = data;
        } else {
          var user = data['user'];
          var token = data['token'];
          if (user != null) {
            user['lastLoginDate'] = DateUtil.currentDate();
            account = await stockAccountService.getOrRegist(user);
            loginStatus = true;
            token = token;
          }
        }
      }
    }

    return this;
  }

  Future<StockUser> logout(String url) async {
    var response = await webClient.send(url, {});
    if (response) {
      account = null;
      loginStatus = false;
      token = '';
    }

    return this;
  }

  bool isAdmin() {
    if (account != null && account?.roles != null) {
      var pos = account?.roles?.indexOf('admin');
      if (pos! > -1) {
        return true;
      }
    }

    return false;
  }
}

var stockUser = StockUser();
