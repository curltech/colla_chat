import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppBarPopupMenu {
  Widget? icon;
  void Function()? onPressed;
  String? title;

  AppBarPopupMenu({this.title, this.icon, this.onPressed});
}

///工作区的顶部栏AppBar，定义了前导组件，比如回退按钮
///定义了尾部组件和下拉按钮
class AppBarWidget {
  static PreferredSizeWidget buildAppBar(
    BuildContext context, {
    Color? backgroundColor,
    Color? foregroundColor,
    bool withLeading = false, //是否有缺省的回退按钮
    Function? leadingCallBack, //回退按钮的回调
    Widget? title = const CommonAutoSizeText(''),
    bool centerTitle = false, //标题是否居中
    List<Widget>? rightWidgets, //右边的排列组件（按钮）
    List<AppBarPopupMenu>? rightPopupMenus, //右边的下拉菜单组件
    PreferredSizeWidget? bottom, //底部组件
  }) {
    ///右边排列的按钮组件，最后一个是下拉按钮组件
    var actions = <Widget>[];

    ///首先加上右边的排列组件
    if (rightWidgets != null && rightWidgets.isNotEmpty) {
      actions.addAll(rightWidgets);
    }

    ///然后加上右边的下拉组件
    var action = popMenuButton(
        foregroundColor: foregroundColor,
        rightPopupMenus: rightPopupMenus,
        rightWidgets: rightWidgets);
    if (action != null) {
      actions.add(action);
    }

    ///左边的回退按钮
    var leading = backButton(context,
        foregroundColor: foregroundColor,
        withLeading: withLeading,
        leadingCallBack: leadingCallBack);
    // backgroundColor ??= myself.primary;
    // foregroundColor ??= Colors.white;
    PreferredSizeWidget appBar = AppBar(
      title: title,
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      bottom: bottom,
    );
    return appBar;
  }

  static Widget buildTitleBar({
    Color? backgroundColor,
    Color? foregroundColor,
    Widget? title = const CommonAutoSizeText(
      '',
      style: TextStyle(color: Colors.white),
    ),
    bool centerTitle = false, //标题是否居中
    List<Widget>? rightWidgets, //右边的排列组件（按钮）
    List<AppBarPopupMenu>? rightPopupMenus,
  }) {
    backgroundColor = backgroundColor ?? myself.primary;
    foregroundColor ??= Colors.white;
    var actions = <Widget>[const Spacer()];
    if (rightWidgets != null && rightWidgets.isNotEmpty) {
      actions.addAll(rightWidgets);
    }
    var action = popMenuButton(
        foregroundColor: foregroundColor,
        rightPopupMenus: rightPopupMenus,
        rightWidgets: rightWidgets);
    if (action != null) {
      actions.add(action);
    }
    return Container(
      padding: const EdgeInsets.all(10),
      color: backgroundColor,
      child: Stack(
        children: <Widget>[
          Align(
              alignment: centerTitle ? Alignment.center : Alignment.centerLeft,
              child: title!),
          Align(alignment: Alignment.topRight, child: Row(children: actions)),
        ],
      ),
    );
  }

  static Widget? backButton(
    BuildContext context, {
    bool withLeading = false,
    final Function? leadingCallBack,
    Color? foregroundColor,
  }) {
    Widget? leadingButton;
    // foregroundColor ??= Colors.white;

    ///是否加上回退按钮，如果回调存在，调用回调函数，然后回退路由
    if (withLeading) {
      leadingButton = IconButton(
        tooltip: AppLocalizations.t('Back'),
        icon: Icon(Icons.arrow_back_ios_new, color: foregroundColor),
        onPressed: () async {
          if (leadingCallBack != null) {
            await leadingCallBack();
          }
          var indexWidgetProvider =
              Provider.of<IndexWidgetProvider>(context, listen: false);
          indexWidgetProvider.pop(context: context);
        },
      );
    }
    return leadingButton;
  }

  static PopupMenuButton<int>? popMenuButton({
    Color? foregroundColor,
    List<AppBarPopupMenu>? rightPopupMenus,
    List<Widget>? rightWidgets,
  }) {
    PopupMenuButton<int>? popMenuButton;
    // foregroundColor ??= Colors.white;

    ///左右边的下拉按钮
    if (rightPopupMenus != null && rightPopupMenus.isNotEmpty) {
      List<PopupMenuItem<int>> items = [];
      List<void Function()?> onPressed = [];
      int i = 0;
      for (var rightAction in rightPopupMenus) {
        PopupMenuItem<int> item;
        Widget? iconWidget = rightAction.icon;
        String text = rightAction.title ?? '';
        Widget textWidget = CommonAutoSizeText(AppLocalizations.t(text));
        List<Widget> rows = [];
        if (iconWidget != null) {
          rows.add(iconWidget);
        }
        rows.add(const SizedBox(
          width: 25,
        ));
        rows.add(textWidget);
        item = PopupMenuItem<int>(
            value: i,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows,
            ));
        onPressed.add(rightAction.onPressed);
        items.add(item);
        ++i;
      }
      popMenuButton = PopupMenuButton<int>(
        color: Colors.white,
        itemBuilder: (BuildContext context) {
          return items;
        },
        icon: Icon(
          Icons.more_horiz,
          color: foregroundColor,
        ),
        //调用下拉按钮的回调函数，参数为按钮序号
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
