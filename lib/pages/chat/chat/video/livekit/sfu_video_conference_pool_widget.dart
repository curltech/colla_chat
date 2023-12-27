import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/conference_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/video/livekit/sfu_video_conference_participant_widget.dart';
import 'package:colla_chat/pages/chat/linkman/conference/conference_edit_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/transport/webrtc/livekit/sfu_room_client.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as livekit_client;

///Sfu会议池的显示界面
class SfuVideoConferencePoolWidget extends StatelessWidget with TileDataMixin {
  final SfuVideoConferenceParticipantWidget
      sfuVideoConferenceParticipantWidget =
      SfuVideoConferenceParticipantWidget();

  SfuVideoConferencePoolWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(sfuVideoConferenceParticipantWidget);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'sfu_video_conference_pool';

  @override
  IconData get iconData => Icons.meeting_room;

  @override
  String get title => 'Sfu video conference pool';

  List<TileData> _buildConferenceTileData(BuildContext context) {
    List<LiveKitConferenceClient> liveKitConferenceClients =
        liveKitConferenceClientPool.conferenceClients;
    List<TileData> tiles = [];
    if (liveKitConferenceClients.isNotEmpty) {
      for (LiveKitConferenceClient liveKitConferenceClient
          in liveKitConferenceClients) {
        ConferenceChatMessageController conferenceChatMessageController =
            liveKitConferenceClient.conferenceChatMessageController;
        Conference? conference = conferenceChatMessageController.conference;
        if (conference == null) {
          continue;
        }
        var conferenceId = conference.conferenceId;
        var conferenceName = conference.name;
        var conferenceOwnerName = conference.conferenceOwnerName;
        var topic = conference.topic;
        TileData tile = TileData(
            prefix: conference.avatarImage,
            title: conferenceName,
            titleTail: topic,
            subtitle: conferenceId,
            selected: liveKitConferenceClientPool.conferenceId == conferenceId,
            isThreeLine: false,
            onTap: (int index, String title, {String? subtitle}) {},
            routeName: 'sfu_video_conference_participant');
        List<TileData> slideActions = [];
        if (liveKitConferenceClientPool.conferenceId != conferenceId) {
          TileData checkSlideAction = TileData(
              title: 'Check',
              prefix: Icons.playlist_add_check_outlined,
              onTap: (int index, String label, {String? subtitle}) async {
                liveKitConferenceClientPool.conferenceId = conferenceId;
                DialogUtil.info(context,
                    content:
                        '${AppLocalizations.t('Conference:')} ${conference.name}${AppLocalizations.t(' is set current')}');
              });
          slideActions.add(checkSlideAction);
        }
        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.playlist_remove_outlined,
            onTap: (int index, String label, {String? subtitle}) async {
              liveKitConferenceClientPool.disconnect(
                  conferenceId: conferenceId);
              DialogUtil.info(context,
                  content:
                      '${AppLocalizations.t('Conference:')} ${conference.name}${AppLocalizations.t(' is closed')}');
            });
        slideActions.add(deleteSlideAction);
        TileData conferenceSlideAction = TileData(
            title: 'Conference',
            prefix: Icons.meeting_room,
            onTap: (int index, String label, {String? subtitle}) async {
              conferenceNotifier.value = conference;
              indexWidgetProvider.push('conference_show');
            });
        slideActions.add(conferenceSlideAction);
        tile.slideActions = slideActions;

        List<TileData> endSlideActions = [];
        TileData renegotiateSlideAction = TileData(
            title: 'Renegotiate',
            prefix: Icons.repeat_one_outlined,
            onTap: (int index, String label, {String? subtitle}) async {
              // liveKitConferenceClientPool.conferenceClient?.renegotiate();
              DialogUtil.info(context,
                  content:
                      '${AppLocalizations.t('Conference:')} ${conference.name}${AppLocalizations.t(' is renegotiate')}');
            });
        endSlideActions.add(renegotiateSlideAction);
        TileData toggleIceSlideAction = TileData(
            title: 'Toggle',
            prefix: Icons.recycling_outlined,
            onTap: (int index, String label, {String? subtitle}) async {
              // liveKitConferenceClientPool.conferenceClient
              //     ?.renegotiate(toggle: true);
              DialogUtil.info(context,
                  content:
                      '${AppLocalizations.t('Conference:')} ${conference.name}${AppLocalizations.t(' is toggle renegotiate')}');
            });
        endSlideActions.add(toggleIceSlideAction);
        tile.endSlideActions = endSlideActions;

        tiles.add(tile);
      }
    }
    return tiles;
  }

  Widget _buildVideoConferenceListView(BuildContext context) {
    List<Widget> children = [];
    var conferenceView = SizedBox(
        height: 200,
        child: DataListView(
          tileData: _buildConferenceTileData(context),
        ));
    children.add(conferenceView);
    children.add(Expanded(child: _buildRoomWidget(context)));

    return Column(
      children: children,
    );
  }

  Widget _buildRoomWidget(BuildContext context) {
    LiveKitConferenceClient? liveKitConferenceClient =
        liveKitConferenceClientPool.conferenceClient;
    if (liveKitConferenceClient == null) {
      return Container();
    }
    List<Widget> children = [];
    LiveKitRoomClient roomClient = liveKitConferenceClient.roomClient;
    children.add(CommonAutoSizeText('uri:${roomClient.uri}'));
    children
        .add(CommonAutoSizeText('adaptiveStream:${roomClient.adaptiveStream}'));
    children.add(CommonAutoSizeText('dynacast:${roomClient.dynacast}'));
    children.add(CommonAutoSizeText('e2ee:${roomClient.e2ee}'));
    children.add(CommonAutoSizeText('fastConnect:${roomClient.fastConnect}'));
    children.add(CommonAutoSizeText('sharedKey:${roomClient.sharedKey}'));
    children.add(CommonAutoSizeText('simulcast:${roomClient.simulcast}'));
    children.add(CommonAutoSizeText('token:${roomClient.token}'));
    children.add(CommonAutoSizeText('dynacast:${roomClient.dynacast}'));
    livekit_client.Room room = roomClient.room;
    if (room.connectionState == livekit_client.ConnectionState.connected) {
      children.add(CommonAutoSizeText('name:${room.name}'));
      children
          .add(CommonAutoSizeText('canPlaybackAudio:${room.canPlaybackAudio}'));
      children
          .add(CommonAutoSizeText('connectionState:${room.connectionState}'));
      // children.add(CommonAutoSizeText('connectOptions:${room.connectOptions.toString()}'));
      // children.add(CommonAutoSizeText('roomOptions:${room.roomOptions}'));
      children.add(CommonAutoSizeText('speakerOn:${room.speakerOn}'));
      children.add(CommonAutoSizeText(
          'selectedAudioInputDeviceId:${room.selectedAudioInputDeviceId}'));
      children.add(CommonAutoSizeText(
          'selectedAudioOutputDeviceId:${room.selectedAudioOutputDeviceId}'));
      children.add(CommonAutoSizeText(
          'selectedVideoInputDeviceId:${room.selectedVideoInputDeviceId}'));
      children.add(CommonAutoSizeText('serverRegion:${room.serverRegion}'));
      children.add(CommonAutoSizeText('serverVersion:${room.serverVersion}'));
    }
    return ListView(
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: title,
      withLeading: withLeading,
      child: _buildVideoConferenceListView(context),
    );
  }
}
