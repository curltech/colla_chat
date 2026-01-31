import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

class GroupDataListController {
  final Map<DataTile, List<DataTile>> allData = <DataTile, List<DataTile>>{};

  GroupDataListController({Map<DataTile, List<DataTile>> tileData = const {}}) {
    _addAll(tileData: tileData);
  }

  List<DataTile>? get(DataTile tile) {
    return allData[tile];
  }

  void _addAll({required Map<DataTile, List<DataTile>> tileData}) {
    allData.addEntries(tileData.entries);
  }

  void addAll({required Map<DataTile, List<DataTile>> tileData}) {
    if (tileData.isNotEmpty) {
      _addAll(tileData: tileData);
    }
  }

  void add(DataTile tile, List<DataTile> tileData) {
    List<DataTile>? data = allData[tile];
    data ??= [];
    data.addAll([...tileData]);
    allData[tile] = data;
  }

  void remove(DataTile tile) {
    if (allData.containsKey(tile)) {
      allData.remove(tile);
    }
  }
}

/// 可扩展的列表，如果某行的子列表不为空，则显示为可扩展的列表，否则显示为直接可点击的行
class GroupDataListView extends StatelessWidget {
  final double? dividerHeight;
  final Color? dividerColor;
  late final GroupDataListController groupDataListController;
  final Future<bool?> Function(int index, String title,
      {String? subtitle, DataTile? group})? onTap;

  GroupDataListView(
      {super.key,
      this.dividerHeight,
      this.dividerColor,
      GroupDataListController? controller,
      Map<DataTile, List<DataTile>> tileData = const {},
      this.onTap}) {
    if (controller != null) {
      groupDataListController = controller;
    } else {
      groupDataListController = GroupDataListController(tileData: tileData);
    }
  }

  Future<bool?> _onTap(int index, String title,
      {String? subtitle, DataTile? group}) async {
    var onTap = this.onTap;
    if (onTap != null) {
      return await onTap(index, title, subtitle: subtitle, group: group);
    }
    return null;
  }

  Widget _buildExpansionTile(DataTile tileData) {
    List<DataTile>? data = groupDataListController.get(tileData);
    if (data == null) {
      throw 'group tileData error';
    }
    Widget? leading = tileData.getPrefixWidget(tileData.selected ?? false);
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
      dividerHeight: dividerHeight,
      onTap: (int index, String title, {String? subtitle}) async {
        return _onTap(index, title, subtitle: subtitle, group: tileData);
      },
      itemCount: data.length,
      itemBuilder: (BuildContext context, int index) {
        return data[index];
      },
    );
    bool selected = tileData.selected ?? false;

    Widget expansionTile = ListenableBuilder(
      listenable: myself,
      builder: (BuildContext context, Widget? child) {
        return ExpansionTile(
          childrenPadding: const EdgeInsets.only(left: 32, right: 5),
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
    List<Widget> groupWidgets = [];
    Map<DataTile, List<DataTile>> tileData = groupDataListController.allData;
    if (tileData.isNotEmpty) {
      for (var entry in tileData.entries) {
        DataTile groupTileData = entry.key;
        List<DataTile> tileData = entry.value;
        Widget groupWidget;
        if (tileData.isEmpty) {
          groupWidget = DataListTile.buildListTile(
              dividerHeight: dividerHeight,
              dividerColor: dividerColor,
              groupTileData, onTap: (
            int index,
            String title, {
            String? subtitle,
            DataTile? group,
          }) async {
            return await _onTap(index, title,
                subtitle: subtitle, group: groupTileData);
          });
        } else {
          groupWidget = _buildExpansionTile(groupTileData);
        }
        groupWidgets.add(groupWidget);
      }
    }
    //该属性将决定列表的长度是否仅包裹其内容的长度。
    //当ListView 嵌在一个无限长的容器组件中时， shrinkWrap 必须为true
    return ListView(shrinkWrap: true, children: groupWidgets);
  }

  @override
  Widget build(BuildContext context) {
    return _buildListView(context);
  }
}
