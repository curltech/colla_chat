import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

///指定路由样式，不指定则系统判断，系统判断的方法是如果是移动则走全局路由，否则走工作区路由
enum RouteStyle { workspace, navigator }

/// 通用列表项的数据模型
class TileData {
  //可以是Widget，String，IconData
  final dynamic prefix;

  //标题
  final String title;
  final String? titleTail;
  final String? subtitle;
  final dynamic suffix;
  final String? routeName;

  //是否缩小
  bool dense;
  bool? selected;

  final bool isThreeLine;

  //缺省行为，为空的时候，是打上选择标志，颜色变化
  Function(int index, String title, {String? subtitle})? onTap;

  List<TileData>? slideActions;
  List<TileData>? endSlideActions;

  TileData(
      {this.prefix,
      required this.title,
      this.subtitle,
      this.titleTail,
      this.suffix,
      this.routeName,
      this.dense = true,
      this.selected = false,
      this.isThreeLine = false,
      this.onTap});

  static TileData of(TileDataMixin mixin, {bool dense = false}) {
    return TileData(
        title: mixin.title,
        routeName: mixin.routeName,
        dense: dense,
        prefix: mixin.iconData);
  }

  static List<TileData> from(List<TileDataMixin> mixins, {bool dense = false}) {
    List<TileData> tileData = [];
    if (mixins.isNotEmpty) {
      for (var mixin in mixins) {
        TileData tile = TileData.of(mixin, dense: dense);
        tileData.add(tile);
      }
    }

    return tileData;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is TileData) {
      return runtimeType == other.runtimeType && title == other.title;
    }
    return false;
  }

  @override
  int get hashCode => title.hashCode;

  Widget? getPrefixWidget(bool selected) {
    Widget? leading;
    if (prefix != null) {
      if (prefix is Widget) {
        leading = prefix;
      } else if (prefix is String) {
        leading = ImageUtil.buildImageWidget(
          image: prefix,
          fit: BoxFit.contain,
        );
      } else if (prefix is IconData) {
        // leading = Icon(prefix);
        if (selected) {
          leading = Icon(prefix, color: Colors.white);
        } else {
          leading = Icon(prefix, color: myself.primary);
        }
      }
    }

    return leading;
  }
}

/// 通用列表项，用构造函数传入数据，根据数据构造列表项
class DataListTile extends StatelessWidget {
  final DataListController<TileData>? dataListViewController;
  final TileData tileData;
  final int index;
  final EdgeInsets? contentPadding;
  final double? horizontalTitleGap;
  final double? minVerticalPadding;
  final double? minLeadingWidth;

  ///如果定义了点击回调函数，序号为参数进行回调
  ///回调函数有两个，一个构造函数传入的成员变量，用于处理高亮显示
  ///二是数据项里面定义的，用于自定义的后续任务
  final Function(int index, String title, {String? subtitle})? onTap;

  const DataListTile({
    Key? key,
    this.dataListViewController,
    required this.tileData,
    this.index = 0,
    this.onTap,
    this.contentPadding,
    this.horizontalTitleGap,
    this.minVerticalPadding,
    this.minLeadingWidth,
  }) : super(key: key);

  Widget _buildListTile(BuildContext context) {
    bool selected = false;
    if (tileData.selected == true ||
        (tileData.selected == null &&
            dataListViewController != null &&
            dataListViewController!.currentIndex == index)) {
      selected = true;
    }

    ///前导组件，一般是自定义图标或者图像
    Widget? leading = tileData.getPrefixWidget(selected);

    ///尾部组件数组，首先加入suffix自定义组件或者文本
    List<Widget>? trailing = <Widget>[];
    var suffix = tileData.suffix;
    if (suffix != null) {
      if (suffix is Widget) {
        trailing.add(suffix);
      } else if (suffix is String) {
        trailing.add(CommonAutoSizeText(
          suffix,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        ));
      }
    }

    ///然后，如果路由名称存在，加入路由图标
    if (tileData.routeName != null) {
      trailing.add(Icon(Icons.chevron_right, color: myself.secondary));
    }

    ///横向排列尾部的组件
    Widget? trailingWidget;
    if (trailing.length == 1) {
      trailingWidget = trailing[0];
    } else if (trailing.length > 1) {
      trailingWidget = SizedBox(
          width: 300,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.end, children: trailing));
    }
    Widget titleWidget = CommonAutoSizeText(
      AppLocalizations.t(tileData.title),
      style: tileData.dense
          ? const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
          : null,
      // softWrap: true,
      // overflow: TextOverflow.ellipsis,
    );
    if (tileData.titleTail != null) {
      titleWidget = Row(children: [
        Expanded(child: titleWidget),
        //const Spacer(),
        CommonAutoSizeText(
          AppLocalizations.t(tileData.titleTail ?? ''),
          style: tileData.dense
              ? const TextStyle(
                  fontSize: 12,
                )
              : null,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        ),
      ]);
    }

    ///未来不使用ListTile，因为高度固定，不够灵活
    var listTile = ListTile(
      contentPadding: contentPadding,
      horizontalTitleGap: horizontalTitleGap,
      minVerticalPadding: minVerticalPadding,
      minLeadingWidth: minLeadingWidth,
      selected: selected,
      selectedColor: Colors.white,
      selectedTileColor: myself.primary,
      leading: leading,
      title: titleWidget,
      subtitle: tileData.subtitle != null
          ? CommonAutoSizeText(
              tileData.subtitle!,
            )
          : null,
      trailing: trailingWidget,
      isThreeLine: tileData.isThreeLine,
      dense: tileData.dense,
      onTap: onTap != null || tileData.routeName != null
          ? () async {
              if (dataListViewController != null) {
                dataListViewController!.currentIndex = index;
              }
              var fn = onTap;
              if (fn != null) {
                await fn(index, tileData.title, subtitle: tileData.subtitle);
              }
              fn = tileData.onTap;
              if (fn != null) {
                await fn(index, tileData.title, subtitle: tileData.subtitle);
              }

              ///如果路由名称存在，点击会调用路由
              if (tileData.routeName != null) {
                indexWidgetProvider.push(tileData.routeName!, context: context);
              }
            }
          : null,
    );

    if (selected) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 10.0),
        color: myself.primary,
        child: listTile,
      );
    }

    return listTile;
  }

  ActionPane _buildActionPane(
      BuildContext context, List<TileData>? slideActions) {
    List<SlidableAction> slidableActions = [];
    for (var slideAction in slideActions!) {
      SlidableAction slidableAction = SlidableAction(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0),
        onPressed: (context) {
          if (slideAction.onTap != null) {
            slideAction.onTap!(index, tileData.title,
                subtitle: slideAction.title);
          }
        },
        backgroundColor: Colors.white,
        foregroundColor: myself.primary,
        icon: slideAction.prefix,
        label: AppLocalizations.t(slideAction.title),
        borderRadius: BorderRadius.circular(0),
      );
      slidableActions.add(slidableAction);
    }
    ActionPane actionPane = ActionPane(
      extentRatio: 0.2 * slideActions.length,
      motion: const DrawerMotion(),
      //BehindMotion,StretchMotion,DrawerMotion,ScrollMotion
      //dismissible: DismissiblePane(onDismissed: () {}),
      children: slidableActions,
    );

    return actionPane;
  }

  Widget _buildSlideActionListTile(BuildContext context) {
    if (tileData.slideActions == null && tileData.endSlideActions == null) {
      return _buildListTile(context);
    }

    ActionPane? startActionPane;
    if (tileData.slideActions != null && tileData.slideActions!.isNotEmpty) {
      startActionPane = _buildActionPane(context, tileData.slideActions);
    }
    ActionPane? endActionPane;
    if (tileData.endSlideActions != null &&
        tileData.endSlideActions!.isNotEmpty) {
      endActionPane = _buildActionPane(context, tileData.endSlideActions);
    }

    Slidable slidable = Slidable(
      key: UniqueKey(),
      startActionPane: startActionPane,
      endActionPane: endActionPane,
      child: _buildListTile(context),
    );

    return slidable;
  }

  @override
  Widget build(BuildContext context) {
    return _buildSlideActionListTile(context);
  }
}
