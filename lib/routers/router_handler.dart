import 'package:colla_chat/pages/loading.dart';
import 'package:colla_chat/pages/stock/login/remote_login.dart';
import 'package:flutter/material.dart';
import 'package:fluro/fluro.dart';
import '../pages/chat/index/mobile_index.dart';
import '../pages/chat/login/p2p_login.dart';

//加载页
var loadingHandler = Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
  return const Loading(
    title: '',
  );
});

// 登录页面
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
Handler mobileIndexHandler = Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
  return const MobileIndex(
    title: '',
  );
});
