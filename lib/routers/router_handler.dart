import 'package:colla_chat/pages/loading.dart';
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
Handler loginHandler = Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
  return const Loading(
    title: '',
  );
});

// 首页
Handler indexHandler = Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
  return const Loading(
    title: '',
  );
});
