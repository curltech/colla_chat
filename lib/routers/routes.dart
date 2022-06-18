import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

import './router_handler.dart';

class Application {
  static String remoteLogin = '/remote_login';
  static String p2pLogin = '/';
  static String index = '/index';

  static final Application _instance = Application();
  static bool initState = false;
  final FluroRouter _router = FluroRouter();

  static Application get instance {
    if (!initState) {
      configureRoutes();
      initState = true;
    }
    return _instance;
  }

  static FluroRouter get router {
    return instance._router;
  }

  static void configureRoutes() {
    var router = _instance._router;
    router.notFoundHandler = Handler(
        handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
      return;
    });

    // 路由页面配置
    router.define(remoteLogin, handler: remoteLoginHandler);
    router.define(p2pLogin, handler: p2pLoginHandler);
    router.define(index, handler: indexHandler);
  }
}
