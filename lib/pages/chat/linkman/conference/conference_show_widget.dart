import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/conference_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/conference/conference_edit_widget.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_conference_client.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

///显示会议的基本信息，会议成员和会议发起人
class ConferenceShowWidget extends StatelessWidget with TileDataMixin {
  final List<PlatformDataField> readOnlyConferenceDataField = [
    PlatformDataField(
        name: 'id',
        label: 'Id',
        inputType: InputType.label,
        prefixIcon: Icon(Icons.numbers_outlined, color: myself.primary)),
    PlatformDataField(
        name: 'conferenceId',
        label: 'ConferenceId',
        inputType: InputType.label,
        prefixIcon: Icon(Icons.meeting_room, color: myself.primary)),
    PlatformDataField(
        name: 'name',
        label: 'Name',
        inputType: InputType.label,
        prefixIcon: Icon(Icons.person, color: myself.primary)),
    PlatformDataField(
        name: 'topic',
        label: 'Topic',
        inputType: InputType.label,
        prefixIcon: Icon(Icons.topic, color: myself.primary)),
    PlatformDataField(
        name: 'conferenceOwnerPeerId',
        label: 'ConferenceOwnerPeerId',
        inputType: InputType.label,
        prefixIcon: Icon(Icons.perm_identity, color: myself.primary)),
    PlatformDataField(
        name: 'video',
        label: 'Video',
        inputType: InputType.label,
        prefixIcon: Icon(Icons.video_call, color: myself.primary)),
    PlatformDataField(
        name: 'startDate',
        label: 'StartDate',
        inputType: InputType.label,
        prefixIcon: Icon(Icons.start, color: myself.primary)),
    PlatformDataField(
        name: 'endDate',
        label: 'EndDate',
        inputType: InputType.label,
        prefixIcon: Icon(Icons.pin_end, color: myself.primary)),
    PlatformDataField(
      name: 'sfu',
      label: 'Sfu',
      inputType: InputType.label,
      prefixIcon: Icon(Icons.switch_access_shortcut, color: myself.primary),
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
  ];
  late final FormInputController controller =
      FormInputController(readOnlyConferenceDataField);
  final bool hasTitle;

  ConferenceShowWidget({super.key, this.hasTitle = true});

  @override
  IconData get iconData => Icons.meeting_room_outlined;

  @override
  String get routeName => 'conference_show';

  @override
  String get title => 'Conference show';

  @override
  bool get withLeading => true;

  //当会议改变后，更新数据，局部刷新
  Future<List<Option<String>>> _buildConferenceOptions() async {
    List<Option<String>> options = <Option<String>>[];
    final Conference? conference = conferenceNotifier.value;
    if (conference != null) {
      List<String> participants = conference.participants ?? [];
      for (String participant in participants) {
        var linkman = await linkmanService.findCachedOneByPeerId(participant);
        if (linkman != null) {
          options.add(Option(linkman.name, linkman.peerId,
              leading: linkman.avatarImage, hint: linkman.email!));
        }
      }
    }
    return options;
  }

  //字段的数据使用控制器数据，直接修改，optionsChanged用于表示控制器数据改变了
  Widget _buildChips(BuildContext context) {
    return PlatformFutureBuilder(
        future: _buildConferenceOptions(),
        builder: (BuildContext context, List<Option<String>> options) {
          List<Chip> chips = [];
          for (var option in options) {
            var chip = Chip(
              label: Text(
                option.label,
                style: const TextStyle(color: Colors.black),
              ),
              avatar: option.leading,
              backgroundColor: Colors.white,
              deleteIconColor: myself.primary,
            );
            chips.add(chip);
          }
          if (chips.isNotEmpty) {
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: chips,
            );
          } else {
            return nil;
          }
        });
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
          DialogUtil.error(content: 'send sfu conference message failure');
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

  //会议信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    ButtonStyle mainStyle = StyleUtil.buildButtonStyle(
        backgroundColor: myself.primary, elevation: 10.0);
    final Conference? conference = conferenceNotifier.value;
    if (conference != null) {
      controller.setValues(JsonUtil.toJson(conference));
      List<FormButton> formButtons = [];
      if (conference.conferenceOwnerPeerId == myself.peerId) {
        formButtons.add(FormButton(
          buttonStyle: mainStyle,
          onTap: (Map<String, dynamic> values) {
            _resend(context);
          },
          label: AppLocalizations.t('Resend'),
        ));
      }
      var formInputWidget = SingleChildScrollView(
          child: Container(
              padding: const EdgeInsets.all(10.0),
              child: FormInputWidget(
                height: 400,
                showResetButton: false,
                formButtons: formButtons,
                controller: controller,
              )));

      return formInputWidget;
    }

    return Center(
        child: CommonAutoSizeText(AppLocalizations.t('No conference')));
  }

  Future<List<TileData>> _buildChatReceipts() async {
    List<TileData> tiles = [];
    final Conference? conference = conferenceNotifier.value;
    if (conference != null) {
      ConferenceChatMessageController? conferenceChatMessageController =
          p2pConferenceClientPool
              .getConferenceChatMessageController(conference.conferenceId);
      if (conferenceChatMessageController == null) {
        return tiles;
      }
      Map<String, Map<String, ChatMessage>> chatReceiptMap =
          conferenceChatMessageController.chatReceipts();
      for (var key in chatReceiptMap.keys) {
        var chatReceipts = chatReceiptMap[key];
        for (var chatReceipt in chatReceipts!.values) {
          Linkman? linkman = await linkmanService
              .findCachedOneByPeerId(chatReceipt.senderPeerId!);
          var tile = TileData(
              title: chatReceipt.senderName!,
              titleTail: key,
              prefix: linkman?.avatarImage);

          tiles.add(tile);
        }
      }
    }
    return tiles;
  }

  Widget _buildConferenceShow(BuildContext context) {
    return Column(
      children: [
        _buildChips(context),
        const SizedBox(
          height: 5,
        ),
        ExpansionTile(
            title: Text(AppLocalizations.t('Conference')),
            initiallyExpanded: true,
            children: [_buildFormInputWidget(context)]),
        Expanded(
            child: FutureBuilder<List<TileData>>(
          future: _buildChatReceipts(),
          builder:
              (BuildContext context, AsyncSnapshot<List<TileData>> snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return DataListView(
                itemCount: snapshot.data!.length,
                itemBuilder: (BuildContext context, int index) {
                  return snapshot.data![index];
                },
              );
            }
            return nilBox;
          },
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child = ValueListenableBuilder(
        valueListenable: conferenceNotifier,
        builder: (BuildContext context, Conference? conference, Widget? child) {
          return _buildConferenceShow(context);
        });
    if (!hasTitle) {
      return child;
    }
    var appBarView =
        AppBarView(title: title, withLeading: withLeading, child: child);

    return appBarView;
  }
}
