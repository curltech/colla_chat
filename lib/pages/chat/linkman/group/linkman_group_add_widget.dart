import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/group/linkman_group_edit_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';

///选择linkman建群
class LinkmanGroupAddWidget extends StatefulWidget with TileDataMixin {
  final DataListController<Linkman> linkmenController =
      DataListController<Linkman>();

  LinkmanGroupAddWidget({Key? key}) : super(key: key);

  @override
  Icon get icon => const Icon(Icons.person_add);

  @override
  String get routeName => 'linkman_group_add';

  @override
  String get title => 'LinkmanGroupAdd';

  @override
  bool get withLeading => true;

  @override
  State<StatefulWidget> createState() => _LinkmanGroupAddWidgetState();
}

class _LinkmanGroupAddWidgetState extends State<LinkmanGroupAddWidget> {
  TextEditingController controller = TextEditingController();
  List<String> groupMembers = [];
  List<S2Choice<String>> groupOwnerChoices = [];
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
    if (group != null) {
      group!.alias = currentGroup.alias;
      group!.mobile = currentGroup.mobile;
      group!.email = currentGroup.email;
      if (group!.groupOwnerPeerId != currentGroup.groupOwnerPeerId) {
        group!.groupOwnerPeerId = currentGroup.groupOwnerPeerId;
      }
      await groupService.modifyGroup(group!);
    } else {
      // 加群
      group = await groupService.createGroup(currentGroup);
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

  _buildSearchTextField(BuildContext context) {
    var searchTextField = TextFormField(
        controller: controller,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          labelText: AppLocalizations.t('PeerId/Mobile/Email/Name'),
          suffixIcon: IconButton(
            onPressed: () {
              _search(controller.text);
            },
            icon: const Icon(Icons.search),
          ),
        ));

    return searchTextField;
  }

  Future<void> _responsePeerClients(List<Linkman> linkmen) async {
    List<TileData> tiles = [];
    if (linkmen.isNotEmpty) {
      for (var linkman in linkmen) {
        var title = linkman.name;
        var subtitle = linkman.peerId;
        TileData tile = TileData(
            title: title,
            subtitle: subtitle,
            suffix: IconButton(
              iconSize: 24.0,
              icon: const Icon(Icons.add),
              onPressed: () async {},
            ));
        tiles.add(tile);
      }
    }
  }

  Future<void> _search(String key) async {
    String email = '';
    if (key.contains('@')) {
      email = key;
    }
    String mobile = '';
    bool isPhoneNumber = StringUtil.isNumeric(key);
    if (isPhoneNumber) {
      mobile = key;
    }
    List<Linkman> linkmen = await linkmanService.findAll();
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
