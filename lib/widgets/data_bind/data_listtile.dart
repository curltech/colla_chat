import 'dart:typed_data';

import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/data_list_controller.dart';

///指定路由样式，不指定则系统判断，系统判断的方法是如果是移动则走全局路由，否则走工作区路由
enum RouteStyle { workspace, navigator }

/// 通用列表项的数据模型
class TileData {
  //图标
  final Icon? icon;

  //头像
  final String? avatar;

  //标题
  final String title;
  final String? subtitle;
  final dynamic suffix;
  final String? routeName;

  //缺省行为，为空的时候，是打上选择标志，颜色变化
  Function(int index, String title)? onTap;

  TileData(
      {this.icon,
      this.avatar,
      required this.title,
      this.subtitle,
      this.suffix,
      this.routeName,
      this.onTap});

  static TileData of(TileDataMixin mixin) {
    return TileData(
        title: mixin.title, routeName: mixin.routeName, icon: mixin.icon);
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
}

/// 通用列表项，用构造函数传入数据，根据数据构造列表项
class DataListTile extends StatelessWidget {
  final DataListController<TileData> dataListViewController;
  final TileData tileData;
  final int index;

  ///是否缩小
  final bool dense;

  final bool isThreeLine;

  ///如果定义了点击回调函数，序号为参数进行回调
  ///回调函数有两个，一个构造函数传入的成员变量，用于处理高亮显示
  ///二是数据项里面定义的，用于自定义的后续任务
  final Function(int index, String title)? onTap;

  const DataListTile(
      {Key? key,
      required this.dataListViewController,
      required this.tileData,
      required this.index,
      this.dense = false,
      this.isThreeLine = false,
      this.onTap})
      : super(key: key);

  Widget _buildListTile(BuildContext context) {
    ///前导组件，一般是自定义图标或者图像
    Widget? leading;
    final avatar = tileData.avatar;
    if (tileData.icon != null) {
      leading = tileData.icon;
    } else if (avatar != null) {
      leading = Image.memory(Uint8List.fromList(avatar.codeUnits));
    }

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
      trailing.add(Icon(Icons.chevron_right,
          color: appDataProvider.themeData?.colorScheme.primary));
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
    bool selected = false;
    if (dataListViewController.currentIndex == index) {
      selected = true;
    }

    ///未来不使用ListTile，因为高度固定，不够灵活
    var listTile = ListTile(
      selected: selected,
      leading: leading,
      title: Text(
        tileData.title,
      ),
      subtitle: tileData.subtitle != null
          ? Text(
              tileData.subtitle!,
            )
          : null,
      trailing: trailingWidget,
      isThreeLine: isThreeLine,
      dense: dense,
      onTap: () {
        dataListViewController.currentIndex = index;
        var fn = onTap;
        if (fn != null) {
          fn(index, tileData.title);
        }
        fn = tileData.onTap;
        if (fn != null) {
          fn(index, tileData.title);
        }

        ///如果路由名称存在，点击会调用路由
        if (tileData.routeName != null) {
          var indexWidgetProvider =
              Provider.of<IndexWidgetProvider>(context, listen: false);
          indexWidgetProvider.push(tileData.routeName!, context: context);
        }
      },
    );

    return listTile;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(top: 5.0),
        child: Column(children: <Widget>[
          _buildListTile(context),
          const Padding(
            padding: EdgeInsets.only(left: 5.0, right: 5.0),
            child: Divider(
              height: 0.5,
            ),
          ),
        ]));
  }
}
