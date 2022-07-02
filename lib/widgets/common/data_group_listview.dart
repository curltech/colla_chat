import 'dart:typed_data';

import 'package:colla_chat/widgets/common/data_listview.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:flutter/material.dart';

import 'data_listtile.dart';

///无状态组件，根据传入的数据一次性展示
///包含很多项的滚动视图，如果只有一个分组，采用ListView实现
///如果有多个分组，ListView的每个组件是每个分组ExpansionTile，每个分组ExpansionTile下面是ListView，
///每个ListView下面是ListTile
class GroupDataListView extends StatelessWidget {
  final Map<TileData, List<TileData>> tileData;

  ///类变量，不用每次重建
  late final Widget listView;
  final Function(int index, String title, {TileData? group})? onTap;

  GroupDataListView({Key? key, required this.tileData, this.onTap})
      : super(key: key) {
    listView = _build();
  }

  _onTap(int index, String title, {TileData? group}) {
    //logger.w('index: $index, title: $title,onTap GroupDataListView');
    var onTap = this.onTap;
    if (onTap != null) {
      onTap(index, title, group: group);
    }
  }

  Widget _buildExpansionTile(TileData tile) {
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
    var tiles = tileData[tile];
    tiles = tiles ?? [];
    Widget dataListView = KeepAliveWrapper(
        keepAlive: true,
        child: DataListView(onTap: _onTap, group: tile, tileData: tiles));

    ///未来不使用ListTile，因为高度固定，不够灵活
    return ExpansionTile(
      maintainState: true,
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

  Widget _build() {
    List<Widget> groups = [];
    if (tileData.isNotEmpty) {
      for (var tileEntry in tileData.entries) {
        Widget groupExpansionTile = _buildExpansionTile(
          tileEntry.key,
        );
        groups.add(groupExpansionTile);
      }
    }
    //该属性将决定列表的长度是否仅包裹其内容的长度。
    //当ListView 嵌在一个无限长的容器组件中时， shrinkWrap 必须为true
    return ListView(shrinkWrap: true, children: groups);
  }

  @override
  Widget build(BuildContext context) {
    return listView;
  }
}
