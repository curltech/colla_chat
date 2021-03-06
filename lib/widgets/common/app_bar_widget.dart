import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppBarPopupMenu {
  Icon? icon;
  void Function()? onPressed;
  String? title;

  AppBarPopupMenu({this.title, this.icon, this.onPressed});
}

///工作区的顶部栏AppBar，定义了前导组件，比如回退按钮
///定义了尾部组件和下拉按钮
class AppBarWidget {
  static AppBar build(
    BuildContext context, {
    withLeading = false, //是否有缺省的回退按钮
    leadingCallBack, //回退按钮的回调
    title = '',
    centerTitle = false, //标题是否居中
    List<Widget>? rightWidgets, //右边的排列组件（按钮）
    List<AppBarPopupMenu>? rightPopupMenus, //右边的下拉菜单组件
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
        rightPopupMenus: rightPopupMenus, rightWidgets: rightWidgets);
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
    List<AppBarPopupMenu>? rightPopupMenus,
    List<Widget>? rightWidgets,
  }) {
    PopupMenuButton<int>? popMenuButton;

    ///左右边的下拉按钮
    if (rightPopupMenus != null && rightPopupMenus.isNotEmpty) {
      List<PopupMenuItem<int>> items = [];
      List<void Function()?> onPressed = [];
      int i = 0;
      for (var rightAction in rightPopupMenus) {
        PopupMenuItem<int> item;
        Widget? iconWidget = rightAction.icon;
        String text = rightAction.title ?? '';
        Widget textWidget = Text(text);
        List<Widget> rows = [];
        if (iconWidget != null) {
          rows.add(iconWidget);
        }
        rows.add(textWidget);
        item = PopupMenuItem<int>(
            value: i,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: rows,
            ));
        onPressed.add(rightAction.onPressed);
        items.add(item);
        ++i;
      }
      popMenuButton = PopupMenuButton<int>(
        itemBuilder: (BuildContext context) {
          return items;
        },

        ///调用下拉按钮的回调函数，参数为按钮序号
        onSelected: (int index) async {
          var onPress = onPressed[index];
          if (onPress != null) {
            onPress();
          }
        },
      );
    }

    return popMenuButton;
  }
}
