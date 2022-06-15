import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

import './application.dart';
import './routes.dart';
import '../pages/chat/login/loading.dart';

class NavigatorUtil {
  static late BuildContext context;
  // 返回
  static void goBack(BuildContext context) {
    /// 其实这边调用的是
    Navigator.pop(context);
    Application.router.pop(context);
  }

  // 带参数的返回
  static void goBackWithParams(BuildContext context, result) {
    Navigator.pop(context, result);
  }

  // 路由返回指定页面
  static void goBackUrl(BuildContext context, String title) {
    Navigator.popAndPushNamed(context, title);
  }

  // 跳转到主页面
  static void goIndexPage(BuildContext context) {
    Application.router.navigateTo(context, Routes.index, replace: true);
  }

  /// 跳转到 转场动画 页面 ， 这边只展示 inFromLeft ，剩下的自己去尝试下，
  /// 框架自带的有 native，nativeModal，inFromLeft，inFromRight，inFromBottom，fadeIn，custom
  static Future jump(BuildContext context, String title) {
    return Application.router
        .navigateTo(context, title, transition: TransitionType.inFromRight);

    /// 指定了 转场动画
  }

  /// 框架自带的有 native，nativeModal，inFromLeft，inFromRight，inFromBottom，fadeIn，custom
  static Future jumpLeft(BuildContext context, String title) {
    return Application.router
        .navigateTo(context, title, transition: TransitionType.inFromLeft);

    /// 指定了 转场动画
  }

  static Future jumpRemove(BuildContext context) {
    return Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => Loading(
            title: '',
          ),
        ),
        (route) => route == null);
  }

  /// 自定义 转场动画
  static Future gotransitionCustomDemoPage(BuildContext context, String title) {
    var transition = (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation, Widget child) {
      return ScaleTransition(
          scale: animation,
          child: RotationTransition(
            turns: animation,
            child: child,
          ));
    };

    return Application.router.navigateTo(context, title,
        transition: TransitionType.custom,

        /// 指定是自定义动画
        transitionBuilder: transition,

        /// 自定义的动画
        transitionDuration: const Duration(milliseconds: 600));

    /// 时间
  }

  /// 使用 IOS 的 Cupertino 的转场动画，这个是修改了源码的 转场动画
  /// Fluro本身不带，但是 Flutter自带
  static Future gotransitionCupertinoDemoPage(
      BuildContext context, String title) {
    return Application.router
        .navigateTo(context, title, transition: TransitionType.cupertino);
  }

  // 跳转到主页面IndexPage并删除当前路由
  static void goToIndexRemovePage(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => Loading(
            title: '',
          ),
        ),
        (route) => route == null);
  }

  // 跳转到登录页并删除当前路由
  static void goToLoginRemovePage(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => Loading(
            title: '',
          ),
        ),
        (route) => route == null);
  }
}
