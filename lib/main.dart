import 'package:colla_chat/pages/loading.dart';
import 'package:colla_chat/routers/application.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CollaChatApp());
}

///应用是一个无态的组件
class CollaChatApp extends StatelessWidget {
  const CollaChatApp({Key? key}) : super(key: key);

  ///widget 的主要工作是提供一个 build() 方法来描述如何根据其他较低级别的 widgets 来显示自己
  @override
  Widget build(BuildContext context) {
    final router = FluroRouter();
    Routes.configureRoutes(router);
    Application.router = router;

    ///创建了一个具有 Material Design 风格的应用
    return MaterialApp(
      title: 'Welcome to CollaChat',
      debugShowCheckedModeBanner: false,

      ///Scaffold 是 Material 库中提供的一个 widget，它提供了默认的导航栏、标题和包含主屏幕 widget 树的 body 属性
      home: Loading(title: 'Flutter Swiper'),
      onGenerateRoute: Application.router.generator,
    );
  }
}
