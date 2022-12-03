import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/group/linkman_group_edit_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_search_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/chat/contact.dart';
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
  List<String> groupMembers = [];
  List<Option<String>> groupOwnerChoices = [];
  Group? group;

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
    List<Linkman> linkmen = await linkmanService.findAll();
    if (linkmen.isNotEmpty) {
      widget.linkmenController.replaceAll(linkmen);
    }
    if (group != null) {
      groupMembers.clear();
      List<GroupMember> members =
          await groupMemberService.findByGroupId(group!.peerId);
      if (members.isNotEmpty) {
        for (GroupMember member in members) {
          groupMembers.add(member.memberPeerId!);
        }
      }
      await _buildGroupOwnerChoices();
    }
  }

  //groupMembers变化后重新更新groupOwnerChoices
  _buildGroupOwnerChoices() async {
    groupOwnerChoices.clear();
    if (groupMembers.isNotEmpty) {
      for (String groupMemberId in groupMembers) {
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
  }

  //群主选择界面
  Widget _buildGroupOwnerWidget(BuildContext context) {
    return SmartSelectUtil.single<String>(
      title: 'GroupOwnerPeer',
      placeholder: 'Select one linkman',
      onChange: (selected) => setState(() {
        if (group != null) {
          group!.groupOwnerPeerId = selected;
        }
      }),
      items: groupOwnerChoices,
      chipOnDelete: (i) {
        setState(() {
          group!.groupOwnerPeerId = null;
        });
      },
      selectedValue: '',
    );
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
    var peerId = values['peerId'];
    var name = values['name'];
    if (peerId != null) {
      Group currentGroup = Group.fromJson(values);
      group!.alias = currentGroup.alias;
      group!.mobile = currentGroup.mobile;
      group!.email = currentGroup.email;
      if (group!.groupOwnerPeerId != currentGroup.groupOwnerPeerId) {
        group!.groupOwnerPeerId = currentGroup.groupOwnerPeerId;
      }
      await groupService.modifyGroup(group!);
    } else {
      // 加群
      group = await groupService.createGroup(name);
      await groupService.addGroup(group!);
    }
    await groupService.store(group!);

    String groupId = group!.peerId;
    List<GroupMember> members =
        await groupMemberService.findByGroupId(group!.peerId);
    Map<String, GroupMember> oldMembers = {};
    if (members.isNotEmpty) {
      for (GroupMember member in members) {
        oldMembers[member.memberPeerId!] = member;
      }
    }
    List<GroupMember> newMembers = [];
    for (var groupMemberId in groupMembers) {
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
    if (oldMembers.isNotEmpty) {
      await groupService.removeGroupMember(groupId, oldMembers.values.toList());
      for (GroupMember member in oldMembers.values) {
        oldMembers[member.memberPeerId!] = member;
        groupMemberService.delete(entity: {'id': member.id});
      }
    }
  }

  //群成员显示和编辑界面
  Widget _buildGroupMembersWidget(BuildContext context) {
    var selector = LinkmanSearchWidget(
      selectType: SelectType.multiselect,
      onSelected: (List<String> selected) {
        logger.i(selected);
      },
      selected: [],
    );

    return selector;
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
        title: Text(AppLocalizations.t(widget.title)),
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
