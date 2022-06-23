import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data_listtile.dart';

///工作区的顶部栏AppBar，定义了回退按钮
class AppBarWidget {
  static AppBar build(
    BuildContext context, {
    withLeading = false,
    leadingRouteStyle,
    leadingCallBack,
    title = '',
    centerTitle = false,
    rightActions,
    rightIcons,
    rightWidgets,
    rightCallBack,
    bottom,
  }) {
    var actions = <Widget>[];
    if (rightWidgets != null && rightWidgets.isNotEmpty) {
      actions.addAll(rightWidgets);
    }
    var action = popMenuButton(context,
        rightActions: rightActions,
        rightIcons: rightIcons,
        rightCallBack: rightCallBack,
        rightWidgets: rightWidgets);
    if (action != null) {
      actions.add(action);
    }
    var leading = backButton(context,
        withLeading: withLeading,
        leadingRouteStyle: leadingRouteStyle,
        leadingCallBack: leadingCallBack);
    AppBar appBar = AppBar(
      title: Text(title),
      elevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: leading,
      actions: actions,
      bottom: bottom,
    );
    return appBar;
  }

  static Widget? backButton(BuildContext context,
      {bool withLeading = false,
      final Function? leadingCallBack,
      RouteStyle? leadingRouteStyle}) {
    Widget? leadingButton;
    if (withLeading) {
      leadingButton = IconButton(
        icon: const Icon(Icons.chevron_left, color: Colors.white),
        onPressed: () {
          if (leadingCallBack != null) {
            leadingCallBack();
          } else {
            var indexWidgetProvider =
                Provider.of<IndexWidgetProvider>(context, listen: false);
            indexWidgetProvider.pop(
                routeStyle: leadingRouteStyle, context: context);
          }
        },
      );
    }
    return leadingButton;
  }

  static PopupMenuButton<int>? popMenuButton(
    BuildContext context, {
    List<String>? rightActions,
    List<Icon>? rightIcons,
    List<Widget>? rightWidgets,
    Function(int index)? rightCallBack,
  }) {
    PopupMenuButton<int>? popMenuButton;
    if (rightActions != null && rightActions.isNotEmpty) {
      List<PopupMenuItem<int>> items = [];
      int i = 0;
      for (var rightAction in rightActions) {
        PopupMenuItem<int> item;
        if (rightIcons != null && rightIcons.length > i) {
          item = PopupMenuItem<int>(
              value: i,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [rightIcons[i], Text(rightAction)],
              ));
        } else {
          item = PopupMenuItem<int>(
            value: i,
            child: Text(rightAction),
          );
        }
        items.add(item);
        ++i;
      }
      popMenuButton = PopupMenuButton<int>(
        itemBuilder: (BuildContext context) {
          return items;
        },
        // icon: const Icon(
        //   Icons.add,
        //   color: Colors.white,
        // ),
        onSelected: (int index) async {
          if (rightCallBack != null) {
            await rightCallBack!(index);
          }
        },
      );
    }

    return popMenuButton;
  }
}
