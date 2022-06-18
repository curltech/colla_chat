import 'dart:typed_data';

import 'package:colla_chat/provider/app_data.dart';
import 'package:colla_chat/provider/index_views.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  late final String? tileType;
  Function()? routerCallback;

  TileData(
      {this.icon,
      this.avatar,
      required this.title,
      this.subtitle,
      this.suffix,
      this.tileType,
      this.routeName,
      this.routerCallback});
}

/// 通用列表项
class DataListTile extends StatelessWidget {
  //图标
  late final TileData _tileData;

  DataListTile({Key? key, required TileData tileData}) : super(key: key) {
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
        trailing.add(Expanded(
            child: Text(
          suffix,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        )));
      }
    }
    if (_tileData.routeName != null || _tileData.routerCallback != null) {
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
    return ListTile(
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
      onTap: () {
        var call = _tileData.routerCallback;
        if (call != null) {
          call();
        } else if (_tileData.routeName != null) {
          var indexViewProvider =
              Provider.of<IndexViewProvider>(context, listen: false);
          indexViewProvider.push(_tileData.routeName!);
        }
      },
    );
  }
}

class DataListView extends StatelessWidget {
  late final Map<String, List<TileData>> _tileData;

  DataListView({Key? key, required Map<String, List<TileData>> tileData})
      : super(key: key) {
    _tileData = tileData;
  }

  Widget _build(BuildContext context) {
    List<Widget> groups = [];
    for (var tiles in _tileData.values) {
      List<Widget> items = [];
      for (var tile in tiles) {
        var item = Container(
            margin: const EdgeInsets.only(top: 5.0),
            child: Column(children: <Widget>[
              DataListTile(tileData: tile),
              const Padding(
                padding: EdgeInsets.only(left: 5.0, right: 5.0),
                child: Divider(
                  height: 0.5,
                ),
              ),
            ]));
        items.add(item);
      }
      var group = Column(children: items);
      groups.add(group);
    }
    var view = Column(
      children: groups,
    );

    return view;
  }

  @override
  Widget build(BuildContext context) {
    return _build(context);
  }
}
