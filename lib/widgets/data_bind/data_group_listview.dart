import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

class GroupDataListController {
  final Map<TileData, List<TileData>> allData = <TileData, List<TileData>>{};

  GroupDataListController({Map<TileData, List<TileData>> tileData = const {}}) {
    _addAll(tileData: tileData);
  }

  List<TileData>? get(TileData tile) {
    return allData[tile];
  }

  void _addAll({required Map<TileData, List<TileData>> tileData}) {
    allData.addEntries(tileData.entries);
  }

  void addAll({required Map<TileData, List<TileData>> tileData}) {
    if (tileData.isNotEmpty) {
      _addAll(tileData: tileData);
    }
  }

  void add(TileData tile, List<TileData> tileData) {
    List<TileData>? data = allData[tile];
    data ??= [];
    data.addAll([...tileData]);
    allData[tile] = data;
  }

  void remove(TileData tile) {
    if (allData.containsKey(tile)) {
      allData.remove(tile);
    }
  }
}

class GroupDataListView extends StatelessWidget {
  late final GroupDataListController groupDataListController;
  final Function(int index, String title, {String? subtitle, TileData? group})?
      onTap;

  GroupDataListView(
      {super.key,
      GroupDataListController? controller,
      Map<TileData, List<TileData>> tileData = const {},
      this.onTap}) {
    if (controller != null) {
      groupDataListController = controller;
    } else {
      groupDataListController = GroupDataListController(tileData: tileData);
    }
  }

  void _onTap(int index, String title, {String? subtitle, TileData? group}) {
    var onTap = this.onTap;
    if (onTap != null) {
      onTap(index, title, subtitle: subtitle, group: group);
    }
  }

  Widget? _buildExpansionTile(TileData tileData) {
    var data = groupDataListController.get(tileData);
    if (data == null) {
      return null;
    }
    Widget? leading = tileData.getPrefixWidget(true);
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

    Widget dataListView = DataListView(
      onTap: _onTap,
      group: tileData,
      itemCount: data.length,
      itemBuilder: (BuildContext context, int index) {
        return data[index];
      },
    );
    bool selected = tileData.selected ?? false;

    /// 未来不使用ListTile，因为高度固定，不够灵活
    Widget expansionTile = ListenableBuilder(
      listenable: myself,
      builder: (BuildContext context, Widget? child) {
        return ExpansionTile(
          childrenPadding: const EdgeInsets.all(0),
          maintainState: true,
          leading: leading,
          textColor: selected ? myself.primary : null,
          title: AutoSizeText(
            AppLocalizations.t(tileData.title),
          ),
          subtitle: tileData.subtitle != null
              ? AutoSizeText(
                  tileData.subtitle!,
                )
              : null,
          trailing: trailingWidget,
          initiallyExpanded: selected,
          children: [dataListView],
        );
      },
    );
    return expansionTile;
  }

  Widget _buildListView(BuildContext context) {
    List<Widget> groups = [];
    var controllers = groupDataListController.allData;
    if (controllers.isNotEmpty) {
      for (var entry in controllers.entries) {
        Widget? groupExpansionTile = _buildExpansionTile(
          entry.key,
        );
        if (groupExpansionTile != null) {
          groups.add(groupExpansionTile);
        }
      }
    }
    //该属性将决定列表的长度是否仅包裹其内容的长度。
    //当ListView 嵌在一个无限长的容器组件中时， shrinkWrap 必须为true
    return ListView(shrinkWrap: true, children: groups);
  }

  @override
  Widget build(BuildContext context) {
    return _buildListView(context);
  }
}
