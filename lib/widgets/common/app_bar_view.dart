import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';

///工作区的标准视图，包裹了顶部栏AppBarWidget和一个包裹了child
class AppBarView extends StatelessWidget {
  final bool withLeading;

  //指定回退路由样式，不指定则系统判断
  final Function? leadingCallBack;
  final String? title;
  final Widget? titleWidget;
  final bool centerTitle;

  //右边按钮
  final List<Widget>? rightWidgets;

  //右边下拉菜单
  final List<AppBarPopupMenu>? rightPopupMenus;
  final PreferredSizeWidget? bottom;
  final Widget child;

  const AppBarView({
    super.key,
    this.withLeading = false,
    this.leadingCallBack,
    this.title,
    this.titleWidget,
    this.centerTitle = false,
    this.rightWidgets,
    this.rightPopupMenus,
    this.bottom,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Widget titleWidget = this.titleWidget ??
        CommonAutoSizeText(
          AppLocalizations.t(title ?? ''),
          style: const TextStyle(color: Colors.white),
          //softWrap: true,
          wrapWords: false,
          overflow: TextOverflow.visible,
          //maxLines: 2
        );

    return Column(children: [
      AppBarWidget.buildAppBar(
        context:context,
        backgroundColor: myself.primary,
        withLeading: withLeading,
        leadingCallBack: leadingCallBack,
        title: titleWidget,
        centerTitle: centerTitle,
        rightWidgets: rightWidgets,
        rightPopupMenus: rightPopupMenus,
        bottom: bottom,
      ),
      Expanded(child: child),
    ]);
  }
}
