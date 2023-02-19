import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';

///联系人和群的查询对话框界面，然后进行单选或者多选
///包装在对话框中，await DialogUtil.show
class LinkmanGroupSearchWidget extends StatefulWidget {
  final Function(List<String>?) onSelected; //获取返回的选择
  final List<String> selected;

  final SelectType selectType;
  final bool includeLinkman;
  final bool includeGroup;

  const LinkmanGroupSearchWidget(
      {Key? key,
      required this.onSelected,
      required this.selected,
      this.selectType = SelectType.chipMultiSelect,
      this.includeLinkman = true,
      this.includeGroup = true})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _LinkmanGroupSearchWidgetState();
}

class _LinkmanGroupSearchWidgetState extends State<LinkmanGroupSearchWidget> {
  String title = '';
  String placeholder = '';

  @override
  initState() {
    super.initState();
    if (widget.includeLinkman && widget.includeGroup) {
      title = 'Linkman and group';
      placeholder = 'linkmen and groups';
    } else if (widget.includeLinkman) {
      title = 'Linkman';
      placeholder = 'linkmen ';
    } else if (widget.includeGroup) {
      title = 'Group';
      placeholder = 'groups';
    }
  }

  Future<List<Option<String>>> _onSearch(String keyword) async {
    List<Linkman> linkmen = <Linkman>[];
    List<Group> groups = <Group>[];
    if (widget.includeLinkman) {
      linkmen = await linkmanService.search(keyword);
    }
    if (widget.includeGroup) {
      groups = await groupService.search(keyword);
    }
    return _buildOptions(linkmen, groups);
  }

  List<Option<String>> _buildOptions(
      List<Linkman> linkmen, List<Group> groups) {
    List<Option<String>> options = [];
    if (widget.includeLinkman) {
      for (Linkman linkman in linkmen) {
        bool checked = widget.selected.contains(linkman.peerId);
        Option<String> item = Option<String>(linkman.name, linkman.peerId,
            checked: checked, leading: linkman.avatarImage);
        options.add(item);
      }
    }
    if (widget.includeGroup) {
      for (Group group in groups) {
        bool checked = widget.selected.contains(group.peerId);
        Option<String> item = Option<String>(group.name, group.peerId,
            checked: checked, leading: group.avatarImage);
        options.add(item);
      }
    }

    return options;
  }

  /// 复杂多选对话框样式，选择项通过传入的回调方法返回
  Widget _buildChipMultiSelectField(BuildContext context) {
    var selector = CustomMultiSelectField(
      title: title,
      prefix: Icon(
        Icons.person_add,
        color: myself.primary,
      ),
      onSearch: _onSearch,
      onConfirm: (selected) {
        widget.onSelected(selected);
      },
    );

    return selector;
  }

  /// 简单多选字段，选择项通过传入的回调方法返回
  Widget _buildDataListMultiSelectField(BuildContext context) {
    var selector = CustomMultiSelectField(
      title: title,
      prefix: Icon(
        Icons.person_add,
        color: myself.primary,
      ),
      onSearch: _onSearch,
      onConfirm: (selected) {
        widget.onSelected(selected);
      },
      selectType: SelectType.dataListMultiSelect,
    );

    return selector;
  }

  /// 简单多选对话框，使用时外部用对话框包裹
  Widget _buildChipMultiSelect(BuildContext context) {
    var selector = CustomMultiSelect(
      onSearch: _onSearch,
      onConfirm: (selected) {
        widget.onSelected(selected);
      },
      title: title,
    );
    return selector;
  }

  Widget _buildDataListMultiSelect(BuildContext context) {
    return CustomMultiSelect(
      onSearch: _onSearch,
      onConfirm: (selected) {
        widget.onSelected(selected);
      },
      selectType: SelectType.dataListMultiSelect,
      title: title,
    );
  }

  /// DataListView的单选对话框，使用时外部用对话框包裹
  Widget _buildDataListSingleSelect(BuildContext context) {
    var dataListView = DataListSingleSelect(
      onSearch: _onSearch,
      onChanged: (String? value) {
        widget.onSelected([value!]);
      },
      title: title,
    );
    return dataListView;
  }

  Widget _buildDataListSingleSelectField(BuildContext context) {
    var dataListView = CustomSingleSelectField(
      onSearch: _onSearch,
      onChanged: (String? value) {
        widget.onSelected([value!]);
      },
      title: title,
    );
    return dataListView;
  }

  @override
  Widget build(BuildContext context) {
    Widget selector;
    switch (widget.selectType) {
      case SelectType.chipMultiSelectField:
        selector = _buildChipMultiSelectField(context);
        break;
      case SelectType.dataListMultiSelectField:
        selector = _buildDataListMultiSelectField(context);
        break;
      case SelectType.chipMultiSelect:
        selector = _buildChipMultiSelect(context);
        break;
      case SelectType.dataListMultiSelect:
        selector = _buildDataListMultiSelect(context);
        break;
      case SelectType.singleSelect:
        selector = _buildDataListSingleSelect(context);
        break;
      case SelectType.singleSelectField:
        selector = _buildDataListSingleSelectField(context);
        break;
      default:
        selector = _buildChipMultiSelectField(context);
    }
    return selector;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
