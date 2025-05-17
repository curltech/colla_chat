import 'package:colla_chat/pages/pip/android_floating_pip_widget.dart';
import 'package:colla_chat/pages/pip/inapp_pip_player_widget.dart';
import 'package:colla_chat/pages/pip/mobile_fl_pip_widget.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

/// 画中画功能主页面，带有路由回调函数
class MobilePipWidget extends StatelessWidget with TileDataMixin {
  MobilePipWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'mobile_pip';

  @override
  IconData get iconData => Icons.picture_in_picture;

  @override
  String get title => 'Mobile pip';

  final Widget enabled = Icon(Icons.access_alarm_rounded);

  late final AndroidFloatingPipWidget androidFloatingPipWidget =
      AndroidFloatingPipWidget(
    disabled: Center(child: Text('AndroidFloatingPip')),
    enabled: enabled,
  );
  late final InAppPipPlayerWidget inAppPipPlayerWidget = InAppPipPlayerWidget(
    title: 'InAppPipPlayer',
    disabled: Center(child: Text('InAppPipPlayer')),
    enabled: enabled,
  );

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        title: title,
        rightWidgets: [
          IconButton(
              onPressed: () {
                mobileFlPipEnabledWidget.enabled.value = enabled;
                mobileFlPipController.enable();
              },
              icon: Icon(Icons.picture_in_picture)),
          IconButton(
              onPressed: () {
                androidFloatingPipWidget.androidFloatingPipController.enable();
              },
              icon: Icon(Icons.picture_in_picture_alt_outlined)),
          IconButton(
              onPressed: () {
                mobileFlPipEnabledWidget.enabled.value = enabled;
                mobileFlPipController.enable();
              },
              icon: Icon(Icons.picture_in_picture_outlined))
        ],
        child: Column(
          children: [androidFloatingPipWidget, inAppPipPlayerWidget],
        ));
  }
}
