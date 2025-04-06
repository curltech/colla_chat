import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///在群的成员中选择联系人的多选或者单选对话框
class GroupLinkmanWidget extends StatelessWidget {
  final Function(List<String>) onSelected; //获取返回的选择
  final List<String> selected;
  final SelectType selectType;
  final String groupId;

  GroupLinkmanWidget({
    super.key,
    required this.onSelected,
    required this.selected,
    this.selectType = SelectType.chipMultiSelect,
    required this.groupId,
  });

  final Rx<String?> title = Rx<String?>(null);
  final OptionController optionController = OptionController();

  Future<String?> _findGroupName() async {
    Group? group = await groupService.findCachedOneByPeerId(groupId);
    if (group != null) {
      return group.name;
    }
    return null;
  }

  ///查询群的成员，并生成群成员的选项
  Future<List<Option<String>>> _buildOptions() async {
    title.value = await _findGroupName();
    var groupMembers = await groupMemberService.findByGroupId(groupId);
    List<Option<String>> options = [];
    for (GroupMember groupMember in groupMembers) {
      String? memberPeerId = groupMember.memberPeerId;
      if (memberPeerId != null) {
        var avatar = await linkmanService.findAvatarImageWidget(memberPeerId);
        bool checked = selected.contains(memberPeerId);
        Option<String> item = Option<String>(
            groupMember.memberAlias!, memberPeerId,
            leading: avatar, selected: checked, hint: '');
        options.add(item);
      }
    }

    return options;
  }

  /// 简单多选对话框的形式，内含一个搜索字段和多选，使用时外部用对话框包裹
  Widget _buildChipMultiSelect(BuildContext context) {
    var selector = PlatformFutureBuilder(
        future: _buildOptions(),
        builder: (BuildContext context, List<Option<String>> options) {
          optionController.options = options;
          return CustomMultiSelect(
            title: title.value,
            onConfirm: (selected) {
              if (selected == null) {
                onSelected([]);
              } else {
                onSelected(selected);
              }
            },
            optionController: optionController,
          );
        });
    return selector;
  }

  Widget _buildDataListMultiSelect(BuildContext context) {
    var selector = PlatformFutureBuilder(
        future: _buildOptions(),
        builder: (BuildContext context, List<Option<String>> options) {
          optionController.options = options;
          return CustomMultiSelect(
            title: title.value,
            onConfirm: (selected) {
              onSelected(selected!);
            },
            optionController: optionController,
          );
        });
    return selector;
  }

  /// DataListSingleSelect的单选对话框，一个搜索字段和单选的组合，使用时外部用对话框包裹
  Widget _buildDataListSingleSelect(BuildContext context) {
    var dataListView = PlatformFutureBuilder(
        future: _buildOptions(),
        builder: (BuildContext context, List<Option<String>> options) {
          optionController.options = options;
          return DataListSingleSelect(
            title: title.value,
            optionController: optionController,
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
