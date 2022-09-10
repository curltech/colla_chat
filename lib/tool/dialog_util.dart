import 'package:flutter/material.dart';
import 'package:toast/toast.dart';

class DialogUtil {
  /// loading框
  static loadingShow(BuildContext context, {String tip = '正在加载，请稍后...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(),
              Padding(
                padding: EdgeInsets.only(top: 26.0),
                child: Text(tip),
              )
            ],
          ),
        );
      },
    );
  }

  /// 关闭loading框
  static loadingHide(BuildContext context) {
    Navigator.of(context).pop(true);
  }

  ///返回为true，代表按的确认
  /// 模态警告
  static Future<bool?> alert(BuildContext context,
      {Icon? icon, String title = '警告', String content = ''}) {
    Icon i;
    if (icon == null) {
      i = const Icon(Icons.warning);
    } else {
      i = icon;
    }
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(children: <Widget>[
            i,
            Text(title),
          ]),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  /// 模态提示
  static Future<bool?> prompt(BuildContext context,
      {Icon? icon, String title = '提示', String content = ''}) {
    return alert(context,
        title: title, content: content, icon: const Icon(Icons.info));
  }

  /// 模态提示错误
  static Future<bool?> fault(BuildContext context,
      {Icon? icon, String title = '错误', String content = ''}) {
    return alert(context,
        title: title, content: content, icon: const Icon(Icons.error));
  }

  /// 底部延时提示错误
  static error(BuildContext context, {String content = '错误'}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(content),
      backgroundColor: Colors.red,
    ));
  }

  /// 底部延时警告
  static warn(BuildContext context, {String content = '警告'}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(content),
      backgroundColor: Colors.amber,
    ));
  }

  /// 底部延时提示
  static info(BuildContext context, {String content = '提示'}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(content),
      backgroundColor: Colors.green,
    ));
  }

  /// 底部弹出半屏对话框，内部调用Navigator.of(context).pop(result)关闭
  /// result返回
  static Future<T?> popModalBottomSheet<T>(BuildContext context,
      {required Widget Function(BuildContext) builder}) {
    return showModalBottomSheet<T>(context: context, builder: builder);
  }

  /// 底部弹出全屏，返回的controller可以关闭
  static PersistentBottomSheetController<T> popBottomSheet<T>(
      BuildContext context,
      {required Widget Function(BuildContext) builder}) {
    return showBottomSheet<T>(context: context, builder: builder);
  }

  static showToast(String msg, {int duration = 1, int gravity = 0}) {
    Toast.show(msg, duration: duration, gravity: gravity);
  }
}
