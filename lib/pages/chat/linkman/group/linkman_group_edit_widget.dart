import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

final List<ColumnFieldDef> groupColumnFieldDefs = [
  ColumnFieldDef(
      name: 'peerId',
      label: 'PeerId',
      inputType: InputType.label,
      prefixIcon: const Icon(Icons.perm_identity)),
  ColumnFieldDef(
      name: 'name', label: 'Name', prefixIcon: const Icon(Icons.person)),
  ColumnFieldDef(
      name: 'alias',
      label: 'Alias',
      prefixIcon: const Icon(Icons.perm_identity)),
  ColumnFieldDef(
      name: 'myAlias',
      label: 'MyAlias',
      prefixIcon: const Icon(Icons.person_pin)),
];

///创建和修改群，填写群的基本信息，选择群成员和群主
class LinkmanGroupEditWidget extends StatefulWidget with TileDataMixin {
  LinkmanGroupEditWidget({Key? key}) : super(key: key);

  @override
  IconData get iconData => Icons.person;

  @override
  String get routeName => 'linkman_group_edit';

  @override
  String get title => 'Linkman edit group';

  @override
  bool get withLeading => true;

  @override
  State<StatefulWidget> createState() => _LinkmanGroupEditWidgetState();
}

class _LinkmanGroupEditWidgetState extends State<LinkmanGroupEditWidget> {
  TextEditingController controller = TextEditingController();

  OptionController groupOwnerController = OptionController();

  //选择的群成员
  ValueNotifier<List<String>> groupMembers = ValueNotifier([]);

  //群主的选项
  // ValueNotifier<List<Option<String>>> groupOwnerOptions = ValueNotifier([]);

  //当前群
  ValueNotifier<Group> group = ValueNotifier(Group('', ''));

  @override
  initState() {
    groupController.addListener(_update);
    super.initState();
    _buildGroupData();
  }

  _update() {
    _buildGroupData();
  }

  _buildGroupData() async {
    var current = groupController.current;
    if (current != null) {
      group.value = current;
    } else {
      group.value = Group('', '');
    }
    if (group.value.id != null) {
      List<String> groupMembers = [];
      List<GroupMember> members =
          await groupMemberService.findByGroupId(group.value.peerId);
      if (members.isNotEmpty) {
        for (GroupMember member in members) {
          groupMembers.add(member.memberPeerId!);
        }
      }
      this.groupMembers.value = groupMembers;
      await _buildGroupOwnerOptions(groupMembers);
    }
  }

  //更新groupOwnerChoices
  _buildGroupOwnerOptions(List<String> selected) async {
    group.value.groupOwnerPeerId ??= myself.peerId;
    group.value.groupOwnerName ??= myself.name;
    List<Option<String>> groupOwnerOptions = [];
    if (selected.isNotEmpty) {
      for (String groupMemberId in selected) {
        Linkman? linkman =
            await linkmanService.findCachedOneByPeerId(groupMemberId);
        bool checked = false;
        if (linkman != null) {
          if (group.value.groupOwnerPeerId != null) {
            String peerId = group.value.groupOwnerPeerId!;
            if (linkman.peerId == peerId) {
              checked = true;
            }
          }
          Option<String> option = Option<String>(linkman.name, linkman.peerId,
              checked: checked, leading: linkman.avatarImage);
          groupOwnerOptions.add(option);
        } else {
          logger.e('Group member $groupMemberId is not linkman');
          if (mounted) {
            DialogUtil.error(context,
                content: 'Group member $groupMemberId is not linkman');
          }
        }
      }
    }
    groupOwnerController.options = groupOwnerOptions;
  }

  //群成员显示和编辑界面
  Widget _buildGroupMembersWidget(BuildContext context) {
    var selector = ValueListenableBuilder(
        valueListenable: groupMembers,
        builder:
            (BuildContext context, List<String> groupMembers, Widget? child) {
          return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: LinkmanGroupSearchWidget(
                selectType: SelectType.dataListMultiSelectField,
                onSelected: (List<String>? selected) async {
                  if (selected != null) {
                    this.groupMembers.value = selected;
                    await _buildGroupOwnerOptions(selected);
                  }
                },
                selected: this.groupMembers.value,
                includeGroup: false,
              ));
        });

    return selector;
  }

  //群主选择界面
  Widget _buildGroupOwnerWidget(BuildContext context) {
    var selector = Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: CustomSingleSelectField(
            title: 'GroupOwnerPeer',
            onChanged: (selected) {
              if (selected != null) {
                group.value.groupOwnerPeerId = selected;
                var options = groupOwnerController.options;
                for (var option in options) {
                  if (option.value == selected) {
                    group.value.groupOwnerName = option.label;
                    break;
                  }
                }
              } else {
                DialogUtil.error(context,
                    content: AppLocalizations.t('Must has group owner'));
              }
            },
            optionController: groupOwnerController));

    return selector;
  }

  //群信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    var formInputWidget = SingleChildScrollView(
        child: Container(
            padding: const EdgeInsets.all(15.0),
            child: ValueListenableBuilder(
                valueListenable: group,
                builder: (BuildContext context, Group? group, Widget? child) {
                  Map<String, dynamic>? initValues = {};
                  if (group != null) {
                    initValues = groupController
                        .getInitValue(groupColumnFieldDefs, entity: group);
                  }
                  return FormInputWidget(
                    onOk: (Map<String, dynamic> values) {
                      _onOk(values).then((group) {
                        if (group != null) {
                          DialogUtil.info(context,
                              content: 'Group ${group!.name} is built');
                        }
                      });
                    },
                    columnFieldDefs: groupColumnFieldDefs,
                    initValues: initValues,
                  );
                })));

    return formInputWidget;
  }

  //修改提交
  Future<Group?> _onOk(Map<String, dynamic> values) async {
    bool groupModified = false;
    Group currentGroup = Group.fromJson(values);
    if (StringUtil.isEmpty(currentGroup.name)) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must has group name'));
      return null;
    }
    if (StringUtil.isEmpty(group.value.groupOwnerPeerId)) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must has group owner'));
      return null;
    }
    var current = groupController.current;
    if (current == null) {
      current = await groupService.createGroup(currentGroup.name);
      groupModified = true;
    }
    if (current.myAlias != currentGroup.myAlias) {
      current.myAlias = currentGroup.myAlias;
      groupModified = true;
    }
    if (current.alias != currentGroup.alias) {
      current.alias = currentGroup.alias;
      groupModified = true;
    }
    if (current.mobile != currentGroup.mobile) {
      current.mobile = currentGroup.mobile;
      groupModified = true;
    }
    if (current.email != currentGroup.email) {
      current.email = currentGroup.email;
      groupModified = true;
    }
    bool add = true;
    if (current.id != null) {
      add = false;
    }
    current.groupOwnerPeerId = group.value.groupOwnerPeerId ?? myself.peerId;
    for (var option in groupOwnerController.options) {
      if (option.value == current.groupOwnerPeerId) {
        current.groupOwnerName = option.label;
        break;
      }
    }
    var participants = groupMembers.value;
    if (!participants.contains(myself.peerId!)) {
      participants.add(myself.peerId!);
      groupMembers.value = [...participants];
    }
    current.participants = groupMembers.value;
    List<Object> gs = await groupService.store(current);
    group.value = current;
    var groupId = current.peerId;

    //对所有的成员发送组变更的消息
    if (add) {
      await groupService.addGroup(current);
    } else if (groupModified) {
      await groupService.modifyGroup(current);
    }
    //新增加的成员
    Object newMembers = gs[1];
    if (newMembers is List<GroupMember> && newMembers.isNotEmpty) {
      //对所有的成员发送组员增加的消息
      await groupService.addGroupMember(groupId, newMembers);
    }

    Object oldMembers = gs[2];
    //处理删除的成员
    if (oldMembers is List<GroupMember> && oldMembers.isNotEmpty) {
      //对所有的成员发送组员删除的消息
      await groupService.removeGroupMember(groupId, oldMembers);
    }

    if (groupController.current == null) {
      groupController.add(current);
    }
    if (add || groupModified) {
      groupChatSummaryController.refresh();
    }

    return current;
  }

  Widget _buildGroupEdit(BuildContext context) {
    return Column(
      children: [
        _buildGroupMembersWidget(context),
        const SizedBox(
          height: 5,
        ),
        _buildGroupOwnerWidget(context),
        const SizedBox(
          height: 5,
        ),
        Expanded(child: _buildFormInputWidget(context)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: _buildGroupEdit(context));
    return appBarView;
  }

  @override
  void dispose() {
    groupController.removeListener(_update);
    controller.dispose();
    super.dispose();
  }
}
