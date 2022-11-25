import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';

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

///群的编辑界面，改变群拥有者，增减群成员，改变群的名称
class LinkmanGroupEditWidget extends StatefulWidget with TileDataMixin {
  final DataListController<Linkman> linkmenController =
      DataListController<Linkman>();

  LinkmanGroupEditWidget({Key? key}) : super(key: key);

  @override
  Icon get icon => const Icon(Icons.groups_sharp);

  @override
  String get routeName => 'linkman_group_edit';

  @override
  String get title => 'LinkmanGroupEdit';

  @override
  bool get withLeading => true;

  @override
  State<StatefulWidget> createState() => _LinkmanGroupEditWidgetState();
}

class _LinkmanGroupEditWidgetState extends State<LinkmanGroupEditWidget> {
  List<String> groupMembers = [];
  List<S2Choice<String>> groupOwnerChoices = [];
  Group? group;

  @override
  initState() {
    super.initState();
    groupController.addListener(_update);
    widget.linkmenController.addListener(_update);
    group = groupController.current;
    _init();
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

  _update() {
    setState(() {});
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
        groupMemberService.delete({'id': member.id});
      }
    }
  }

  //群成员显示和编辑界面
  Widget _buildGroupMembersWidget(BuildContext context) {
    List<Linkman> linkmen = widget.linkmenController.data;
    List<S2Choice<String>> choiceItems = [];
    for (Linkman linkman in linkmen) {
      S2Choice<String> item =
          S2Choice<String>(value: linkman.peerId, title: linkman.name);
      choiceItems.add(item);
    }

    return SmartSelect<String>.multiple(
      title: 'Linkmen',
      placeholder: 'Select one or more linkman',
      selectedValue: groupMembers,
      onChange: (selected) => setState(() {
        groupMembers = selected.value;
        _buildGroupOwnerChoices();
      }),
      choiceItems: choiceItems,
      modalType: S2ModalType.bottomSheet,
      modalConfig: S2ModalConfig(
        type: S2ModalType.bottomSheet,
        useFilter: false,
        style: S2ModalStyle(
          backgroundColor: Colors.grey.withOpacity(0.5),
        ),
        headerStyle: S2ModalHeaderStyle(
          elevation: 0,
          centerTitle: false,
          backgroundColor: appDataProvider.themeData.colorScheme.primary,
          textStyle: const TextStyle(color: Colors.white),
        ),
      ),
      choiceStyle: S2ChoiceStyle(
        opacity: 0.5,
        elevation: 0,
        //titleStyle: const TextStyle(color: Colors.white),
        color: appDataProvider.themeData.colorScheme.primary,
      ),
      tileBuilder: (context, state) {
        return S2Tile.fromState(
          state,
          isTwoLine: true,
          leading: const Icon(Icons.person_add_alt),
          body: S2TileChips(
            chipLength: state.selected.length,
            chipLabelBuilder: (context, i) {
              return Text(state.selected.title![i]);
            },
            chipOnDelete: (i) {
              setState(() {
                groupMembers.removeAt(i);
                _buildGroupOwnerChoices();
              });
            },
            chipColor: appDataProvider.themeData.colorScheme.primary,
          ),
        );
      },
    );
  }

  //groupMembers变化后重新更新groupOwnerChoices
  _buildGroupOwnerChoices() async {
    groupOwnerChoices.clear();
    if (groupMembers.isNotEmpty) {
      for (String groupMemberId in groupMembers) {
        Linkman? linkman =
            await linkmanService.findCachedOneByPeerId(groupMemberId);
        if (linkman != null) {
          S2Choice<String> item =
              S2Choice<String>(value: linkman.peerId, title: linkman.name);
          groupOwnerChoices.add(item);
        }
      }
    }
  }

  //群主选择界面
  Widget _buildGroupOwnerWidget(BuildContext context) {
    String selectedValue = '';
    if (group != null && group!.groupOwnerPeerId != null) {
      selectedValue = group!.groupOwnerPeerId!;
    }
    return SmartSelect<String>.single(
      title: 'GroupOwnerPeer',
      placeholder: 'Select one linkman',
      selectedValue: selectedValue,
      onChange: (selected) => setState(() {
        if (group != null) {
          group!.groupOwnerPeerId = selected.value;
        }
      }),
      choiceItems: groupOwnerChoices,
      modalType: S2ModalType.bottomSheet,
      modalConfig: S2ModalConfig(
        type: S2ModalType.bottomSheet,
        useFilter: false,
        style: S2ModalStyle(
          backgroundColor: Colors.grey.withOpacity(0.5),
        ),
        headerStyle: S2ModalHeaderStyle(
          elevation: 0,
          centerTitle: false,
          backgroundColor: appDataProvider.themeData.colorScheme.primary,
          textStyle: const TextStyle(color: Colors.white),
        ),
      ),
      choiceStyle: S2ChoiceStyle(
        opacity: 0.5,
        elevation: 0,
        //titleStyle: const TextStyle(color: Colors.white),
        color: appDataProvider.themeData.colorScheme.primary,
      ),
      tileBuilder: (context, state) {
        return S2Tile.fromState(
          state,
          isTwoLine: true,
          leading: const Icon(Icons.person_add_alt),
          body: S2TileChips(
            chipLength: state.selected.length,
            chipLabelBuilder: (context, i) {
              return Text(state.selected.title![i]);
            },
            chipOnDelete: (i) {
              setState(() {
                group!.groupOwnerPeerId = null;
              });
            },
            chipColor: appDataProvider.themeData.colorScheme.primary,
          ),
        );
      },
    );
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
    super.dispose();
  }
}
