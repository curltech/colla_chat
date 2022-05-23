import 'package:flutter/material.dart';
import 'package:fluro/fluro.dart';
import './router_handler.dart';

class Routes {
  static String loading = '/';
  static String remoteLogin = '/remote_login';
  static String p2pLogin = '/p2p_login';
  static String index = '/index';

  static void configureRoutes(FluroRouter router) {
    router.notFoundHandler = Handler(
        handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
      return;
    });

    // 路由页面配置
    router.define(loading, handler: loadingHandler);
    router.define(remoteLogin, handler: remoteLoginHandler);
    router.define(p2pLogin, handler: p2pLoginHandler);
    router.define(index, handler: indexHandler);
  }
}
