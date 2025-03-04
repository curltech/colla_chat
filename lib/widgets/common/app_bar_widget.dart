import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';

class AppBarPopupMenu {
  Widget? icon;
  void Function()? onPressed;
  String? title;

  AppBarPopupMenu({this.title, this.icon, this.onPressed});
}

///工作区的顶部栏AppBar，定义了前导组件，比如回退按钮
///定义了尾部组件和下拉按钮
class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? toolbarHeight;
  final double? elevation;
  final bool withLeading; //是否有缺省的回退按钮
  final Widget? leadingWidget;
  final Function? leadingCallBack; //回退按钮的回调
  final Widget? title;
  final bool centerTitle; //标题是否居中
  final Widget? rightWidget;
  final List<Widget>? rightWidgets; //右边的排列组件（按钮）
  final List<AppBarPopupMenu>? rightPopupMenus; //右边的下拉菜单组件
  final PreferredSizeWidget? bottom;
  final bool isAppBar;

  AppBarWidget(
      {super.key,
      this.backgroundColor,
      this.foregroundColor,
      this.toolbarHeight,
      this.elevation,
      this.leadingWidget,
      this.leadingCallBack,
      this.rightWidget,
      this.rightWidgets,
      this.rightPopupMenus,
      this.bottom,
      this.withLeading = false,
      this.title = const CommonAutoSizeText(''),
      this.centerTitle = false,
      this.isAppBar = true});

  Size _preferredSize = Size(0, 0);

  @override
  Widget build(BuildContext context) {
    return isAppBar ? _buildAppBar(context) : _buildTitleBar(context);
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    ///右边排列的按钮组件，最后一个是下拉按钮组件
    var actions = <Widget>[];

    ///首先加上右边的排列组件
    if (rightWidget != null) {
      actions.add(rightWidget!);
    }
    if (rightWidgets != null && rightWidgets!.isNotEmpty) {
      actions.addAll(rightWidgets!);
    }

    ///然后加上右边的下拉组件
    var action = _buildPopMenuButton(context);
    if (action != null) {
      actions.add(action);
    }

    Widget? leading = leadingWidget;

    ///左边的回退按钮
    if (withLeading) {
      leading ??= _buildBackButton(context);
    }
    AppBar appBar = AppBar(
      title: title,
      centerTitle: centerTitle,
      titleSpacing: leadingWidget != null ? 0.0 : null,
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: false,
      toolbarHeight: toolbarHeight,
      elevation: elevation,
      backgroundColor: backgroundColor ?? myself.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      bottom: bottom,
    );
    // _preferredSize = appBar.preferredSize;

    return appBar;
  }

  Widget _buildTitleBar(BuildContext context) {
    List<Widget> children = [];
    var actions = <Widget>[const Spacer()];
    if (rightWidget != null) {
      actions.add(rightWidget!);
    }
    if (rightWidgets != null && rightWidgets!.isNotEmpty) {
      actions.addAll(rightWidgets!);
    }
    Widget? leading = leadingWidget;

    ///左边的回退按钮
    if (withLeading) {
      leading ??= _buildBackButton(context);
    }
    if (leading != null) {
      if (centerTitle || title == null) {
        children.add(Row(
          children: [leading, ...actions],
        ));
      } else {
        children.add(Row(
          children: [leading, title!, ...actions],
        ));
      }
    } else {
      if (!centerTitle && title != null) {
        children.add(Row(
          children: [title!, ...actions],
        ));
      }
    }
    if (centerTitle && title != null) {
      children.add(Align(alignment: Alignment.center, child: title!));
    }
    return Container(
      padding: const EdgeInsets.all(10),
      color: backgroundColor ?? myself.primary,
      child: Stack(
        children: children,
      ),
    );
  }

  Widget? _buildBackButton(BuildContext context) {
    Widget? leadingButton = IconButton(
      tooltip: AppLocalizations.t('Back'),
      icon: Icon(Icons.arrow_back_ios_new, color: foregroundColor),
      onPressed: () async {
        if (leadingCallBack != null) {
          await leadingCallBack!();
        }
        indexWidgetProvider.pop(context: context);
      },
    );
    return leadingButton;
  }

  PopupMenuButton<int>? _buildPopMenuButton(BuildContext context) {
    PopupMenuButton<int>? popMenuButton;

    ///左右边的下拉按钮
    if (rightPopupMenus != null && rightPopupMenus!.isNotEmpty) {
      List<PopupMenuItem<int>> items = [];
      List<void Function()?> onPressed = [];
      int i = 0;
      for (var rightAction in rightPopupMenus!) {
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

  @override
  Size get preferredSize => _preferredSize;
}
