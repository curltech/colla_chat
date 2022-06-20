import 'dart:typed_data';

import 'package:colla_chat/widgets/common/data_listview.dart';
import 'package:flutter/material.dart';

import 'data_listtile.dart';

///包含很多项的滚动视图，如果只有一个分组，采用ListView实现
///如果有多个分组，ListView的每个组件是每个分组ExpansionTile，每个分组ExpansionTile下面是ListView，
///每个ListView下面是ListTile
class GroupDataListView extends StatelessWidget {
  late final Map<TileData, List<TileData>> _tileData;

  GroupDataListView({Key? key, required Map<TileData, List<TileData>> tileData})
      : super(key: key) {
    _tileData = tileData;
  }

  Widget _buildExpansionTile(BuildContext context, TileData tile) {
    Widget? leading;
    final avatar = tile.avatar;
    if (tile.icon != null) {
      leading = tile.icon;
    } else if (avatar != null) {
      leading = Image.memory(Uint8List.fromList(avatar.codeUnits));
    }
    List<Widget>? trailing = <Widget>[];
    var suffix = tile.suffix;
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
    List<TileData>? tileData = _tileData[tile];
    tileData = tileData ?? [];
    DataListView dataListView =
        DataListView(DataListViewController(tileData: tileData));

    ///未来不使用ListTile，因为高度固定，不够灵活
    return ExpansionTile(
      leading: leading,
      title: Text(
        tile.title,
      ),
      subtitle: tile.subtitle != null
          ? Text(
              tile.subtitle!,
            )
          : null,
      trailing: trailingWidget,
      initiallyExpanded: true,
      children: [dataListView],
    );
  }

  Widget _build(BuildContext context) {
    List<Widget> groups = [];
    if (_tileData.isNotEmpty) {
      if (_tileData.length == 1) {
        Widget groupWidget = DataListView(
            DataListViewController(tileData: _tileData.values.first));
        return groupWidget;
      } else {
        for (var tileEntry in _tileData.entries) {
          Widget groupExpansionTile = _buildExpansionTile(
            context,
            tileEntry.key,
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
