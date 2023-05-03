import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/login/loading.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/material.dart';

class DialogUtil {
  static ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>
      showMaterialBanner(
    BuildContext context, {
    Key? key,
    required Widget content,
    TextStyle? contentTextStyle,
    List<Widget>? actions,
    double? elevation,
    Widget? leading,
    Color? backgroundColor,
    Color? surfaceTintColor,
    Color? shadowColor,
    Color? dividerColor,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? leadingPadding,
    bool forceActionsBelow = false,
    OverflowBarAlignment overflowAlignment = OverflowBarAlignment.end,
    Animation<double>? animation,
    void Function()? onVisible,
  }) {
    return ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        key: key,
        content: content,
        contentTextStyle: contentTextStyle,
        elevation: elevation,
        leading: leading,
        backgroundColor: backgroundColor,
        surfaceTintColor: surfaceTintColor,
        shadowColor: shadowColor,
        dividerColor: dividerColor,
        padding: padding,
        leadingPadding: leadingPadding,
        forceActionsBelow: forceActionsBelow = false,
        overflowAlignment: overflowAlignment = OverflowBarAlignment.end,
        animation: animation,
        onVisible: onVisible,
        actions: actions ??
            <Widget>[
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                },
                child: CommonAutoSizeText(AppLocalizations.t('Dismiss')),
              ),
            ],
      ),
    );
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    BuildContext context, {
    Key? key,
    required Widget content,
    Color? backgroundColor,
    double? elevation,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double? width,
    ShapeBorder? shape,
    SnackBarBehavior? behavior,
    SnackBarAction? action,
    bool? showCloseIcon,
    Color? closeIconColor,
    Duration duration = const Duration(milliseconds: 4000),
    Animation<double>? animation,
    void Function()? onVisible,
    DismissDirection dismissDirection = DismissDirection.down,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: key,
        content: content,
        backgroundColor: backgroundColor,
        elevation: elevation,
        margin: margin,
        padding: padding,
        width: width,
        shape: shape,
        behavior: behavior,
        action: action,
        showCloseIcon: showCloseIcon,
        closeIconColor: closeIconColor,
        duration: duration,
        animation: animation,
        onVisible: onVisible,
        dismissDirection: dismissDirection = DismissDirection.down,
        clipBehavior: clipBehavior = Clip.hardEdge,
      ),
    );
  }

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
        return Dialog(
          child: ListView(children: options),
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
          CommonAutoSizeText(
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
          CommonAutoSizeText(
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
    Color? barrierColor,
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

  ///缺省的背景图像
  static Widget defaultLoadingWidget(
      {BuildContext? context, String tip = 'Loading, please waiting...'}) {
    Widget loading = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(
          height: 20,
        ),
        const CircularProgressIndicator(),
        const SizedBox(
          height: 20,
        ),
        CommonAutoSizeText(AppLocalizations.t(tip)),
        const SizedBox(
          height: 20,
        ),
      ],
    );
    loading = Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Opacity(
            opacity: 1.0,
            child: loadingBackgroundImage.currentBackgroundImage(context),
          ),
        ),
        Center(child: loading),
      ],
    );
    return loading;
  }

  /// loading框
  static loadingShow(BuildContext context,
      {String tip = 'Loading, please waiting...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          child: defaultLoadingWidget(context: context, tip: tip),
        );
      },
    );
  }

  /// 关闭loading框
  static loadingHide(BuildContext context) {
    Navigator.of(context).pop(true);
  }

  ///返回为true，代表按的确认
  static Future<bool?> confirm(BuildContext context,
      {Icon? icon, String title = 'Confirm', String content = ''}) {
    icon = icon ?? const Icon(Icons.privacy_tip_outlined);
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
            child: Column(
          children: [
            Row(children: <Widget>[
              icon!,
              CommonAutoSizeText(AppLocalizations.t(title)),
            ]),
            CommonAutoSizeText(content),
            ButtonBar(
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: CommonAutoSizeText(AppLocalizations.t('Cancel')),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: CommonAutoSizeText(AppLocalizations.t('Ok')),
                ),
              ],
            ),
          ],
        ));
      },
    );
  }

  static Future<String?> showTextFormField(BuildContext context,
      {Icon? icon, String title = 'Input', String content = ''}) {
    ButtonStyle style = StyleUtil.buildButtonStyle();
    ButtonStyle mainStyle = StyleUtil.buildButtonStyle(
        backgroundColor: myself.primary, elevation: 10.0);
    icon = icon ?? const Icon(Icons.privacy_tip_outlined);
    var size = MediaQuery.of(context).size;
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        TextEditingController controller = TextEditingController();
        return Center(
            child: SizedBox(
                width: size.width * dialogSizeIndex,
                height: size.height * dialogSizeIndex,
                child: Card(
                    elevation: 0,
                    shape: const ContinuousRectangleBorder(),
                    child: Column(children: [
                      AppBarWidget.buildTitleBar(
                          title: CommonAutoSizeText(
                        AppLocalizations.t(title),
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      )),
                      Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(10),
                          child: Column(children: [
                            CommonAutoSizeTextFormField(
                              keyboardType: TextInputType.text,
                              labelText: content,
                              controller: controller,
                            ),
                            ButtonBar(
                              children: [
                                TextButton(
                                  style: style,
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: CommonAutoSizeText(
                                      AppLocalizations.t('Cancel')),
                                ),
                                TextButton(
                                  style: mainStyle,
                                  onPressed: () {
                                    Navigator.of(context).pop(controller.text);
                                  },
                                  child: CommonAutoSizeText(
                                      AppLocalizations.t('Ok')),
                                ),
                              ],
                            ),
                          ])),
                    ]))));
      },
    );
  }

  /// 模态警告
  static Future<bool?> alert(BuildContext context,
      {Icon? icon, String title = 'Warning', String content = ''}) {
    return confirm(context,
        title: title, content: content, icon: const Icon(Icons.info));
  }

  /// 模态提示
  static Future<bool?> prompt(BuildContext context,
      {Icon? icon, String title = 'Prompt', String content = ''}) {
    return confirm(context,
        title: title, content: content, icon: const Icon(Icons.info));
  }

  /// 模态提示错误
  static Future<bool?> fault(BuildContext context,
      {Icon? icon, String title = 'Fault', String content = ''}) {
    return confirm(context,
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
      content: CommonAutoSizeText(AppLocalizations.t(content)),
      backgroundColor: Colors.red,
    ));
  }

  /// 底部延时警告
  static warn(BuildContext context, {String content = 'Warning'}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: CommonAutoSizeText(AppLocalizations.t(content)),
      backgroundColor: Colors.amber,
    ));
  }

  /// 底部延时提示
  static info(BuildContext context, {String content = 'Information'}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: CommonAutoSizeText(AppLocalizations.t(content)),
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

// static showToast(String msg, {int duration = 1, int gravity = 0}) {
//   Toast.show(AppLocalizations.t(msg), duration: duration, gravity: gravity);
// }
}
