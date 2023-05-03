import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class SmartDialogUtil {
  ///带标题的对话框
  static Future<T?> show<T>({
    BuildContext? context,
    Widget? title,
    required Widget Function(BuildContext?) builder,
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
    Widget child = builder(context);
    if (title != null) {
      child = Column(children: [
        title,
        Expanded(child: child),
      ]);
    }
    maskWidget =
        maskWidget ?? DialogUtil.defaultLoadingWidget(context: context);
    return SmartDialog.show<T>(
      builder: (BuildContext context) {
        return child;
      },
      controller: controller,
      alignment: alignment,
      clickMaskDismiss: clickMaskDismiss,
      usePenetrate: usePenetrate,
      useAnimation: useAnimation,
      animationType: animationType,
      nonAnimationTypes: nonAnimationTypes,
      animationBuilder: animationBuilder,
      animationTime: animationTime,
      maskColor: maskColor,
      maskWidget: maskWidget,
      debounce: debounce,
      onDismiss: onDismiss,
      onMask: onMask,
      displayTime: displayTime,
      tag: tag,
      backDismiss: backDismiss,
      keepSingle: keepSingle,
      permanent: permanent,
      useSystem: useSystem,
      bindPage: bindPage,
      bindWidget: bindWidget,
      ignoreArea: ignoreArea,
    );
  }

  ///动画控制器
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

  ///二个转动的图像Loading
  Widget buildRotationLoading(
      {required TickerProvider vsync, Widget? rotation, Widget? center}) {
    center = center ?? myself.avatarImage;
    rotation = rotation ?? AppImage.mdAppImage;
    return Stack(alignment: Alignment.center, children: [
      RotationTransition(
        alignment: Alignment.center,
        turns: buildController(vsync: vsync),
        child: rotation,
      ),
      center!,
    ]);
  }

  ///一个转动的图像Loading
  Widget buildImageLoading({
    required TickerProvider vsync,
    Widget? rotation,
  }) {
    rotation = rotation ?? myself.avatarImage;
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
            child: rotation,
          ),
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: CommonAutoSizeText(AppLocalizations.t('Loading...')),
          ),
        ]),
      ),
    );
  }

  static Future<T?> showAttach<T>({
    required BuildContext? targetContext,
    required Widget Function(BuildContext) builder,
    Widget Function(Offset, Size, Offset, Size)? replaceBuilder,
    SmartDialogController? controller,
    Offset Function(Offset, Size)? targetBuilder,
    AlignmentGeometry? alignment,
    bool? clickMaskDismiss,
    SmartAnimationType? animationType,
    List<SmartNonAnimationType>? nonAnimationTypes,
    Widget Function(AnimationController, Widget, AnimationParam)?
        animationBuilder,
    Offset Function(Size)? scalePointBuilder,
    bool? usePenetrate,
    bool? useAnimation,
    Duration? animationTime,
    Color? maskColor,
    Widget? maskWidget,
    Rect? maskIgnoreArea,
    void Function()? onMask,
    bool? debounce,
    Positioned Function(Offset, Size)? highlightBuilder,
    void Function()? onDismiss,
    Duration? displayTime,
    String? tag,
    bool? backDismiss,
    bool? keepSingle,
    bool? permanent,
    bool? useSystem,
    bool? bindPage,
    BuildContext? bindWidget,
  }) async {
    return await SmartDialog.showAttach<T>(
      targetContext: targetContext,
      builder: builder,
      replaceBuilder: replaceBuilder,
      controller: controller,
      targetBuilder: targetBuilder,
      alignment: alignment,
      clickMaskDismiss: clickMaskDismiss,
      animationType: animationType,
      nonAnimationTypes: nonAnimationTypes,
      animationBuilder: animationBuilder,
      scalePointBuilder: scalePointBuilder,
      usePenetrate: usePenetrate,
      useAnimation: useAnimation,
      animationTime: animationTime,
      maskColor: maskColor,
      maskWidget: maskWidget,
      maskIgnoreArea: maskIgnoreArea,
      onMask: onMask,
      debounce: debounce,
      highlightBuilder: highlightBuilder,
      onDismiss: onDismiss,
      displayTime: displayTime,
      tag: tag,
      backDismiss: backDismiss,
      keepSingle: keepSingle,
      permanent: permanent,
      useSystem: useSystem,
      bindPage: bindPage,
      bindWidget: bindWidget,
    );
  }

  /// loading框
  static loadingShow({String tip = 'Loading, please waiting...'}) {
    SmartDialog.showLoading(
      msg: tip,
      maskColor: myself.primary,
      maskWidget: DialogUtil.defaultLoadingWidget(),
      usePenetrate: true,
      animationType: SmartAnimationType.fade,
    );
  }

  /// 关闭loading框
  static loadingHide() {
    SmartDialog.dismiss();
  }

  /// 返回为true，代表按的确认
  /// 模态警告
  static Future<bool?> alert({
    Icon? icon,
    String title = 'Warning',
    String content = '',
    AlignmentGeometry? alignment,
  }) {
    Icon i;
    if (icon == null) {
      i = const Icon(Icons.warning);
    } else {
      i = icon;
    }
    return SmartDialog.show(
      alignment: alignment,
      builder: (context) {
        return AlertDialog(
          title: Row(children: <Widget>[
            i,
            CommonAutoSizeText(title),
          ]),
          content: CommonAutoSizeText(content),
          actions: <Widget>[
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
        );
      },
    );
  }

  /// 模态提示
  static Future<bool?> prompt(BuildContext context,
      {Icon? icon, String title = 'Prompt', String content = ''}) {
    return alert(title: title, content: content, icon: const Icon(Icons.info));
  }

  /// 模态提示错误
  static Future<bool?> fault(BuildContext context,
      {Icon? icon, String title = 'Fault', String content = ''}) {
    return alert(
        title: title,
        content: content,
        icon: const Icon(
          Icons.error,
          color: Colors.red,
        ));
  }

  /// 底部延时提示错误
  static error({String content = 'Error'}) {
    showToast(
      content,
      maskColor: Colors.red,
    );
  }

  /// 底部延时警告
  static warn({String content = 'Warning'}) {
    showToast(
      content,
      maskColor: Colors.amber,
    );
  }

  /// 底部延时提示
  static info({String content = 'Information'}) {
    showToast(
      content,
      maskColor: Colors.green,
    );
  }

  /// 底部弹出半屏对话框，内部调用SmartDialog.dismiss()关闭
  static Future<T?> popModalBottomSheet<T>(BuildContext? context,
      {required Widget Function(BuildContext?) builder}) {
    return show(
      alignment: Alignment.bottomCenter,
      builder: builder,
      context: context,
    );
  }

  /// 底部弹出全屏，返回的controller可以关闭
  static Future<T?> popBottomSheet<T>(BuildContext? context,
      {required Widget Function(BuildContext?) builder}) {
    return show(
      alignment: Alignment.bottomCenter,
      builder: builder,
      context: context,
    );
  }

  static showToast(
    String msg, {
    SmartDialogController? controller,
    Duration? displayTime,
    AlignmentGeometry? alignment,
    bool? clickMaskDismiss,
    SmartAnimationType? animationType,
    Widget Function(AnimationController, Widget, AnimationParam)?
        animationBuilder,
    bool? usePenetrate,
    bool? useAnimation,
    Duration? animationTime,
    Color? maskColor,
    Widget? maskWidget,
    bool? consumeEvent,
    bool? debounce,
    SmartToastType? displayType,
    Widget Function(BuildContext)? builder,
  }) {
    SmartDialog.showToast(
      msg,
      controller: controller,
      displayTime: displayTime,
      alignment: alignment,
      clickMaskDismiss: clickMaskDismiss,
      animationType: animationType,
      animationBuilder: animationBuilder,
      usePenetrate: usePenetrate,
      useAnimation: useAnimation,
      animationTime: animationTime,
      maskColor: maskColor,
      maskWidget: maskWidget,
      consumeEvent: consumeEvent,
      debounce: debounce,
      displayType: displayType,
      builder: builder,
    );
  }
}
