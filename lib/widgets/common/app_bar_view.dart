import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

///工作区的标准视图，包裹了顶部栏AppBarWidget和一个包裹了child
class AppBarView extends StatefulWidget {
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
  State<StatefulWidget> createState() {
    return _AppBarViewState();
  }
}

class _AppBarViewState extends State<AppBarView> {
  @override
  initState() {
    super.initState();
    myself.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget titleWidget = widget.titleWidget ??
        CommonAutoSizeText(
          AppLocalizations.t(widget.title ?? ''),
          style: const TextStyle(color: Colors.white),
          //softWrap: true,
          wrapWords: false,
          overflow: TextOverflow.visible,
          //maxLines: 2
        );
    return Consumer<IndexWidgetProvider>(
        builder: (context, indexWidgetProvider, child) {
      return Column(children: [
        AppBarWidget.buildAppBar(
          context,
          backgroundColor: myself.primary,
          withLeading: widget.withLeading,
          leadingCallBack: widget.leadingCallBack,
          title: titleWidget,
          centerTitle: widget.centerTitle,
          rightWidgets: widget.rightWidgets,
          rightPopupMenus: widget.rightPopupMenus,
          bottom: widget.bottom,
        ),
        Expanded(child: widget.child),
      ]);
    });
  }

  @override
  void dispose() {
    myself.removeListener(_update);
    super.dispose();
  }
}
