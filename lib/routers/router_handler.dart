import 'package:colla_chat/pages/stock/login/remote_login.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

import '../pages/chat/index/index_view.dart';
import '../pages/chat/login/p2p_login.dart';

Handler remoteLoginHandler = Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
  return RemoteLogin();
});

// p2p登录页面
Handler p2pLoginHandler = Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
  return P2pLogin();
});

// 首页
Handler indexHandler = Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
  return const IndexView(
    title: '',
  );
});
