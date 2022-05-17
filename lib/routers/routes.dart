import 'package:flutter/material.dart';
import 'package:fluro/fluro.dart';
import './router_handler.dart';

class Routes {
  static String loading = '/';
  static String login = '/login';
  static String index = '/index';

  static void configureRoutes(FluroRouter router) {
    router.notFoundHandler = Handler(
        handlerFunc: (BuildContext? context, Map<String, List<String>> params) {

      return;
    });

    // 路由页面配置
    router.define(loading, handler: loadingHandler);
    router.define(login, handler: loginHandler);
    router.define(index, handler: indexHandler);
  }
}
