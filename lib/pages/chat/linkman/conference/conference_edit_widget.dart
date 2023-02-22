import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
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
  //ValueNotifier<List<Option<String>>> groupOwnerOptions = ValueNotifier([]);

  //当前会议
  ValueNotifier<Conference> conference =
      ValueNotifier(Conference('', name: ''));

  @override
  initState() {
    conferenceController.addListener(_update);
    super.initState();
    _buildConferenceData();
  }

  _update() {
    if (mounted) {
      _buildConferenceData();
    }
  }

  //当当前会议改变后，更新数据，局部刷新
  _buildConferenceData() async {
    var current = conferenceController.current;
    if (current != null) {
      conference.value = current;
    } else {
      conference.value = Conference('', name: '');
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

  //更新ConferenceOwnerOptions，从会议成员中选择
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

  //会议成员显示和编辑界面，从所有的联系人中选择会议成员
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
            selected: conferenceMembers,
            includeGroup: false,
          );
        });

    return selector;
  }

  //会议发起人选择界面
  Widget _buildConferenceOwnerWidget(BuildContext context) {
    var selector =
        // ValueListenableBuilder(
        //     valueListenable: groupOwnerOptions,
        //     builder: (BuildContext context, List<Option> option, Widget? child) {
        //       return
        CustomSingleSelectField(
            title: 'ConferenceOwnerPeer',
            onChanged: (selected) {
              conference.value.conferenceOwnerPeerId = selected;
            },
            optionController: conferenceOwnerController);
    // });
    return selector;
  }

  //会议信息编辑界面
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
                      _onOk(values).then((conferenceId) {
                        DialogUtil.info(context,
                            content:
                                'Conference $conferenceId operation is completed');
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
    bool conferenceAdd = false;
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
    if (StringUtil.isEmpty(conference.value.topic)) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must has conference topic'));
      return null;
    }
    var current = conferenceController.current;
    if (current == null) {
      current = await conferenceService.createConference(currentConference.name,
          topic: currentConference.topic,
          conferenceOwnerPeerId: currentConference.conferenceOwnerPeerId,
          startDate: currentConference.startDate,
          endDate: currentConference.endDate,
          participants: conferenceMembers.value);
      conferenceModified = true;
      conferenceAdd = true;
    } else {
      if (current.topic != currentConference.topic) {
        current.topic = currentConference.topic;
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
    }
    conference.value.conferenceOwnerPeerId ??= myself.peerId;
    current.conferenceOwnerPeerId = conference.value.conferenceOwnerPeerId;
    current.participants = conferenceMembers.value;
    await conferenceService.store(current);
    conference.value = current;
    if (conferenceAdd) {
      List<ChatMessage> chatMessages =
          await chatMessageService.buildGroupChatMessage(
        current.conferenceId,
        PartyType.conference,
        contentType: ContentType.video,
        title: ContentType.video.name,
        content: current,
        messageId: current.conferenceId,
        subMessageType: ChatMessageSubType.videoChat,
        peerIds: current.participants,
      );
      for (var chatMessage in chatMessages) {
        await chatMessageService.sendAndStore(chatMessage);
      }
    }

    if (conferenceController.current == null) {
      conferenceController.add(current);
    }
    if (conferenceModified) {
      conferenceChatSummaryController.refresh();
    }

    return conference.value.conferenceId;
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
    conferenceController.current = null;
    conferenceController.removeListener(_update);
    controller.dispose();
    super.dispose();
  }
}