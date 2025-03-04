import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/pages/chat/linkman/conference/conference_edit_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/qrcode_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

///根据token创建匿名的SFU会议
class AnonymousConferenceEditWidget extends StatelessWidget with TileDataMixin {
  AnonymousConferenceEditWidget({super.key});

  @override
  IconData get iconData => Icons.panorama_wide_angle_outlined;

  @override
  String get routeName => 'anonymous_conference_edit';

  @override
  String get title => 'Anonymous conference edit';

  @override
  bool get withLeading => true;

  @override
  String? get information => null;

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
      name: 'conferenceOwnerPeerId',
      label: 'ConferenceOwnerPeerId',
      inputType: InputType.label,
      prefixIcon: Icon(Icons.perm_identity, color: myself.primary),
    ),
    PlatformDataField(
      name: 'conferenceOwnerName',
      label: 'ConferenceOwnerName',
      inputType: InputType.label,
      prefixIcon: Icon(Icons.open_with, color: myself.primary),
    ),
    PlatformDataField(
      name: 'sfuUri',
      label: 'SfuUri',
      inputType: InputType.label,
      prefixIcon: Icon(Icons.edit_location_outlined, color: myself.primary),
    ),
    PlatformDataField(
      name: 'sfuToken',
      label: 'SfuToken',
      inputType: InputType.label,
      prefixIcon: Icon(Icons.token, color: myself.primary),
    ),
    PlatformDataField(
      name: 'name',
      label: 'Name',
      inputType: InputType.label,
      prefixIcon: Icon(Icons.person, color: myself.primary),
    ),
    PlatformDataField(
      name: 'topic',
      label: 'Topic',
      inputType: InputType.label,
      prefixIcon: Icon(Icons.topic, color: myself.primary),
    ),
    PlatformDataField(
      name: 'startDate',
      label: 'StartDate',
      inputType: InputType.label,
      prefixIcon: Icon(Icons.start, color: myself.primary),
    ),
    PlatformDataField(
      name: 'endDate',
      label: 'EndDate',
      inputType: InputType.label,
      prefixIcon: Icon(Icons.pin_end, color: myself.primary),
    ),
  ];
  late final FormInputController formInputController =
      FormInputController(conferenceDataField);

  //会议信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    var formInputWidget = ValueListenableBuilder(
        valueListenable: conferenceNotifier,
        builder: (BuildContext context, Conference? conference, Widget? child) {
          if (conference != null) {
            formInputController.setValues(JsonUtil.toJson(conference));
          }
          return FormInputWidget(
            spacing: 5.0,
            height: appDataProvider.portraitSize.height * 0.7,
            controller: formInputController,
            formButtons: [
              FormButton(
                  label: 'Qrcode',
                  onTap: (Map<String, dynamic> values) {
                    scanQrcode(context);
                  })
            ],
          );
        });

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: formInputWidget);
  }

  Future<void> scanQrcode(BuildContext context) async {
    String? content = await QrcodeUtil.mobileScan(context);
    if (content == null) {
      return;
    }
    var map = JsonUtil.toJson(content);
    Conference conference = Conference.fromJson(map);
    bool? confirm = await DialogUtil.confirm(
        content: 'You confirm add anonymous conference ${conference.name}?');
    if (confirm != null && confirm) {
      conference.status = EntityStatus.effective.name;
      conference.sfu = true;
      await conferenceService.store(conference);
      conferenceNotifier.value = conference;
      ChatMessage chatMessage = await chatMessageService.buildChatMessage(
        receiverPeerId: myself.peerId,
        groupId: conference.conferenceId,
        groupName: conference.name,
        groupType: PartyType.conference,
        title: conference.video
            ? ChatMessageContentType.video.name
            : ChatMessageContentType.audio.name,
        content: conference,
        messageId: conference.conferenceId,
        subMessageType: ChatMessageSubType.videoChat,
      );
      await chatMessageService.sendAndStore(chatMessage, updateSummary: false);
      if (conferenceController.current == null) {
        conferenceController.add(conference);
      }
      DialogUtil.info(
          content:
              'You add anonymous conference ${conference.name} successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Add anonymous conference';
    if (conferenceNotifier.value?.id != null) {
      title = 'Edit anonymous conference';
    }

    var appBarView = AppBarView(
        title: title,
        withLeading: withLeading,
        child: _buildFormInputWidget(context));
    return appBarView;
  }
}
