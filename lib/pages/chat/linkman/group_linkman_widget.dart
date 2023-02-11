import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';

///在群的成员中选择联系人的多选或者单选对话框
class GroupLinkmanWidget extends StatelessWidget {
  final Function(List<String>) onSelected; //获取返回的选择
  final List<String> selected;
  final SelectType
      selectType; //查询界面的类型，multi界面无搜索字段，dialog和listview可以包括在showDialog中
  final String groupPeerId;
  String? title;

  GroupLinkmanWidget({
    Key? key,
    required this.onSelected,
    required this.selected,
    this.selectType = SelectType.multidialog,
    required this.groupPeerId,
    this.title,
  }) : super(key: key);

  Future<String?> _findGroupName() async {
    Group? group = await groupService.findCachedOneByPeerId(groupPeerId);
    if (group != null) {
      return group.name;
    }
    return null;
  }

  ///查询群的成员，并生成群成员的选项
  Future<List<Option<String>>> _buildOptions() async {
    title = await _findGroupName();
    var groupMembers = await groupMemberService.findByGroupId(groupPeerId);
    List<Option<String>> options = [];
    for (GroupMember groupMember in groupMembers) {
      String? memberPeerId = groupMember.memberPeerId;
      if (memberPeerId != null) {
        var avatar = await linkmanService.findAvatarImageWidget(memberPeerId);
        bool checked = selected.contains(memberPeerId);
        Option<String> item = Option<String>(
            groupMember.memberAlias!, memberPeerId,
            leading: avatar, checked: checked);
        options.add(item);
      }
    }

    return options;
  }

  ///将群成员的数据转换从列表显示数据TileData
  Future<List<TileData>> _buildTileData() async {
    title = await _findGroupName();
    List<TileData> tiles = [];
    var groupMembers = await groupMemberService.findByGroupId(groupPeerId);
    if (groupMembers.isNotEmpty) {
      for (var groupMember in groupMembers) {
        var title = groupMember.memberAlias!;
        String? memberPeerId = groupMember.memberPeerId;
        if (memberPeerId != null) {
          var avatar = await linkmanService.findAvatarImageWidget(memberPeerId);
          TileData tile = TileData(
            prefix: avatar,
            title: title,
            subtitle: memberPeerId,
            dense: false,
          );
          tiles.add(tile);
        }
      }
    }
    return tiles;
  }

  /// 简单多选对话框的形式，内含一个搜索字段和多选，使用时外部用对话框包裹
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

  /// DataListSingleSelect的单选对话框，一个搜索字段和单选的组合，使用时外部用对话框包裹
  Widget _buildDataListView(BuildContext context) {
    var dataListView = FutureBuilder(
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
          return DataListSingleSelect<String>(
            title: '',
            items: options,
            onChanged: (String? value) {
              onSelected([value!]);
            },
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
