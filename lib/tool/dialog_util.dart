import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';

class DialogUtil {
  ///利用Option产生的SelectDialog
  static Future<T?> showSelectDialog<T>({
    required BuildContext context,
    required Widget? title,
    required List<Option> items,
  }) async {
    List<SimpleDialogOption> options = [];
    for (var item in items) {
      SimpleDialogOption option = _simpleDialogOption(
          context: context,
          label: item.label,
          value: item.value,
          checked: item.checked);
      options.add(option);
    }
    T? value = await show<T>(
      context: context,
      title: title,
      builder: (BuildContext context) {
        return SimpleDialog(
          children: options,
        );
      },
    );

    return value;
  }

  static SimpleDialogOption _simpleDialogOption<T>({
    required BuildContext context,
    required String label,
    required T value,
    required bool checked,
  }) {
    TextStyle style = TextStyle(color: myself.primary);
    return SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, value);
        },
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            label,
            style: checked ? style : null,
          ),
          const Spacer(),
          checked ? const Icon(Icons.check) : Container()
        ]));
  }

  ///利用Option产生的SelectMenu
  static Future<T?> showSelectMenu<T>({
    required BuildContext context,
    required List<Option> items,
  }) async {
    List<PopupMenuEntry<T>> options = [];
    T? initialValue;
    for (var item in items) {
      PopupMenuEntry<T> option = _popupMenuEntry<T>(
          context: context,
          label: item.label,
          value: item.value,
          checked: item.checked);
      options.add(option);
      if (item.checked) {
        initialValue = item.value;
      }
    }
    T? value = await showMenu<T>(
        context: context,
        color: Colors.grey.withOpacity(0.8),
        position: const RelativeRect.fromLTRB(0, 0, 0, 0),
        initialValue: initialValue,
        items: options);

    return value;
  }

  static PopupMenuEntry<T> _popupMenuEntry<T>({
    required BuildContext context,
    required String label,
    required T value,
    required bool checked,
  }) {
    TextStyle style = TextStyle(color: myself.primary);
    return PopupMenuItem(
        value: value,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            AppLocalizations.t(label),
            style: checked ? style : null,
          ),
          const Spacer(),
          checked ? const Icon(Icons.check) : Container()
        ]));
  }

  ///带标题的对话框
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    Widget? title,
    bool barrierDismissible = true,
    Color? barrierColor = Colors.black54,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
  }) async {
    Widget child = builder(context);
    if (title != null) {
      child = Column(children: [
        title,
        Expanded(child: child),
      ]);
    }
    T? value = await showDialog<T>(
      context: context,
      builder: (BuildContext context) {
        return child;
      },
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
    );

    return value;
  }

  /// loading框
  static loadingShow(BuildContext context,
      {String tip = 'Loading, please waiting...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircularProgressIndicator(),
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Text(AppLocalizations.t(tip)),
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
      {Icon? icon, String title = 'Warning', String content = ''}) {
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
            Text(AppLocalizations.t(title)),
          ]),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.t('Cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(AppLocalizations.t('Ok')),
            ),
          ],
        );
      },
    );
  }

  /// 模态提示
  static Future<bool?> prompt(BuildContext context,
      {Icon? icon, String title = 'Prompt', String content = ''}) {
    return alert(context,
        title: title, content: content, icon: const Icon(Icons.info));
  }

  /// 模态提示错误
  static Future<bool?> fault(BuildContext context,
      {Icon? icon, String title = 'Fault', String content = ''}) {
    return alert(context,
        title: title,
        content: content,
        icon: const Icon(
          Icons.error,
          color: Colors.red,
        ));
  }

  /// 底部延时提示错误
  static error(BuildContext context, {String content = 'Error'}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.t(content)),
      backgroundColor: Colors.red,
    ));
  }

  /// 底部延时警告
  static warn(BuildContext context, {String content = 'Warning'}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.t(content)),
      backgroundColor: Colors.amber,
    ));
  }

  /// 底部延时提示
  static info(BuildContext context, {String content = 'Information'}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.t(content)),
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
    Toast.show(AppLocalizations.t(msg), duration: duration, gravity: gravity);
  }
}
