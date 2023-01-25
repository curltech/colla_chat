import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/group/linkman_group_edit_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

///选择linkman建群
class LinkmanGroupAddWidget extends StatefulWidget with TileDataMixin {
  final DataListController<Linkman> linkmenController =
      DataListController<Linkman>();

  LinkmanGroupAddWidget({Key? key}) : super(key: key);

  @override
  Icon get icon => const Icon(Icons.person);

  @override
  String get routeName => 'linkman_group_add';

  @override
  String get title => 'Linkman add group';

  @override
  bool get withLeading => true;

  @override
  State<StatefulWidget> createState() => _LinkmanGroupAddWidgetState();
}

class _LinkmanGroupAddWidgetState extends State<LinkmanGroupAddWidget> {
  TextEditingController controller = TextEditingController();

  //选择的群成员
  ValueNotifier<List<String>> groupMembers = ValueNotifier([]);

  //群主的选项
  ValueNotifier<List<Option<String>>> groupOwnerChoices = ValueNotifier([]);

  //当前群
  Group? group;

  //群主peerId
  String groupOwnerPeerId = '';

  @override
  initState() {
    super.initState();
    widget.linkmenController.addListener(_update);
    _init();
  }

  _update() {
    setState(() {});
  }

  _init() async {
    if (group != null) {
      groupMembers.value.clear();
      List<GroupMember> members =
          await groupMemberService.findByGroupId(group!.peerId);
      if (members.isNotEmpty) {
        for (GroupMember member in members) {
          groupMembers.value.add(member.memberPeerId!);
        }
      }
      await _buildGroupOwnerChoices(groupMembers.value);
    }
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
          if (group != null && group!.groupOwnerPeerId != null) {
            String peerId = group!.groupOwnerPeerId!;
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
              if (group != null) {
                group!.groupOwnerPeerId = selected;
              }
            },
            items: this.groupOwnerChoices.value,
            // chipOnDelete: (i) {
            //   groupOwnerPeerId.value = '';
            //   if (group != null) {
            //     group!.groupOwnerPeerId = null;
            //   }
            // },
            selectedValue: groupOwnerPeerId,
          );
        });
    return selector;
  }

  //群信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    Map<String, dynamic>? initValues =
        groupController.getInitValue(groupColumnFieldDefs);

    var formInputWidget = SingleChildScrollView(
        child: Container(
            padding: const EdgeInsets.all(15.0),
            child: FormInputWidget(
              onOk: (Map<String, dynamic> values) {
                _onOk(values);
              },
              columnFieldDefs: groupColumnFieldDefs,
              initValues: initValues,
            )));

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
    group ??= await groupService.createGroup(currentGroup.name);
    group!.alias = currentGroup.alias;
    group!.mobile = currentGroup.mobile;
    group!.email = currentGroup.email;
    if (group!.groupOwnerPeerId != currentGroup.groupOwnerPeerId) {
      group!.groupOwnerPeerId = currentGroup.groupOwnerPeerId;
    }
    if (group!.id == null) {
      await groupService.addGroup(group!);
    } else {
      await groupService.modifyGroup(group!);
    }
    await groupService.store(group!);

    String groupId = group!.peerId;
    List<GroupMember> members =
        await groupMemberService.findByGroupId(group!.peerId);
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
          groupMemberService.store(groupMember);
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
        groupMemberService.delete(entity: {'id': member.id});
      }
    }
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
    widget.linkmenController.removeListener(_update);
    controller.dispose();
    super.dispose();
  }
}
