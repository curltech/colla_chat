import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/login/loading.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/button_widget.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/style/platform_style_widget.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

class DialogUtil {
  static ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>
      showMaterialBanner({
    Key? key,
    BuildContext? context,
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
    context ??= appDataProvider.context!;
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
                  ScaffoldMessenger.of(context!).hideCurrentMaterialBanner();
                },
                child: AutoSizeText(AppLocalizations.t('Dismiss')),
              ),
            ],
      ),
    );
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
      showSnackBar({
    Key? key,
    BuildContext? context,
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
    context ??= appDataProvider.context!;
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
    BuildContext? context,
    required Widget? title,
    required List<Option> items,
  }) async {
    context ??= appDataProvider.context!;
    List<SimpleDialogOption> options = [];
    for (var item in items) {
      SimpleDialogOption option = _simpleDialogOption(
          context: context,
          prefix: item.leading,
          label: item.label,
          value: item.value,
          selected: item.selected);
      options.add(option);
    }
    T? value = await show<T>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(children: [
            AppBarWidget(title: title),
            Expanded(child: ListView(children: options).asStyle())
          ]),
        );
      },
    );

    return value;
  }

  static SimpleDialogOption _simpleDialogOption<T>({
    BuildContext? context,
    required String label,
    required T value,
    required bool selected,
    Widget? prefix,
  }) {
    context ??= appDataProvider.context!;
    TextStyle style = TextStyle(color: myself.primary);
    List<Widget> children = [];
    if (prefix != null) {
      children.add(prefix);
      children.add(const SizedBox(
        width: 10.0,
      ));
    }
    children.add(AutoSizeText(
      label,
      style: selected ? style : null,
    ));
    children.add(
      const Spacer(),
    );
    children.add(selected
        ? Icon(
            Icons.check,
            color: myself.primary,
          )
        : nilBox);
    return SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context!, value);
        },
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.end, children: children));
  }

  ///利用Option产生的SelectMenu
  static Future<T?> showSelectMenu<T>({
    BuildContext? context,
    required List<Option> items,
  }) async {
    context ??= appDataProvider.context!;
    List<PopupMenuEntry<T>> options = [];
    T? initialValue;
    for (var item in items) {
      PopupMenuEntry<T> option = _popupMenuEntry<T>(
          context: context,
          label: item.label,
          value: item.value,
          selected: item.selected);
      options.add(option);
      if (item.selected) {
        initialValue = item.value;
      }
    }
    T? value = await showMenu<T>(
        context: context,
        color: Colors.grey.withAlpha(255 * 0.8.toInt()),
        position: const RelativeRect.fromLTRB(0, 0, 0, 0),
        initialValue: initialValue,
        items: options);

    return value;
  }

  static PopupMenuEntry<T> _popupMenuEntry<T>({
    BuildContext? context,
    required String label,
    required T value,
    required bool selected,
  }) {
    context ??= appDataProvider.context!;
    TextStyle style = TextStyle(color: myself.primary);
    return PopupMenuItem(
        value: value,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          AutoSizeText(
            AppLocalizations.t(label),
            style: selected ? style : null,
          ),
          const Spacer(),
          selected ? const Icon(Icons.check) : nilBox
        ]));
  }

  ///带标题的对话框
  static Future<T?> show<T>({
    BuildContext? context,
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
    context ??= appDataProvider.context!;
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
    context ??= appDataProvider.context!;
    Widget loading = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(
          height: 20,
        ),
        SizedBox(
            height: 80,
            width: 80,
            child: InkWell(
                child: LoadingIndicator(
                  indicatorType: Indicator.ballRotateChase,
                  colors: [
                    myself.primary,
                  ],
                ),
                onTap: () {
                  loadingHide(context: context);
                })),
        const SizedBox(
          height: 20,
        ),
        AutoSizeText(AppLocalizations.t(tip)),
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
            opacity: 0.8,
            child: backgroundImages.currentBackgroundImage(context),
          ),
        ),
        Center(child: loading),
      ],
    );
    return loading;
  }

  /// loading框
  static Future<bool?> loadingShow(
      {BuildContext? context,
      String tip = 'Loading, please waiting...'}) async {
    context ??= appDataProvider.context!;
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: defaultLoadingWidget(context: context, tip: tip),
        );
      },
    );
  }

  /// 关闭loading框
  static loadingHide({BuildContext? context}) {
    context ??= appDataProvider.context!;
    try {
      Navigator.of(context).pop(true);
    } catch (e) {
      logger.e('pop failure:$e');
    }
  }

  ///返回为true，代表按的确认
  static Future<bool?> confirm(
      {BuildContext? context,
      Icon? icon,
      String title = 'Confirm',
      String content = '',
      String cancelLabel = 'Cancel',
      String okLabel = 'Ok'}) async {
    context ??= appDataProvider.context!;
    ButtonStyle style = StyleUtil.buildButtonStyle();
    ButtonStyle mainStyle = StyleUtil.buildButtonStyle(
        backgroundColor: myself.primary, elevation: 10.0);
    bool? result;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: icon ?? Icon(Icons.confirmation_num_outlined),
          title: AppBarWidget(
              isAppBar: false,
              title: Text(
                AppLocalizations.t(title),
                style: const TextStyle(color: Colors.white),
              )),
          titlePadding: EdgeInsets.zero,
          content: SizedBox(
              width: appDataProvider.totalSize.width * 0.8,
              height: appDataProvider.totalSize.height * 0.5,
              child: Center(
                  child: AutoSizeText(
                      style: TextStyle(color: Colors.white),
                      softWrap: true,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      AppLocalizations.t(content)))),
          actions: <Widget>[
            TextButton(
              style: style,
              onPressed: () {
                result = false;
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.t(cancelLabel)),
            ),
            TextButton(
              style: mainStyle,
              onPressed: () {
                result = true;
                Navigator.of(context).pop(true);
              },
              child: Text(AppLocalizations.t(okLabel)),
            ),
          ],
        );
      },
    );

    return result;
  }

  static Future<String?> showTextFormField(
      {BuildContext? context,
      Icon? icon,
      String title = '',
      String content = '',
      String? tip}) async {
    context ??= appDataProvider.context!;
    ButtonStyle style = StyleUtil.buildButtonStyle();
    ButtonStyle mainStyle = StyleUtil.buildButtonStyle(
        backgroundColor: myself.primary, elevation: 10.0);
    String? result;
    TextEditingController controller = TextEditingController();
    controller.text = tip ?? '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: AppBarWidget(
              isAppBar: false,
              title: Text(
                AppLocalizations.t(title),
                style: const TextStyle(color: Colors.white),
              )),
          titlePadding: EdgeInsets.zero,
          content: TextFormField(
            keyboardType: TextInputType.text,
            decoration: buildInputDecoration(
              labelText: AppLocalizations.t(content),
            ),
            controller: controller,
          ),
          actions: <Widget>[
            TextButton(
              style: style,
              onPressed: () {
                result = null;
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.t('Cancel')),
            ),
            TextButton(
              style: mainStyle,
              onPressed: () {
                result = controller.text;
                Navigator.of(context).pop(result);
              },
              child: Text(AppLocalizations.t('Ok')),
            ),
          ],
        );
      },
    );
    return result;
  }

  /// 模态警告
  static Future<bool?> alert(
      {BuildContext? context,
      Icon? icon,
      String title = 'Warning',
      String content = ''}) async {
    context ??= appDataProvider.context!;
    return await confirm(
        context: context,
        title: title,
        content: content,
        icon: const Icon(
          Icons.warning,
          color: Colors.yellow,
        ));
  }

  /// 模态提示
  static Future<bool?> prompt(
      {BuildContext? context,
      Icon? icon,
      String title = 'Prompt',
      String content = ''}) async {
    context ??= appDataProvider.context!;
    return await confirm(
        context: context,
        title: title,
        content: content,
        icon: const Icon(
          Icons.info,
          color: Colors.green,
        ));
  }

  /// 模态提示错误
  static Future<bool?> fault(
      {BuildContext? context,
      Icon? icon,
      String title = 'Fault',
      String content = ''}) async {
    context ??= appDataProvider.context!;
    return await confirm(
        context: context,
        title: title,
        content: content,
        icon: const Icon(
          Icons.error,
          color: Colors.red,
        ));
  }

  /// 底部延时提示错误
  static error({BuildContext? context, String content = 'Error'}) {
    context ??= appDataProvider.context!;
    ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar(
      icon: Icon(
        Icons.error_outline_outlined,
        color: Colors.red,
      ),
      content: AutoSizeText(
          style: TextStyle(color: Colors.white),
          softWrap: true,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          AppLocalizations.t(content)),
    ));
  }

  /// 底部延时警告
  static warn({BuildContext? context, String content = 'Warning'}) {
    context ??= appDataProvider.context!;
    ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar(
      icon: Icon(
        Icons.warning_amber,
        color: Colors.amber,
      ),
      content: AutoSizeText(
          style: TextStyle(color: Colors.white),
          softWrap: true,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          AppLocalizations.t(content)),
    ));
  }

  /// 底部延时提示
  static info({BuildContext? context, String content = 'Information'}) {
    context ??= appDataProvider.context!;
    ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar(
        icon: Icon(
          Icons.info_outline,
          color: Colors.green,
        ),
        content: AutoSizeText(
            style: TextStyle(color: Colors.white),
            softWrap: true,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            AppLocalizations.t(content))));
  }

  static SnackBar _buildSnackBar(
      {required Widget icon, required Widget content}) {
    return SnackBar(
      padding: EdgeInsets.all(15.0),
      content: Padding(
          padding: EdgeInsets.all(15.0),
          child: Row(children: [
            icon,
            SizedBox(
              width: 15.0,
            ),
            Expanded(child: content)
          ])).asStyle(),
      backgroundColor: Colors.white.withAlpha(0),
    );
  }

  /// 底部弹出半屏对话框，内部调用Navigator.of(context).pop(result)关闭
  /// result返回
  static Future<T?> popModalBottomSheet<T>(
      {BuildContext? context, required Widget Function(BuildContext) builder}) {
    context ??= appDataProvider.context!;
    Widget child = builder(context).asStyle();
    return showModalBottomSheet<T>(
        context: context,
        backgroundColor: Colors.white.withAlpha(0),
        builder: (BuildContext context) {
          return child;
        });
  }

  /// 底部弹出全屏，返回的controller可以关闭
  static PersistentBottomSheetController popBottomSheet(
      {BuildContext? context, required Widget Function(BuildContext) builder}) {
    context ??= appDataProvider.context!;
    Widget child = builder(context).asStyle();
    return showBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return child;
        });
  }

  static Future<T?> showFullScreen<T>({
    BuildContext? context,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
    Color? backgroundColor,
    Duration insetAnimationDuration = Duration.zero,
    Curve insetAnimationCurve = Curves.decelerate,
    Widget? child,
  }) async {
    return await show<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        useSafeArea: useSafeArea,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
        anchorPoint: anchorPoint,
        builder: (BuildContext context) {
          return Dialog.fullscreen(
              backgroundColor: backgroundColor,
              insetAnimationDuration: insetAnimationDuration,
              insetAnimationCurve: insetAnimationCurve,
              child: child);
        });
  }
}
