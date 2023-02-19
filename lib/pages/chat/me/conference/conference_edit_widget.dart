import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/chat/me/conference/conference_list_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/conference.dart';
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

final List<ColumnFieldDef> conferenceColumnFieldDefs = [
  ColumnFieldDef(
      name: 'conferenceId',
      label: 'ConferenceId',
      inputType: InputType.label,
      prefixIcon: const Icon(Icons.meeting_room)),
  ColumnFieldDef(
      name: 'name', label: 'Name', prefixIcon: const Icon(Icons.person)),
  ColumnFieldDef(
      name: 'title',
      label: 'Title',
      prefixIcon: const Icon(Icons.perm_identity)),
  ColumnFieldDef(
      name: 'conferenceOwnerPeerId',
      label: 'ConferenceOwnerPeerId',
      inputType: InputType.label,
      prefixIcon: const Icon(Icons.perm_identity)),
  ColumnFieldDef(
      name: 'password',
      label: 'Password',
      inputType: InputType.password,
      prefixIcon: const Icon(Icons.password)),
];

///创建和修改群，填写群的基本信息，选择群成员和群主
class ConferenceEditWidget extends StatefulWidget with TileDataMixin {
  ConferenceEditWidget({Key? key}) : super(key: key);

  @override
  IconData get iconData => Icons.meeting_room_outlined;

  @override
  String get routeName => 'conference_edit';

  @override
  String get title => 'Conference edit';

  @override
  bool get withLeading => true;

  @override
  State<StatefulWidget> createState() => _ConferenceEditWidgetState();
}

class _ConferenceEditWidgetState extends State<ConferenceEditWidget> {
  TextEditingController controller = TextEditingController();

  OptionController conferenceOwnerController = OptionController();

  //选择的会议成员
  ValueNotifier<List<String>> conferenceMembers = ValueNotifier([]);

  //群主的选项
  // ValueNotifier<List<Option<String>>> groupOwnerOptions = ValueNotifier([]);

  //当前会议
  ValueNotifier<Conference> conference = ValueNotifier(Conference(''));

  @override
  initState() {
    conferenceController.addListener(_update);
    super.initState();
    _buildConferenceData();
  }

  _update() {
    setState(() {});
  }

  _buildConferenceData() async {
    var current = conferenceController.current;
    if (current != null) {
      conference.value = current;
    } else {
      conference.value = Conference('');
    }
    if (conference.value.id != null) {
      List<String> conferenceMembers = [];
      List<GroupMember> members =
          await groupMemberService.findByGroupId(conference.value.conferenceId);
      if (members.isNotEmpty) {
        for (GroupMember member in members) {
          conferenceMembers.add(member.memberPeerId!);
        }
      }
      this.conferenceMembers.value = conferenceMembers;
      await _buildConferenceOwnerOptions(conferenceMembers);
    }
  }

  //更新groupOwnerOptions
  _buildConferenceOwnerOptions(List<String> selected) async {
    conference.value.conferenceOwnerPeerId ??= myself.peerId;
    List<Option<String>> conferenceOwnerOptions = [];
    if (selected.isNotEmpty) {
      for (String conferenceMemberId in selected) {
        Linkman? linkman =
            await linkmanService.findCachedOneByPeerId(conferenceMemberId);
        bool checked = false;
        if (linkman != null) {
          if (conference.value.conferenceOwnerPeerId != null) {
            String? peerId = conference.value.conferenceOwnerPeerId!;
            if (linkman.peerId == peerId) {
              checked = true;
            }
          }
          Option<String> option = Option<String>(linkman.name, linkman.peerId,
              checked: checked, leading: linkman.avatarImage);
          conferenceOwnerOptions.add(option);
        } else {
          logger.e('Conference member $conferenceMemberId is not linkman');
          if (mounted) {
            DialogUtil.error(context,
                content:
                    'Conference member $conferenceMemberId is not linkman');
          }
        }
      }
    }
    conferenceOwnerController.options = conferenceOwnerOptions;
  }

  //群成员显示和编辑界面
  Widget _buildConferenceMembersWidget(BuildContext context) {
    var selector = ValueListenableBuilder(
        valueListenable: conferenceMembers,
        builder: (BuildContext context, List<String> conferenceMembers,
            Widget? child) {
          return LinkmanGroupSearchWidget(
            selectType: SelectType.dataListMultiSelectField,
            onSelected: (List<String>? selected) async {
              if (selected != null) {
                this.conferenceMembers.value = selected;
                await _buildConferenceOwnerOptions(selected);
              }
            },
            selected: this.conferenceMembers.value,
            includeGroup: false,
          );
        });

    return selector;
  }

  //群主选择界面
  Widget _buildConferenceOwnerWidget(BuildContext context) {
    var selector = CustomSingleSelectField(
        title: 'ConferenceOwnerPeer',
        onChanged: (selected) {
          conference.value?.conferenceOwnerPeerId = selected;
        },
        optionController: conferenceOwnerController);
    return selector;
  }

  //群信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    var formInputWidget = SingleChildScrollView(
        child: Container(
            padding: const EdgeInsets.all(15.0),
            child: ValueListenableBuilder(
                valueListenable: conference,
                builder: (BuildContext context, Conference? conference,
                    Widget? child) {
                  Map<String, dynamic>? initValues = {};
                  if (conference != null) {
                    initValues = conferenceController.getInitValue(
                        conferenceColumnFieldDefs,
                        entity: conference);
                  }
                  return FormInputWidget(
                    onOk: (Map<String, dynamic> values) {
                      _onOk(values).then((groupId) {
                        DialogUtil.info(context,
                            content:
                                'Conference $groupId operation is completed');
                      });
                    },
                    columnFieldDefs: conferenceColumnFieldDefs,
                    initValues: initValues,
                  );
                })));

    return formInputWidget;
  }

  //修改提交
  Future<String?> _onOk(Map<String, dynamic> values) async {
    bool conferenceModified = false;
    Conference currentConference = Conference.fromJson(values);
    if (StringUtil.isEmpty(currentConference.name)) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must has conference name'));
      return null;
    }
    if (StringUtil.isEmpty(conference.value.conferenceOwnerPeerId)) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must has conference owner'));
      return null;
    }
    var current = conferenceController.current;
    current ??=
        await conferenceService.createConference(currentConference.name!);
    if (current?.title != currentConference.title) {
      current.title = currentConference.title;
      conferenceModified = true;
    }
    if (current.name != currentConference.name) {
      current.name = currentConference.name;
      conferenceModified = true;
    }
    if (current.conferenceOwnerPeerId !=
        currentConference.conferenceOwnerPeerId) {
      current.conferenceOwnerPeerId = currentConference.conferenceOwnerPeerId;
      conferenceModified = true;
    }
    if (current.password != currentConference.password) {
      current.password = currentConference.password;
      conferenceModified = true;
    }
    bool add = true;
    if (current.id != null) {
      add = false;
    }
    conference.value.conferenceOwnerPeerId ??= myself.peerId;
    current.conferenceOwnerPeerId = conference.value.conferenceOwnerPeerId;
    await conferenceService.store(current);
    conference.value = current;
    String conferenceId = current.conferenceId;
    List<GroupMember> members =
        await groupMemberService.findByGroupId(current.conferenceId);
    Map<String, GroupMember> oldMembers = {};
    //所有的现有成员
    if (members.isNotEmpty) {
      for (GroupMember member in members) {
        oldMembers[member.memberPeerId!] = member;
      }
    }
    //新增加的成员
    List<GroupMember> newMembers = [];
    for (var memberPeerId in conferenceMembers.value) {
      var member = oldMembers[memberPeerId];
      if (member == null) {
        Linkman? linkman =
            await linkmanService.findCachedOneByPeerId(memberPeerId);
        if (linkman != null) {
          GroupMember groupMember = GroupMember();
          groupMember.groupId = conferenceId;
          groupMember.memberPeerId = memberPeerId;
          groupMember.memberType = MemberType.member.name;
          if (StringUtil.isEmpty(linkman.alias)) {
            groupMember.memberAlias = linkman.name;
          } else {
            groupMember.memberAlias = linkman.alias;
          }
          groupMember.status = EntityStatus.effective.name;
          await groupMemberService.store(groupMember);
          newMembers.add(groupMember);
        }
      } else {
        oldMembers.remove(memberPeerId);
      }
    }

    //处理删除的成员
    if (oldMembers.isNotEmpty) {
      for (GroupMember member in oldMembers.values) {
        oldMembers[member.memberPeerId!] = member;
        await groupMemberService.delete(entity: {'id': member.id});
      }
    }

    if (conferenceController.current == null) {
      conferenceController.add(current);
    }

    return conferenceId;
  }

  Widget _buildConferenceEdit(BuildContext context) {
    return Column(
      children: [
        _buildConferenceMembersWidget(context),
        const SizedBox(
          height: 5,
        ),
        _buildConferenceOwnerWidget(context),
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
        child: _buildConferenceEdit(context));
    return appBarView;
  }

  @override
  void dispose() {
    conferenceController.removeListener(_update);
    controller.dispose();
    super.dispose();
  }
}
