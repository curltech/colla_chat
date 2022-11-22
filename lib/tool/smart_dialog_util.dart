import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:toast/toast.dart';

class SmartDialogUtil {
  static Future<T?> popDialog<T>({
    required Widget Function(BuildContext) builder,
    SmartDialogController? controller,
    AlignmentGeometry? alignment,
    bool? clickMaskDismiss,
    bool? usePenetrate,
    bool? useAnimation,
    SmartAnimationType? animationType,
    List<SmartNonAnimationType>? nonAnimationTypes,
    Widget Function(AnimationController, Widget, AnimationParam)?
        animationBuilder,
    Duration? animationTime,
    Color? maskColor,
    Widget? maskWidget,
    bool? debounce,
    void Function()? onDismiss,
    void Function()? onMask,
    Duration? displayTime,
    String? tag,
    bool? backDismiss,
    bool? keepSingle,
    bool? permanent,
    bool? useSystem,
    bool? bindPage,
    BuildContext? bindWidget,
    Rect? ignoreArea,
  }) async {
    return SmartDialog.show(builder: builder);
  }

  static Widget defaultLoadingWidget() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Opacity(
        opacity: 0.6,
        child: ImageUtil.buildImageWidget(
            fit: BoxFit.fill, image: 'assets/bg/login-bg-wd-1.jpg'),
      ),
    );
  }

  static AnimationController buildController({required TickerProvider vsync}) {
    AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: vsync,
    );
    controller.forward();
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.reset();
        controller.forward();
      }
    });
    return controller;
  }

  Widget buildLoadingOne({required TickerProvider vsync}) {
    return Stack(alignment: Alignment.center, children: [
      RotationTransition(
        alignment: Alignment.center,
        turns: buildController(vsync: vsync),
        child: Image.network(
          'https://raw.githubusercontent.com/xdd666t/MyData/master/pic/flutter/blog/20211101174606.png',
          height: 110,
          width: 110,
        ),
      ),
      Image.network(
        'https://raw.githubusercontent.com/xdd666t/MyData/master/pic/flutter/blog/20211101181404.png',
        height: 60,
        width: 60,
      ),
    ]);
  }

  Widget buildLoadingTwo({required TickerProvider vsync}) {
    return Stack(alignment: Alignment.center, children: [
      Image.network(
        'https://raw.githubusercontent.com/xdd666t/MyData/master/pic/flutter/blog/20211101162946.png',
        height: 50,
        width: 50,
      ),
      RotationTransition(
        alignment: Alignment.center,
        turns: buildController(vsync: vsync),
        child: Image.network(
          'https://raw.githubusercontent.com/xdd666t/MyData/master/pic/flutter/blog/20211101173708.png',
          height: 80,
          width: 80,
        ),
      ),
    ]);
  }

  Widget buildLoadingThree({required TickerProvider vsync}) {
    return Center(
      child: Container(
        height: 120,
        width: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.center,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          RotationTransition(
            alignment: Alignment.center,
            turns: buildController(vsync: vsync),
            child: Image.network(
              'https://raw.githubusercontent.com/xdd666t/MyData/master/pic/flutter/blog/20211101163010.png',
              height: 50,
              width: 50,
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 20),
            child: Text('loading...'),
          ),
        ]),
      ),
    );
  }

  /// loading框
  static loadingShow({String tip = 'Loading, please waiting...'}) {
    SmartDialog.showLoading(
        msg: tip,
        maskColor: appDataProvider.themeData.colorScheme.primary,
        maskWidget: defaultLoadingWidget(),
        usePenetrate: true,
        animationType: SmartAnimationType.scale,
        builder: (BuildContext context) => Container());
  }

  /// 关闭loading框
  static loadingHide() {
    SmartDialog.dismiss();
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
            Text(title),
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
      content: Text(content),
      backgroundColor: Colors.red,
    ));
  }

  /// 底部延时警告
  static warn(BuildContext context, {String content = 'Warning'}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(content),
      backgroundColor: Colors.amber,
    ));
  }

  /// 底部延时提示
  static info(BuildContext context, {String content = 'Information'}) {
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
    SmartDialog.showToast(msg, displayTime: Duration(seconds: duration));
  }
}
