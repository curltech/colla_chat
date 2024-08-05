import 'package:colla_chat/pages/index/index_view.dart';
import 'package:colla_chat/pages/login/p2p_login.dart';
import 'package:colla_chat/pages/stock/login/remote_login.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

Handler remoteLoginHandler = Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
  return const RemoteLogin();
});

// p2p登录页面
final p2pLogin = P2pLogin();
Handler p2pLoginHandler = Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
  return p2pLogin;
});

// 首页
final indexView = IndexView();
Handler indexHandler = Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
  return indexView;
});
