import 'dart:typed_data';

import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

///指定路由样式，不指定则系统判断，系统判断的方法是如果是移动则走全局路由，否则走工作区路由
enum RouteStyle { workspace, navigator }

/// 通用列表项的数据模型
class TileData {
  //图标
  late final Icon? icon;

  //头像
  late final String? avatar;

  //标题
  late final String title;
  late final String? subtitle;
  late final dynamic suffix;
  late final String? routeName;
  //进入路由样式
  late final RouteStyle? routeStyle;
  Function(String title)? onTap;

  TileData(
      {this.icon,
      this.avatar,
      required this.title,
      this.subtitle,
      this.suffix,
      this.routeName,
      this.routeStyle,
      this.onTap});
}

/// 通用列表项，用构造函数传入数据，根据数据构造列表项
class DataListTile extends StatelessWidget {
  late final TileData _tileData;
  bool selected;

  DataListTile({Key? key, required TileData tileData, this.selected = false})
      : super(key: key) {
    _tileData = tileData;
  }

  @override
  Widget build(BuildContext context) {
    Widget? leading;
    final avatar = _tileData.avatar;
    if (_tileData.icon != null) {
      leading = _tileData.icon;
    } else if (avatar != null) {
      leading = Image.memory(Uint8List.fromList(avatar.codeUnits));
    }
    List<Widget>? trailing = <Widget>[];
    var suffix = _tileData.suffix;
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
    if (_tileData.routeName != null) {
      trailing.add(Icon(Icons.chevron_right,
          color: appDataProvider.themeData?.colorScheme.primary));
    }
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
        _tileData.title,
      ),
      subtitle: _tileData.subtitle != null
          ? Text(
              _tileData.subtitle!,
            )
          : null,
      trailing: trailingWidget,
      dense: true,
      onTap: () {
        var call = _tileData.onTap;
        if (call != null) {
          call(_tileData.title);
        }
        if (_tileData.routeName != null) {
          var indexWidgetProvider =
              Provider.of<IndexWidgetProvider>(context, listen: false);
          indexWidgetProvider.push(_tileData.routeName!,
              context: context, routeStyle: _tileData.routeStyle);
        }
      },
    );
    return Container(
        margin: const EdgeInsets.only(top: 5.0),
        child: Column(children: <Widget>[
          listTile,
          const Padding(
            padding: EdgeInsets.only(left: 5.0, right: 5.0),
            child: Divider(
              height: 0.5,
            ),
          ),
        ]));
  }
}
