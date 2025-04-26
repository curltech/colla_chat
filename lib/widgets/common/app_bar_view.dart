import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/index/help_information_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';

///工作区的标准视图，包裹了顶部栏AppBarWidget和一个包裹了child
class AppBarView extends StatelessWidget {
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
  final Widget? rightWidget;
  final List<Widget>? rightWidgets;

  //右边下拉菜单
  final List<AppBarPopupMenu>? rightPopupMenus;
  final PreferredSizeWidget? bottom;
  final Widget child;

  const AppBarView({
    super.key,
    this.withLeading = false,
    this.leadingWidget,
    this.leadingCallBack,
    this.title,
    this.helpPath,
    this.isAppBar = true,
    this.titleWidget,
    this.centerTitle = false,
    this.rightWidget,
    this.rightWidgets,
    this.rightPopupMenus,
    this.bottom,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: myself,
      builder: (BuildContext context, Widget? child) {
        Widget titleWidget = this.titleWidget ??
            CommonAutoSizeText(
              AppLocalizations.t(title ?? ''),
              style: const TextStyle(color: Colors.white),
              //softWrap: true,
              wrapWords: false,
              overflow: TextOverflow.visible,
              //maxLines: 2
            );

        if (helpPath != null) {
          titleWidget = Row(
            children: [
              titleWidget,
              InkWell(
                onTap: () {
                  helpInformationController.title.value = title ?? '';
                  helpInformationController.helpPath = helpPath ?? '';
                  indexWidgetProvider.push('help');
                },
                child: Icon(
                  size: 18,
                  Icons.help_outline,
                  color: Colors.yellowAccent,
                ),
              )
            ],
          );
        }
        return Column(children: [
          AppBarWidget(
            backgroundColor: myself.primary,
            withLeading: withLeading,
            leadingWidget: leadingWidget,
            leadingCallBack: leadingCallBack,
            title: titleWidget,
            centerTitle: centerTitle,
            rightWidget: rightWidget,
            rightWidgets: rightWidgets,
            rightPopupMenus: rightPopupMenus,
            bottom: bottom,
            isAppBar: isAppBar,
          ),
          Expanded(child: this.child),
        ]);
      },
    );
  }
}
