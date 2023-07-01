import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';

///在群的成员中选择联系人的多选或者单选对话框
class GroupLinkmanWidget extends StatefulWidget {
  final Function(List<String>) onSelected; //获取返回的选择
  final List<String> selected;
  final SelectType selectType;
  final String groupId;

  const GroupLinkmanWidget({
    Key? key,
    required this.onSelected,
    required this.selected,
    this.selectType = SelectType.chipMultiSelect,
    required this.groupId,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupLinkmanWidgetState();
}

class _GroupLinkmanWidgetState extends State<GroupLinkmanWidget> {
  String? title;
  OptionController optionController = OptionController();

  @override
  initState() {
    super.initState();
  }

  Future<String?> _findGroupName() async {
    Group? group = await groupService.findCachedOneByPeerId(widget.groupId);
    if (group != null) {
      return group.name;
    }
    return null;
  }

  ///查询群的成员，并生成群成员的选项
  Future<List<Option<String>>> _buildOptions() async {
    title = await _findGroupName();
    var groupMembers =
        await groupMemberService.findByGroupId(widget.groupId);
    List<Option<String>> options = [];
    for (GroupMember groupMember in groupMembers) {
      String? memberPeerId = groupMember.memberPeerId;
      if (memberPeerId != null) {
        var avatar = await linkmanService.findAvatarImageWidget(memberPeerId);
        bool checked = widget.selected.contains(memberPeerId);
        Option<String> item = Option<String>(
            groupMember.memberAlias!, memberPeerId,
            leading: avatar, checked: checked);
        options.add(item);
      }
    }

    return options;
  }

  /// 简单多选对话框的形式，内含一个搜索字段和多选，使用时外部用对话框包裹
  Widget _buildChipMultiSelect(BuildContext context) {
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
          optionController.options = options;
          return CustomMultiSelect(
            title: title,
            onConfirm: (selected) {
              widget.onSelected(selected!);
            },
            optionController: optionController,
          );
        });
    return selector;
  }

  Widget _buildDataListMultiSelect(BuildContext context) {
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
          optionController.options = options;
          return CustomMultiSelect(
            title: title,
            onConfirm: (selected) {
              widget.onSelected(selected!);
            },
            optionController: optionController,
          );
        });
    return selector;
  }

  /// DataListSingleSelect的单选对话框，一个搜索字段和单选的组合，使用时外部用对话框包裹
  Widget _buildDataListSingleSelect(BuildContext context) {
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
          optionController.options = options;
          return DataListSingleSelect(
            title: title,
            optionController: optionController,
            onChanged: (String? value) {
              widget.onSelected([value!]);
            },
          );
        });
    return Container(padding: const EdgeInsets.all(10.0), child: dataListView);
  }

  @override
  Widget build(BuildContext context) {
    Widget selector;
    switch (widget.selectType) {
      case SelectType.dataListMultiSelect:
        selector = _buildDataListMultiSelect(context);
        break;
      case SelectType.chipMultiSelect:
        selector = _buildChipMultiSelect(context);
        break;
      case SelectType.singleSelect:
        selector = _buildDataListSingleSelect(context);
        break;
      default:
        selector = _buildChipMultiSelect(context);
    }
    return selector;
  }
}
