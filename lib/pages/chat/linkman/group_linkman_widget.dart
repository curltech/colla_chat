import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';

///在群中选择联系人
class GroupLinkmanWidget extends StatelessWidget {
  final Function(List<String>) onSelected; //获取返回的选择
  final List<String> selected;
  final SelectType
      selectType; //查询界面的类型，multi界面无搜索字段，dialog和listview可以包括在showDialog中
  final String peerId;
  String? title;

  GroupLinkmanWidget({
    Key? key,
    required this.onSelected,
    required this.selected,
    this.selectType = SelectType.multidialog,
    required this.peerId,
    this.title,
  }) : super(key: key);

  Future<String?> _findGroupName() async {
    Group? group = await groupService.findCachedOneByPeerId(peerId);
    if (group != null) {
      return group.name;
    }
    return null;
  }

  Future<List<Option<String>>> _buildOptions() async {
    title = await _findGroupName();
    var groupMembers = await groupMemberService.findByGroupId(peerId);
    List<Option<String>> options = [];
    for (GroupMember groupMember in groupMembers) {
      bool checked = selected.contains(groupMember.memberPeerId);
      Option<String> item = Option<String>(
          groupMember.memberAlias!, groupMember.memberPeerId!,
          checked: checked);
      options.add(item);
    }

    return options;
  }

  /// 一个搜索字段和一个多选字段的组合，对话框的形式，使用时外部用对话框包裹
  Widget _buildMultiSelectDialog(BuildContext context) {
    var selector = FutureBuilder(
        future: _buildOptions(),
        builder: (BuildContext context,
            AsyncSnapshot<List<Option<String>>> snapshot) {
          var hasData = snapshot.hasData;
          if (!hasData) {
            return Container();
          }
          List<Option<String>>? options = snapshot.data;
          if (options == null) {
            return Container();
          }
          return MultiSelectUtil.buildMultiSelectDialog<String>(
            title: AppBarWidget.buildTitleBar(
                title: Text(
              title ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            )),
            onConfirm: (selected) {
              onSelected(selected);
            },
            items: options,
          );
        });
    return selector;
  }

  //将linkman数据转换从列表显示数据
  Future<List<TileData>> _buildTileData() async {
    title = await _findGroupName();
    List<TileData> tiles = [];
    var groupMembers = await groupMemberService.findByGroupId(peerId);
    if (groupMembers.isNotEmpty) {
      for (var groupMember in groupMembers) {
        var title = groupMember.memberAlias!;
        var subtitle = groupMember.memberPeerId;
        TileData tile = TileData(
          //prefix: groupMember.avatar,
          title: title,
          subtitle: subtitle,
          dense: false,
        );
        tiles.add(tile);
      }
    }
    return tiles;
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
    onSelected([subtitle!]);
  }

  /// 一个搜索字段和一个单选选字段的组合，对话框的形式，使用时外部用对话框包裹
  Widget _buildDataListView(BuildContext context) {
    var dataListView = FutureBuilder(
        future: _buildTileData(),
        builder:
            (BuildContext context, AsyncSnapshot<List<TileData>> snapshot) {
          var hasData = snapshot.hasData;
          if (!hasData) {
            return Container();
          }
          List<TileData>? tiles = snapshot.data;
          if (tiles == null) {
            return Container();
          }
          return DataListView(
            tileData: tiles,
            onTap: _onTap,
          );
        });
    return Container(padding: const EdgeInsets.all(10.0), child: dataListView);
  }

  @override
  Widget build(BuildContext context) {
    Widget selector;
    switch (selectType) {
      case SelectType.multidialog:
        selector = _buildMultiSelectDialog(context);
        break;
      case SelectType.listview:
        selector = _buildDataListView(context);
        break;
      default:
        selector = _buildMultiSelectDialog(context);
    }
    return selector;
  }
}
