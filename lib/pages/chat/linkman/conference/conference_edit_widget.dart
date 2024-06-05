import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/linkman_webrtc_connection_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:colla_chat/widgets/qrcode_widget.dart';
import 'package:flutter/material.dart';

ValueNotifier<Conference?> conferenceNotifier =
    ValueNotifier<Conference?>(null);

///创建和修改群，填写群的基本信息，选择群成员和群主
class ConferenceEditWidget extends StatefulWidget with TileDataMixin {
  const ConferenceEditWidget({super.key});

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
  final List<PlatformDataField> conferenceDataField = [
    PlatformDataField(
        name: 'id',
        label: 'Id',
        inputType: InputType.label,
        prefixIcon: Icon(Icons.numbers_outlined, color: myself.primary)),
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
    PlatformDataField(
      name: 'sfu',
      label: 'Sfu',
      inputType: InputType.switcher,
      dataType: DataType.bool,
      prefixIcon: Icon(Icons.switch_access_shortcut, color: myself.primary),
    ),
    PlatformDataField(
      name: 'sfuUri',
      label: 'SfuUri',
      inputType: InputType.text,
      dataType: DataType.string,
      prefixIcon: Icon(Icons.edit_location_outlined, color: myself.primary),
      readOnly: true,
    ),
    PlatformDataField(
      name: 'sfuToken',
      label: 'SfuToken',
      inputType: InputType.textarea,
      dataType: DataType.string,
      prefixIcon: Icon(Icons.token, color: myself.primary),
      readOnly: true,
    ),
  ];
  late final FormInputController controller =
      FormInputController(conferenceDataField);

  OptionController conferenceOwnerController = OptionController();

  //选择的会议成员
  ValueNotifier<List<String>> conferenceMembers = ValueNotifier([]);

  @override
  initState() {
    _initConference();
    conferenceController.addListener(_update);
    _buildConferenceData();
    super.initState();
  }

  Conference _initConference() {
    Conference? current = conferenceNotifier.value;
    if (current == null) {
      current = Conference('', name: '');
      conferenceNotifier.value = current;
    }
    return current;
  }

  _update() {
    if (mounted) {
      _buildConferenceData();
    }
  }

  //当当前会议改变后，更新数据，局部刷新
  _buildConferenceData() async {
    Conference? current = conferenceNotifier.value;
    if (current == null) {
      return;
    }
    if (current.id != null) {
      List<String> conferenceMembers = [];
      List<GroupMember> members =
          await groupMemberService.findByGroupId(current.conferenceId);
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
    Conference? current = conferenceNotifier.value;
    if (current == null) {
      return;
    }
    current.conferenceOwnerPeerId ??= myself.peerId;
    List<Option<String>> conferenceOwnerOptions = [];
    if (selected.isNotEmpty) {
      for (String conferenceMemberId in selected) {
        Linkman? linkman =
            await linkmanService.findCachedOneByPeerId(conferenceMemberId);
        bool checked = false;
        if (linkman != null) {
          if (current.conferenceOwnerPeerId != null) {
            String? peerId = current.conferenceOwnerPeerId!;
            if (linkman.peerId == peerId) {
              checked = true;
            }
          }
          Option<String> option = Option<String>(linkman.name, linkman.peerId,
              checked: checked,
              leading: linkman.avatarImage,
              hint: linkman.email);
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
            this.conferenceMembers.value.insert(0, myself.peerId!);
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
    Conference? current = conferenceNotifier.value;
    if (current == null) {
      return Container();
    }
    var selector = Container(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: CustomSingleSelectField(
            title: 'ConferenceOwnerPeer',
            onChanged: (selected) {
              current.conferenceOwnerPeerId = selected;
            },
            optionController: conferenceOwnerController));
    // });
    return selector;
  }

  _resend(BuildContext context) async {
    Conference? current = conferenceNotifier.value;
    if (current == null) {
      return null;
    }
    if (current.conferenceOwnerPeerId != myself.peerId) {
      return null;
    }
    bool sfu = current.sfu;
    if (sfu) {
      List<String>? participants = current.participants;
      if (participants != null) {
        try {
          await chatMessageService
              .sendSfuConferenceMessage(current, participants, store: false);
        } catch (e) {
          logger.e('sendSfuConferenceMessage failure:$e');
          DialogUtil.error(context,
              content: 'send sfu conference message failure');
          return null;
        }
      }
    } else {
      ChatMessage chatMessage = await chatMessageService.buildGroupChatMessage(
        current.conferenceId,
        PartyType.conference,
        groupName: current.name,
        title: current.video
            ? ChatMessageContentType.video.name
            : ChatMessageContentType.audio.name,
        content: current,
        messageId: current.conferenceId,
        subMessageType: ChatMessageSubType.videoChat,
      );
      await chatMessageService.send(chatMessage,
          cryptoOption: CryptoOption.group, peerIds: current.participants);
    }
  }

  _qrcode() async {
    Conference? current = conferenceNotifier.value;
    if (current == null) {
      return null;
    }
    List<String>? tokens = current.sfuToken;
    List<String>? token;
    if (tokens != null && tokens.isNotEmpty) {
      token = [tokens.last];
    }
    String content = JsonUtil.toJsonString({
      'sfuUri': current.sfuUri,
      'sfuToken': token,
      'sfu': current.sfu,
      'name': current.name,
      'topic': current.topic,
      'conferenceId': current.conferenceId,
      'video': current.video,
      'adaptiveStream': current.adaptiveStream,
      'dynacast': current.dynacast,
      'simulcast': current.simulcast,
      'fastConnect': current.fastConnect,
      'e2ee': current.e2ee,
      'password': current.password,
      'conferenceOwnerPeerId': current.conferenceOwnerPeerId,
      'conferenceOwnerName': current.conferenceOwnerName,
      'startDate': current.startDate,
      'endDate': current.endDate,
      'participants': current.participants,
    });
    await DialogUtil.show(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          elevation: 0.0,
          insetPadding: EdgeInsets.zero,
          child: SizedBox(
              width: 320,
              height: 320,
              child: QrcodeWidget(
                content: content,
                width: 320,
              )),
        );
      },
    );
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
    ButtonStyle mainStyle = StyleUtil.buildButtonStyle(
        backgroundColor: myself.primary, elevation: 10.0);
    var formInputWidget = ValueListenableBuilder(
        valueListenable: conferenceNotifier,
        builder: (BuildContext context, Conference? conference, Widget? child) {
          if (conference != null) {
            controller.setValues(JsonUtil.toJson(conference));
          }
          List<FormButton> formButtons = [
            FormButton(
                label: 'Ok',
                onTap: (Map<String, dynamic> values) async {
                  Conference? conference = await _onOk(values);
                  if (conference != null) {
                    DialogUtil.info(context,
                        content: AppLocalizations.t('Built conference ') +
                            conference.name);
                  }
                })
          ];
          if (conference!.conferenceOwnerPeerId == myself.peerId) {
            formButtons.add(FormButton(
                label: 'Qrcode',
                onTap: (Map<String, dynamic> values) async {
                  await _qrcode();
                }));
            formButtons.add(FormButton(
              onTap: (Map<String, dynamic> values) {
                _resend(context);
              },
              label: AppLocalizations.t('Resend'),
            ));
          }
          return FormInputWidget(
            spacing: 5.0,
            height: appDataProvider.portraitSize.height * 0.6,
            controller: controller,
            formButtons: formButtons,
          );
        });
    children.add(formInputWidget);

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: ListView(children: children));
  }

  /// 修改提交
  Future<Conference?> _onOk(Map<String, dynamic> values) async {
    Conference? current = _initConference();
    bool conferenceModified = false;

    Conference currentConference = Conference.fromJson(values);
    if (StringUtil.isEmpty(current.conferenceOwnerPeerId)) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must has conference owner'));
      return null;
    }
    if (StringUtil.isEmpty(values['name'])) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must has conference name'));
      return null;
    }
    if (StringUtil.isEmpty(currentConference.topic)) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must has conference topic'));
      return null;
    }
    if (current.id == null) {
      var participants = conferenceMembers.value;
      if (!participants.contains(myself.peerId!)) {
        participants.add(myself.peerId!);
        conferenceMembers.value = [...participants];
      }
      current = await conferenceService.createConference(
          currentConference.name, currentConference.video,
          topic: currentConference.topic,
          conferenceOwnerPeerId: current.conferenceOwnerPeerId,
          startDate: currentConference.startDate,
          endDate: currentConference.endDate,
          participants: conferenceMembers.value);
      current.password = currentConference.password;
      current.simulcast = currentConference.simulcast;
      current.dynacast = currentConference.dynacast;
      current.e2ee = currentConference.e2ee;
      current.fastConnect = currentConference.fastConnect;
      current.adaptiveStream = currentConference.adaptiveStream;
      current.maxParticipants = currentConference.maxParticipants;
      current.sfu = currentConference.sfu;
      current.sfuToken = currentConference.sfuToken;
      current.sfuUri = currentConference.sfuUri;
      conferenceModified = true;
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

    ///1.发送视频通邀请话消息,此时消息必须有content,包含conference信息
    ///当前chatSummary可以不存在，因此不需要当前处于聊天场景下，因此是一个静态方法，创建永久conference的时候使用
    ///对linkman模式下，conference是临时的，不保存数据库
    ///对group和conference模式下，conference是永久的，保存数据库，可以以后重新加入
    if (current.id == null) {
      bool sfu = current.sfu;
      if (sfu) {
        List<String>? participants = current.participants;
        if (participants != null) {
          LiveKitManageRoom? liveKitManageRoom =
              await conferenceService.createRoom(current, participants);
          if (liveKitManageRoom != null) {
            try {
              await chatMessageService.sendSfuConferenceMessage(
                  current, participants);
            } catch (e) {
              logger.e('buildSfuConference failure:$e');
              if (mounted) {
                DialogUtil.error(context,
                    content: 'build sfu conference failure');
              }
              return null;
            }
          } else {
            logger.e('buildSfuConference failure:');
            if (mounted) {
              DialogUtil.error(context,
                  content: 'build sfu conference failure');
            }
            return null;
          }
        }
      } else {
        ChatMessage chatMessage =
            await chatMessageService.buildGroupChatMessage(
          current.conferenceId,
          PartyType.conference,
          groupName: current.name,
          title: current.video
              ? ChatMessageContentType.video.name
              : ChatMessageContentType.audio.name,
          content: current,
          messageId: current.conferenceId,
          subMessageType: ChatMessageSubType.videoChat,
        );
        await chatMessageService.sendAndStore(chatMessage,
            cryptoOption: CryptoOption.group,
            peerIds: current.participants,
            updateSummary: false);
      }
    }

    await conferenceService.store(current);
    conferenceNotifier.value = current;

    if (mounted) {
      DialogUtil.info(context,
          content: AppLocalizations.t('Conference has stored completely'));
    }
    if (conferenceController.current == null) {
      conferenceController.add(current);
    }
    if (conferenceModified) {
      conferenceChatSummaryController.refresh();
    }
    if (currentConference.id == null) {
      setState(() {});
    }

    return current;
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Add conference';
    if (conferenceNotifier.value?.id != null) {
      title = 'Edit conference';
    }
    List<Widget> rightWidgets = [
      IconButton(
          onPressed: () async {
            Conference? current = conferenceNotifier.value;
            if (current != null) {
              List<GroupMember> members =
                  await groupMemberService.findByGroupId(current.conferenceId);
              List<Linkman> linkmen = [];
              for (var member in members) {
                String? memberPeerId = member.memberPeerId;
                if (memberPeerId != null) {
                  Linkman? linkman =
                      await linkmanService.findCachedOneByPeerId(memberPeerId);
                  if (linkman != null) {
                    linkmen.add(linkman);
                  }
                }
              }
              groupLinkmanController.replaceAll(linkmen);
            }
            indexWidgetProvider.push('linkman_webrtc_connection');
          },
          icon: const Icon(Icons.more_horiz_outlined))
    ];
    var appBarView = AppBarView(
        title: title,
        withLeading: widget.withLeading,
        rightWidgets: rightWidgets,
        child: _buildFormInputWidget(context));
    return appBarView;
  }

  @override
  void dispose() {
    conferenceNotifier.removeListener(_update);
    super.dispose();
  }
}
