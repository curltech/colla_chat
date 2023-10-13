import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

final List<PlatformDataField> conferenceColumnFieldDefs = [
  PlatformDataField(
    name: 'conferenceId',
    label: 'ConferenceId',
    inputType: InputType.label,
    prefixIcon: Icon(Icons.meeting_room, color: myself.primary),
  ),
  PlatformDataField(
    name: 'name',
    label: 'Name',
    prefixIcon: Icon(Icons.person, color: myself.primary),
  ),
  PlatformDataField(
    name: 'topic',
    label: 'Topic',
    prefixIcon: Icon(Icons.topic, color: myself.primary),
  ),
  PlatformDataField(
    name: 'conferenceOwnerPeerId',
    label: 'ConferenceOwnerPeerId',
    inputType: InputType.label,
    prefixIcon: Icon(Icons.perm_identity, color: myself.primary),
  ),
  PlatformDataField(
    name: 'password',
    label: 'Password',
    inputType: InputType.password,
    prefixIcon: Icon(Icons.password, color: myself.primary),
  ),
  PlatformDataField(
    name: 'video',
    label: 'Video',
    inputType: InputType.switcher,
    dataType: DataType.bool,
    prefixIcon: Icon(Icons.video_call, color: myself.primary),
  ),
  PlatformDataField(
    name: 'startDate',
    label: 'StartDate',
    inputType: InputType.datetime,
    dataType: DataType.string,
    prefixIcon: Icon(Icons.start, color: myself.primary),
  ),
  PlatformDataField(
    name: 'endDate',
    label: 'EndDate',
    inputType: InputType.datetime,
    dataType: DataType.string,
    prefixIcon: Icon(Icons.pin_end, color: myself.primary),
  ),
];

///创建和修改群，填写群的基本信息，选择群成员和群主
class ConferenceAddWidget extends StatefulWidget with TileDataMixin {
  ConferenceAddWidget({Key? key}) : super(key: key);

  @override
  IconData get iconData => Icons.meeting_room_outlined;

  @override
  String get routeName => 'conference_add';

  @override
  String get title => 'Add conference';

  @override
  bool get withLeading => true;

  @override
  State<StatefulWidget> createState() => _ConferenceAddWidgetState();
}

class _ConferenceAddWidgetState extends State<ConferenceAddWidget> {
  final FormInputController controller =
      FormInputController(conferenceColumnFieldDefs);

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
      await _buildConferenceOwnerOptions(conferenceMembers);
      this.conferenceMembers.value = conferenceMembers;
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
              checked: checked,
              leading: linkman.avatarImage,
              hint: linkman.email!);
          conferenceOwnerOptions.add(option);
        } else {
          logger.e('Conference member $conferenceMemberId is not linkman');
          if (mounted) {
            DialogUtil.error(context,
                content: AppLocalizations.t('Conference member ') +
                    conferenceMemberId +
                    AppLocalizations.t(' is not linkman'));
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
          if (!this.conferenceMembers.value.contains(myself.peerId)) {
            this.conferenceMembers.value.add(myself.peerId!);
          }
          return Container(
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
              child: LinkmanGroupSearchWidget(
                key: UniqueKey(),
                selectType: SelectType.chipMultiSelectField,
                onSelected: (List<String>? selected) async {
                  if (selected != null) {
                    this.conferenceMembers.value = selected;
                    await _buildConferenceOwnerOptions(selected);
                  }
                },
                selected: conferenceMembers,
                includeGroup: false,
              ));
        });

    return selector;
  }

  //会议发起人选择界面
  Widget _buildConferenceOwnerWidget(BuildContext context) {
    var selector = Container(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: CustomSingleSelectField(
            title: 'ConferenceOwnerPeer',
            onChanged: (selected) {
              conference.value.conferenceOwnerPeerId = selected;
            },
            optionController: conferenceOwnerController));
    // });
    return selector;
  }

  //会议信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    var children = [
      _buildConferenceMembersWidget(context),
      const SizedBox(
        height: 5,
      ),
      _buildConferenceOwnerWidget(context),
    ];
    var formInputWidget = ValueListenableBuilder(
        valueListenable: conference,
        builder: (BuildContext context, Conference? conference, Widget? child) {
          if (conference != null) {
            controller.setValues(JsonUtil.toJson(conference));
          }
          return FormInputWidget(
            spacing: 5.0,
            height: appDataProvider.portraitSize.height * 0.6,
            onOk: (Map<String, dynamic> values) {
              _onOk(values).then((conference) {
                if (conference != null) {
                  DialogUtil.info(context,
                      content: AppLocalizations.t('Built conference ') +
                          conference.name);
                }
              });
            },
            controller: controller,
          );
        });
    children.add(formInputWidget);

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: ListView(children: children));
  }

  //修改提交
  Future<Conference?> _onOk(Map<String, dynamic> values) async {
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
    if (StringUtil.isEmpty(currentConference.topic)) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must has conference topic'));
      return null;
    }
    var current = conferenceController.current;
    if (current == null) {
      var participants = conferenceMembers.value;
      if (!participants.contains(myself.peerId!)) {
        participants.add(myself.peerId!);
        conferenceMembers.value = [...participants];
      }
      current = await conferenceService.createConference(
          currentConference.name, currentConference.video,
          topic: currentConference.topic,
          conferenceOwnerPeerId: conference.value.conferenceOwnerPeerId,
          startDate: currentConference.startDate,
          endDate: currentConference.endDate,
          participants: conferenceMembers.value);
      current.password = currentConference.password;
      current.advance = currentConference.advance;
      current.mute = currentConference.mute;
      current.contact = currentConference.contact;
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
        current.conferenceOwnerPeerId =
            currentConference.conferenceOwnerPeerId ?? myself.peerId;
        conferenceModified = true;
      }
      if (current.password != currentConference.password) {
        current.password = currentConference.password;
        conferenceModified = true;
      }
      if (current.video != currentConference.video) {
        current.video = currentConference.video;
        conferenceModified = true;
      }
      if (current.startDate != currentConference.startDate) {
        current.startDate = currentConference.startDate;
        conferenceModified = true;
      }
      if (current.endDate != currentConference.endDate) {
        current.endDate = currentConference.endDate;
        conferenceModified = true;
      }
    }
    for (var option in conferenceOwnerController.options) {
      if (option.value == current.conferenceOwnerPeerId) {
        current.conferenceOwnerName = option.label;
        break;
      }
    }
    current.participants = conferenceMembers.value;
    await conferenceService.store(current);
    if (mounted) {
      DialogUtil.info(context,
          content: AppLocalizations.t('Conference has stored completely'));
    }
    conference.value = current;

    ///1.发送视频通邀请话消息,此时消息必须有content,包含conference信息
    ///当前chatSummary可以不存在，因此不需要当前处于聊天场景下，因此是一个静态方法，创建永久conference的时候使用
    ///对linkman模式下，conference是临时的，不保存数据库
    ///对group和conference模式下，conference是永久的，保存数据库，可以以后重新加入
    if (conferenceAdd) {
      ChatMessage chatMessage = await chatMessageService.buildGroupChatMessage(
        current.conferenceId,
        PartyType.conference,
        title: current.video
            ? ChatMessageContentType.video.name
            : ChatMessageContentType.audio.name,
        content: current,
        messageId: current.conferenceId,
        subMessageType: ChatMessageSubType.videoChat,
      );
      await chatMessageService.sendAndStore(chatMessage,
          cryptoOption: CryptoOption.group, peerIds: current.participants);
    }

    if (conferenceController.current == null) {
      conferenceController.add(current);
    }
    if (conferenceModified) {
      conferenceChatSummaryController.refresh();
    }
    if (conferenceAdd) {
      setState(() {});
    }

    return current;
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Add conference';
    int? id = conference.value.id;
    if (id != null) {
      title = 'Edit conference';
    }
    var appBarView = AppBarView(
        title: title,
        withLeading: widget.withLeading,
        child: _buildFormInputWidget(context));
    return appBarView;
  }

  @override
  void dispose() {
    conferenceController.removeListener(_update);
    super.dispose();
  }
}
