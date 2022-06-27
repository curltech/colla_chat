import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

///工作区的顶部栏AppBar，定义了前导组件，比如回退按钮
///定义了尾部组件和下拉按钮
class AppBarWidget {
  static AppBar build(
    BuildContext context, {
    withLeading = false, //是否有缺省的回退按钮
    leadingCallBack, //回退按钮的回调
    title = '',
    centerTitle = false, //标题是否居中
    rightActions, //右边的下拉组件
    rightIcons, //右边下拉组件的图标
    rightWidgets, //右边的排列组件
    rightCallBack, //右边下拉组件的回调
    bottom, //底部组件
  }) {
    ///右边排列的按钮组件，最后一个是下拉按钮组件
    var actions = <Widget>[];

    ///首先加上右边的排列组件
    if (rightWidgets != null && rightWidgets.isNotEmpty) {
      actions.addAll(rightWidgets);
    }

    ///然后加上右边的下拉组件
    var action = popMenuButton(context,
        rightActions: rightActions,
        rightIcons: rightIcons,
        rightCallBack: rightCallBack,
        rightWidgets: rightWidgets);
    if (action != null) {
      actions.add(action);
    }

    ///左边的回退按钮
    var leading = backButton(context,
        withLeading: withLeading, leadingCallBack: leadingCallBack);
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
      {bool withLeading = false, final Function? leadingCallBack}) {
    Widget? leadingButton;

    ///是否加上回退按钮，如果回调存在，调用回调函数，然后回退路由
    if (withLeading) {
      leadingButton = IconButton(
        icon: const Icon(Icons.chevron_left, color: Colors.white),
        onPressed: () {
          if (leadingCallBack != null) {
            leadingCallBack();
          }
          var indexWidgetProvider =
              Provider.of<IndexWidgetProvider>(context, listen: false);
          indexWidgetProvider.pop(context: context);
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

    ///左右边的下拉按钮
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
        ///调用下拉按钮的回调函数，参数为按钮序号
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
