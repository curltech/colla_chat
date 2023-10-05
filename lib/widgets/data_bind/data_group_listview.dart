import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class GroupDataListController with ChangeNotifier {
  final Map<TileData, DataListController<TileData>> controllers = {};

  GroupDataListController({Map<TileData, List<TileData>> tileData = const {}}) {
    _addAll(tileData: tileData);
  }

  DataListController<TileData>? get(TileData tile) {
    return controllers[tile];
  }

  _addAll({required Map<TileData, List<TileData>> tileData}) {
    if (tileData.isNotEmpty) {
      for (var tileEntry in tileData.entries) {
        int? currentIndex;
        DataListController<TileData>? dataListController =
            controllers[tileEntry.key];
        if (dataListController != null) {
          currentIndex = dataListController.currentIndex;
        }
        dataListController = DataListController<TileData>(
            data: tileEntry.value, currentIndex: currentIndex);
        controllers[tileEntry.key] = dataListController;
      }
    }
  }

  addAll({required Map<TileData, List<TileData>> tileData}) {
    if (tileData.isNotEmpty) {
      _addAll(tileData: tileData);
      notifyListeners();
    }
  }

  add(TileData tile, List<TileData> tileData) {
    int? currentIndex;
    DataListController<TileData>? dataListController = controllers[tile];
    if (dataListController != null) {
      currentIndex = dataListController.currentIndex;
    }
    dataListController = DataListController<TileData>(
        data: tileData, currentIndex: currentIndex);
    controllers[tile] = dataListController;
    notifyListeners();
  }

  remove(TileData tile) {
    if (controllers.containsKey(tile)) {
      controllers.remove(tile);
      notifyListeners();
    }
  }
}

class GroupDataListView extends StatefulWidget {
  late final GroupDataListController controller;
  final Function(int index, String title, {String? subtitle, TileData? group})?
      onTap;

  GroupDataListView(
      {Key? key,
      GroupDataListController? controller,
      Map<TileData, List<TileData>> tileData = const {},
      this.onTap})
      : super(key: key) {
    if (controller != null) {
      this.controller = controller;
    } else {
      this.controller = GroupDataListController(tileData: tileData);
    }
  }

  @override
  State<StatefulWidget> createState() {
    return _GroupDataListViewState();
  }
}

class _GroupDataListViewState extends State<GroupDataListView> {
  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
    myself.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
    //logger.w('index: $index, title: $title,onTap GroupDataListView');
    var onTap = widget.onTap;
    if (onTap != null) {
      onTap(index, title, subtitle: subtitle, group: group);
    }
  }

  Widget? _buildExpansionTile(TileData tileData) {
    var dataListController = widget.controller.get(tileData);
    if (dataListController == null) {
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
        onTap: _onTap, group: tileData, controller: dataListController);
    bool selected = tileData.selected ?? false;

    /// 未来不使用ListTile，因为高度固定，不够灵活
    ExpansionTile expansionTile = ExpansionTile(
      childrenPadding: const EdgeInsets.all(0),
      maintainState: true,
      leading: leading,
      textColor: selected ? myself.primary : null,
      title: CommonAutoSizeText(
        AppLocalizations.t(tileData.title),
      ),
      subtitle: tileData.subtitle != null
          ? CommonAutoSizeText(
              tileData.subtitle!,
            )
          : null,
      trailing: trailingWidget,
      initiallyExpanded: true,
      children: [dataListView],
    );

    return expansionTile;
  }

  Widget _buildListView(BuildContext context) {
    List<Widget> groups = [];
    var controllers = widget.controller.controllers;
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

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    myself.removeListener(_update);
    super.dispose();
  }
}
