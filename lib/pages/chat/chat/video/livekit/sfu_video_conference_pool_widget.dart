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
import 'package:colla_chat/widgets/common/nil.dart';
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

  SfuVideoConferencePoolWidget({super.key}) {
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
                DialogUtil.info(
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
              DialogUtil.info(
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
        tiles.add(tile);
      }
    }
    return tiles;
  }

  Widget _buildVideoConferenceListView(BuildContext context) {
    List<Widget> children = [];
    var tileData = _buildConferenceTileData(context);
    var conferenceView = SizedBox(
        height: 200,
        child: DataListView(
          itemCount: tileData.length,
          itemBuilder: (BuildContext context, int index) {
            return tileData[index];
          },
        ));
    children.add(CommonAutoSizeText(AppLocalizations.t('Room')));
    children.add(conferenceView);
    children.add(CommonAutoSizeText(AppLocalizations.t('Room info')));
    children.add(Expanded(child: _buildRoomWidget(context)));

    return Column(
      children: children,
    );
  }

  Widget _buildRoomWidget(BuildContext context) {
    LiveKitConferenceClient? liveKitConferenceClient =
        liveKitConferenceClientPool.conferenceClient;
    if (liveKitConferenceClient == null) {
      return nil;
    }
    List<Widget> children = [];
    LiveKitRoomClient roomClient = liveKitConferenceClient.roomClient;
    children.add(
        CommonAutoSizeText('${AppLocalizations.t('uri')}:${roomClient.uri}'));
    children.add(CommonAutoSizeText(
        '${AppLocalizations.t('adaptiveStream')}:${roomClient.adaptiveStream}'));
    children.add(CommonAutoSizeText(
        '${AppLocalizations.t('dynacast')}:${roomClient.dynacast}'));
    children.add(
        CommonAutoSizeText('${AppLocalizations.t('e2ee')}:${roomClient.e2ee}'));
    children.add(CommonAutoSizeText(
        '${AppLocalizations.t('fastConnect')}:${roomClient.fastConnect}'));
    children.add(CommonAutoSizeText(
        '${AppLocalizations.t('sharedKey')}:${roomClient.sharedKey}'));
    children.add(CommonAutoSizeText(
        '${AppLocalizations.t('simulcast')}:${roomClient.simulcast}'));
    children.add(CommonAutoSizeText(
        '${AppLocalizations.t('token')}:${roomClient.token}'));
    children.add(CommonAutoSizeText(
        '${AppLocalizations.t('dynacast')}:${roomClient.dynacast}'));
    livekit_client.Room room = roomClient.room;
    if (room.connectionState == livekit_client.ConnectionState.connected) {
      children.add(
          CommonAutoSizeText('${AppLocalizations.t('name')}:${room.name}'));
      children.add(CommonAutoSizeText(
          '${AppLocalizations.t('connectionState')}:${room.connectionState}'));
      children.add(CommonAutoSizeText(
          '${AppLocalizations.t('autoSubscribe')}:${room.connectOptions.autoSubscribe}'));
      children.add(CommonAutoSizeText(
          '${AppLocalizations.t('encryptionType')}:${room.roomOptions.e2eeOptions?.encryptionType}'));
      children.add(CommonAutoSizeText(
          '${AppLocalizations.t('canPlaybackAudio')}:${room.canPlaybackAudio}'));

      children.add(CommonAutoSizeText(
          '${AppLocalizations.t('speakerOn')}:${room.speakerOn}'));
      children.add(CommonAutoSizeText(
          '${AppLocalizations.t('selectedAudioInputDeviceId')}:${room.selectedAudioInputDeviceId}'));
      children.add(CommonAutoSizeText(
          '${AppLocalizations.t('selectedAudioOutputDeviceId')}:${room.selectedAudioOutputDeviceId}'));
      children.add(CommonAutoSizeText(
          '${AppLocalizations.t('selectedVideoInputDeviceId')}:${room.selectedVideoInputDeviceId}'));
      children.add(CommonAutoSizeText(
          '${AppLocalizations.t('serverRegion')}:${room.serverRegion}'));
      children.add(CommonAutoSizeText(
          '${AppLocalizations.t('serverVersion')}:${room.serverVersion}'));
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
