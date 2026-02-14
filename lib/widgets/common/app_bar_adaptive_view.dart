import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/adaptive_container.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppBarAdaptiveView extends StatelessWidget {
  final bool withLeading;
  final Widget? leadingWidget;

  //指定回退路由样式，不指定则系统判断
  final Function? leadingCallBack;
  final String? title;
  final String? helpPath;
  final Widget? titleWidget;
  final bool centerTitle;
  final bool isAppBar;

  //右边按钮
  final List<Widget>? rightWidgets;
  final List<ActionData>? actions;
  final PreferredSizeWidget? bottom;
  final ContainerType containerType;
  final double pixels;

  final Widget main;
  final Widget body;
  AdaptiveContainerController? controller;

  AppBarAdaptiveView(
      {super.key,
      required this.main,
      required this.body,
      this.withLeading = false,
      this.leadingWidget,
      this.leadingCallBack,
      this.title,
      this.helpPath,
      this.isAppBar = true,
      this.titleWidget,
      this.centerTitle = false,
      this.actions,
      this.rightWidgets,
      this.bottom,
      this.pixels = 320,
      this.containerType = ContainerType.carousel});

  @override
  Widget build(BuildContext context) {
    var provider = Consumer3<AppDataProvider, IndexWidgetProvider, Myself>(
        builder:
            (context, appDataProvider, indexWidgetProvider, myself, child) {
      ContainerType containerType = this.containerType;
      if (appDataProvider.landscape) {
        if (appDataProvider.bodyWidth == 0) {
          containerType = ContainerType.resizeable;
        }
      }
      controller = AdaptiveContainerController(
        containerType: containerType,
        pixels: pixels,
      );
      List<ActionData> actions = this.actions ?? [];
      List<Widget> rightWidgets = [];
      if (this.rightWidgets != null) {
        rightWidgets.addAll(this.rightWidgets!);
      }
      if (body is DataTileMixin) {
        DataTileMixin dataTileMixin = body as DataTileMixin;
        if (dataTileMixin.actions != null) {
          actions.addAll(dataTileMixin.actions!);
        }
        if (dataTileMixin.rightWidgets != null) {
          rightWidgets.addAll(dataTileMixin.rightWidgets!);
        }
      }
      rightWidgets.add(ValueListenableBuilder(
          valueListenable: controller!.isOpen,
          builder: (BuildContext context, bool value, Widget? child) {
            return IconButton(
              onPressed: () {
                controller?.toggle();
              },
              isSelected: controller!.isOpen.value,
              icon: Icon(Icons.vertical_split_outlined),
              selectedIcon: Icon(Icons.vertical_split),
            );
          }));
      var appBarView = AppBarView(
          title: title,
          withLeading: withLeading,
          leadingWidget: leadingWidget,
          leadingCallBack: leadingCallBack,
          helpPath: helpPath,
          isAppBar: isAppBar,
          titleWidget: titleWidget,
          centerTitle: centerTitle,
          actions: actions,
          bottom: bottom,
          rightWidgets: rightWidgets,
          child: AdaptiveContainer(
              controller: controller!, main: main, body: body));

      return appBarView;
    });

    return provider;
  }
}
