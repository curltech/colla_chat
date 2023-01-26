import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/image_util.dart';
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
      this.suffix,
      this.routeName,
      this.dense = true,
      this.selected = false,
      this.isThreeLine = false,
      this.onTap});

  static TileData of(TileDataMixin mixin) {
    return TileData(
        title: mixin.title, routeName: mixin.routeName, prefix: mixin.icon);
  }

  static List<TileData> from(List<TileDataMixin> mixins) {
    List<TileData> tileData = [];
    if (mixins.isNotEmpty) {
      for (var mixin in mixins) {
        TileData tile = TileData.of(mixin);
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
        if (selected) {
          leading = Icon(prefix, color: myself.primary);
        } else {
          leading = Icon(prefix);
        }
      }
    }

    return leading;
  }
}

/// 通用列表项，用构造函数传入数据，根据数据构造列表项
class DataListTile extends StatelessWidget {
  final DataListController<TileData> dataListViewController;
  final TileData tileData;
  final int index;

  ///如果定义了点击回调函数，序号为参数进行回调
  ///回调函数有两个，一个构造函数传入的成员变量，用于处理高亮显示
  ///二是数据项里面定义的，用于自定义的后续任务
  final Function(int index, String title, {String? subtitle})? onTap;

  const DataListTile(
      {Key? key,
      required this.dataListViewController,
      required this.tileData,
      required this.index,
      this.onTap})
      : super(key: key);

  Widget _buildListTile(BuildContext context) {
    bool selected = false;
    if (tileData.selected == true ||
        (tileData.selected == null &&
            dataListViewController.currentIndex == index)) {
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
        trailing.add(Text(
          suffix,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        ));
      }
    }

    ///然后，如果路由名称存在，加入路由图标
    if (tileData.routeName != null) {
      trailing.add(Icon(Icons.chevron_right, color: myself.primary));
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

    ///未来不使用ListTile，因为高度固定，不够灵活
    var listTile = ListTile(
      selected: selected,
      leading: leading,
      title: Text(
        AppLocalizations.t(tileData.title),
      ),
      subtitle: tileData.subtitle != null
          ? Text(
              tileData.subtitle!,
            )
          : null,
      trailing: trailingWidget,
      isThreeLine: tileData.isThreeLine,
      dense: tileData.dense,
      onTap: () async {
        dataListViewController.currentIndex = index;
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
      },
    );

    return listTile;
  }

  ActionPane _buildActionPane(
      BuildContext context, List<TileData>? slideActions) {
    List<SlidableAction> slidableActions = [];
    if (tileData.slideActions != null) {
      for (var slideAction in tileData.slideActions!) {
        SlidableAction slidableAction = SlidableAction(
          onPressed: (context) {
            if (slideAction.onTap != null) {
              slideAction.onTap!(index, tileData.title,
                  subtitle: slideAction.title);
            }
          },
          backgroundColor: Colors.white.withOpacity(AppOpacity.lgOpacity),
          foregroundColor: myself.primary,
          icon: slideAction.prefix,
          label: AppLocalizations.t(slideAction.title),
        );
        slidableActions.add(slidableAction);
      }
    }
    ActionPane actionPane = ActionPane(
      motion: const ScrollMotion(),
      dismissible: DismissiblePane(onDismissed: () {}),
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
      endActionPane = _buildActionPane(context, tileData.slideActions);
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
