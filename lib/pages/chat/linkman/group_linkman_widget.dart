import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';

///在群的成员中选择联系人的多选或者单选对话框
class GroupLinkmanWidget extends StatelessWidget {
  final Function(List<String>) onSelected; //获取返回的选择
  final List<String> selected;
  final SelectType selectType;
  final String groupPeerId;
  String? title;
  final OptionController optionController = OptionController();

  GroupLinkmanWidget({
    Key? key,
    required this.onSelected,
    required this.selected,
    this.selectType = SelectType.chipMultiSelect,
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
    optionController.options = options;

    return options;
  }

  /// 简单多选对话框，使用时外部用对话框包裹
  Widget _buildDialogWidget(BuildContext context, Widget child) {
    var size = MediaQuery.of(context).size;
    var selector = Center(
        child: Container(
      color: Colors.white,
      width: size.width * 0.9,
      height: size.height * 0.9,
      alignment: Alignment.center,
      child: Column(children: [
        AppBarWidget.buildTitleBar(
            title: Text(
          AppLocalizations.t(title!),
          style: const TextStyle(fontSize: 16, color: Colors.white),
        )),
        const SizedBox(
          height: 10,
        ),
        Expanded(child: child),
      ]),
    ));
    return selector;
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
          return CustomMultiSelect(
            onConfirm: (selected) {
              onSelected(selected!);
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
          return CustomMultiSelect(
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
          return DataListSingleSelect(
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
        selector =
            _buildDialogWidget(context, _buildDataListMultiSelect(context));
        break;
      case SelectType.chipMultiSelect:
        selector = _buildDialogWidget(context, _buildChipMultiSelect(context));
        break;
      case SelectType.singleSelect:
        selector =
            _buildDialogWidget(context, _buildDataListSingleSelect(context));
        break;
      default:
        selector = _buildDialogWidget(context, _buildChipMultiSelect(context));
    }
    return selector;
  }
}
