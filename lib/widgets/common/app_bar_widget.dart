import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/menu_util.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';

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
  final List<ActionData>? actions;
  final List<Widget>? rightWidgets; //右边的排列组件（按钮）
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
      this.actions,
      this.rightWidgets,
      this.bottom,
      this.withLeading = false,
      this.title = const AutoSizeText(''),
      this.centerTitle = false,
      this.isAppBar = true});

  late final Size _preferredSize =
      Size(0, toolbarHeight ?? appDataProvider.toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return isAppBar ? _buildAppBar(context) : _buildTitleBar(context);
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    var btns = <Widget>[];
    if (rightWidgets != null && rightWidgets!.isNotEmpty) {
      btns.addAll(rightWidgets!);
    }
    if (actions != null && actions!.isNotEmpty) {
      btns.add(IconButton(
          onPressed: () {
            _showActionCard(context);
          },
          icon: Icon(
            Icons.more_horiz,
            color: foregroundColor,
          )));
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
      actions: btns,
      automaticallyImplyLeading: false,
      toolbarHeight: toolbarHeight,
      elevation: elevation,
      backgroundColor: backgroundColor ?? myself.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      bottom: bottom,
    );

    return appBar;
  }

  Widget _buildTitleBar(BuildContext context) {
    List<Widget> children = [];
    var btns = <Widget>[const Spacer()];
    if (rightWidgets != null && rightWidgets!.isNotEmpty) {
      btns.addAll(rightWidgets!);
    }
    if (actions != null && actions!.isNotEmpty) {
      btns.add(IconButton(
          onPressed: () {
            _showActionCard(context);
          },
          icon: Icon(
            Icons.more_horiz,
            color: foregroundColor,
          )));
    }
    Widget? leading = leadingWidget;

    ///左边的回退按钮
    if (withLeading) {
      leading ??= _buildBackButton(context);
    }
    if (leading != null) {
      if (centerTitle || title == null) {
        children.add(Row(
          children: [leading, ...btns],
        ));
      } else {
        children.add(Row(
          children: [leading, title!, ...btns],
        ));
      }
    } else {
      if (!centerTitle && title != null) {
        children.add(Row(
          children: [title!, ...btns],
        ));
      }
    }
    if (centerTitle && title != null) {
      children.add(Align(alignment: Alignment.center, child: title!));
    }
    return Container(
      height: toolbarHeight,
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
          await leadingCallBack!.call();
        } else {
          indexWidgetProvider.pop(context: context);
        }
      },
    );
    return leadingButton;
  }

  Future<dynamic> _showActionCard(BuildContext context) async {
    if (actions == null || actions!.isEmpty) {
      return;
    }
    return MenuUtil.popModalBottomSheet(context, actions: actions!);
  }

  @override
  Size get preferredSize => _preferredSize;
}
