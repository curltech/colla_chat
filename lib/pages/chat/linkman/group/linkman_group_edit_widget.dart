import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/service/chat/chat.dart';

import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
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

class LinkmanGroupEditWidget extends StatefulWidget with TileDataMixin {
  LinkmanGroupEditWidget({Key? key}) : super(key: key);

  @override
  Icon get icon => const Icon(Icons.person);

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

  //选择的群成员
  ValueNotifier<List<String>> groupMembers = ValueNotifier([]);

  //群主的选项
  ValueNotifier<List<Option<String>>> groupOwnerChoices = ValueNotifier([]);

  //当前群
  late ValueNotifier<Group> group;

  //群主peerId
  String? groupOwnerPeerId;

  @override
  initState() {
    groupController.addListener(_update);
    super.initState();
    _init();
  }

  _update() {
    _init();
  }

  _init() async {
    var current = groupController.current;
    if (current != null) {
      group = ValueNotifier(current);
    } else {
      group = ValueNotifier(Group('', ''));
    }
    if (group.value.id != null) {
      groupOwnerPeerId = group.value.groupOwnerPeerId;
      List<String> groupMembers = [];
      List<GroupMember> members =
          await groupMemberService.findByGroupId(group.value.peerId);
      if (members.isNotEmpty) {
        for (GroupMember member in members) {
          groupMembers.add(member.memberPeerId!);
        }
      }
      this.groupMembers.value = groupMembers;
      await _buildGroupOwnerChoices(groupMembers);
    }
  }

  //转向群发界面
  Widget _buildActionTiles(BuildContext context) {
    List<TileData> tileData = [];
    if (group.value.id != null) {
      tileData.add(TileData(
          title: 'Chat',
          prefix: const Icon(Icons.chat),
          routeName: 'chat_message',
          onTap: (int index, String title, {String? subtitle}) async {
            ChatSummary? chatSummary =
                await chatSummaryService.findOneByPeerId(group.value.peerId);
            if (chatSummary != null) {
              chatMessageController.chatSummary = chatSummary;
            }
          }));
      tileData.add(
        TileData(
            title: 'Dismiss group',
            prefix: const Icon(Icons.group_off),
            onTap: (int index, String title, {String? subtitle}) async {
              _dismissGroup();
            }),
      );
    }
    var listView = DataListView(
      tileData: tileData,
    );
    return listView;
  }

  _dismissGroup() async {
    groupService.dismissGroup(group.value);
  }

  //群成员显示和编辑界面
  Widget _buildGroupMembersWidget(BuildContext context) {
    var selector = ValueListenableBuilder(
        valueListenable: groupMembers,
        builder:
            (BuildContext context, List<String> groupMembers, Widget? child) {
          return LinkmanGroupSearchWidget(
            selectType: SelectType.smartselect,
            onSelected: (List<String> selected) async {
              this.groupMembers.value = selected;
              await _buildGroupOwnerChoices(selected);
            },
            selected: this.groupMembers.value,
            includeGroup: false,
          );
        });

    return selector;
  }

  //更新groupOwnerChoices
  _buildGroupOwnerChoices(List<String> selected) async {
    List<Option<String>> groupOwnerChoices = [];
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
          Option<String> item =
              Option<String>(linkman.name, linkman.peerId, checked: checked);
          groupOwnerChoices.add(item);
        }
      }
    }
    this.groupOwnerChoices.value = groupOwnerChoices;
  }

  //群主选择界面
  Widget _buildGroupOwnerWidget(BuildContext context) {
    var selector = ValueListenableBuilder(
        valueListenable: groupOwnerChoices,
        builder: (BuildContext context, List<Option<String>> groupOwnerChoices,
            Widget? child) {
          return SmartSelectUtil.single<String>(
            title: 'GroupOwnerPeer',
            placeholder: 'Select one linkman',
            onChange: (selected) {
              groupOwnerPeerId = selected ?? '';
              if (group.value.id != null) {
                group.value.groupOwnerPeerId = selected;
              }
            },
            items: this.groupOwnerChoices.value,
            // chipOnDelete: (i) {
            //   groupOwnerPeerId.value = '';
            //   if (group != null) {
            //     group!.groupOwnerPeerId = null;
            //   }
            // },
            selectedValue: groupOwnerPeerId ?? '',
          );
        });
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
                      _onOk(values);
                    },
                    columnFieldDefs: groupColumnFieldDefs,
                    initValues: initValues,
                  );
                })));

    return formInputWidget;
  }

  //修改提交
  _onOk(Map<String, dynamic> values) async {
    Group currentGroup = Group.fromJson(values);
    if (StringUtil.isEmpty(currentGroup.name)) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must has group name'));
      return;
    }
    if (StringUtil.isEmpty(groupOwnerPeerId)) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must has group owner'));
      return;
    }
    var group = this.group.value.id != null
        ? this.group.value
        : await groupService.createGroup(currentGroup.name);
    group.alias = currentGroup.alias;
    group.myAlias = currentGroup.myAlias;
    group.mobile = currentGroup.mobile;
    group.email = currentGroup.email;
    group.groupOwnerPeerId = groupOwnerPeerId;
    //group.groupMembers=[];
    if (group.id == null) {
      await groupService.addGroup(group);
      groupController.add(group);
    } else {
      await groupService.modifyGroup(group);
    }
    await groupService.store(group);
    this.group.value = group;
    String groupId = group.peerId;
    List<GroupMember> members =
        await groupMemberService.findByGroupId(group.peerId);
    Map<String, GroupMember> oldMembers = {};
    //所有的现有成员
    if (members.isNotEmpty) {
      for (GroupMember member in members) {
        oldMembers[member.memberPeerId!] = member;
      }
    }
    //新增加的成员
    List<GroupMember> newMembers = [];
    for (var groupMemberId in groupMembers.value) {
      var member = oldMembers[groupMemberId];
      if (member == null) {
        Linkman? linkman =
            await linkmanService.findCachedOneByPeerId(groupMemberId);
        if (linkman != null) {
          GroupMember groupMember = GroupMember();
          groupMember.groupId = groupId;
          groupMember.memberPeerId = groupMemberId;
          groupMember.memberType = MemberType.member.name;
          groupMember.memberAlias = linkman.alias ?? linkman.name;
          groupMember.status = EntityStatus.effective.name;
          await groupMemberService.store(groupMember);
          newMembers.add(groupMember);
        }
      } else {
        oldMembers.remove(groupMemberId);
      }
    }
    await groupService.addGroupMember(groupId, newMembers);
    //处理删除的成员
    if (oldMembers.isNotEmpty) {
      await groupService.removeGroupMember(groupId, oldMembers.values.toList());
      for (GroupMember member in oldMembers.values) {
        oldMembers[member.memberPeerId!] = member;
        await groupMemberService.delete(entity: {'id': member.id});
      }
    }
  }

  Widget _buildGroupEdit(BuildContext context) {
    return Column(
      children: [
        _buildActionTiles(context),
        const SizedBox(
          height: 15,
        ),
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
