import 'package:colla_chat/pages/loading.dart';
import 'package:colla_chat/pages/stock/login/remote_login.dart';
import 'package:flutter/material.dart';
import 'package:fluro/fluro.dart';

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

// 首页
Handler indexHandler = Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
  return const Loading(
    title: '',
  );
});
