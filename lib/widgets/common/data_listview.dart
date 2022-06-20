import 'dart:typed_data';

import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_view_provider.dart';
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
  Function()? routeCallback;

  TileData(
      {this.icon,
      this.avatar,
      required this.title,
      this.subtitle,
      this.suffix,
      this.routeName,
      this.routeCallback});
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
        trailing.add(Text(
          suffix,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        ));
      }
    }
    if (_tileData.routeName != null || _tileData.routeCallback != null) {
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
      dense: true,
      onTap: () {
        var call = _tileData.routeCallback;
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

///包含很多项的滚动视图，如果只有一个分组，采用ListView实现
///如果有多个分组，ListView的每个组件是每个分组ExpansionTile，每个分组ExpansionTile下面是ListView，
///每个ListView下面是ListTile
class DataListView extends StatelessWidget {
  late final Map<TileData, List<TileData>> _tileData;

  DataListView({Key? key, required Map<TileData, List<TileData>> tileData})
      : super(key: key) {
    _tileData = tileData;
  }

  Widget _buildGroup(BuildContext context, List<TileData> tiles) {
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
    Widget groupWidget = ListView.builder(
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          return items[index];
        });

    return groupWidget;
  }

  Widget _buildTile(
      BuildContext context, TileData tileData, List<Widget> children) {
    Widget? leading;
    final avatar = tileData.avatar;
    if (tileData.icon != null) {
      leading = tileData.icon;
    } else if (avatar != null) {
      leading = Image.memory(Uint8List.fromList(avatar.codeUnits));
    }
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
    return ExpansionTile(
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
      initiallyExpanded: true,
      children: children,
    );
  }

  Widget _build(BuildContext context) {
    List<Widget> groups = [];
    if (_tileData.isNotEmpty) {
      if (_tileData.length == 1) {
        Widget groupWidget = _buildGroup(context, _tileData.values.first);
        return groupWidget;
      } else {
        for (var tileEntry in _tileData.entries) {
          Widget groupWidget = _buildGroup(context, tileEntry.value);
          Widget groupExpansionTile = _buildTile(
            context,
            tileEntry.key,
            [groupWidget],
          );
          groups.add(groupExpansionTile);
        }
      }
    }

    return ListView(shrinkWrap: true, children: groups);
  }

  @override
  Widget build(BuildContext context) {
    return _build(context);
  }
}
