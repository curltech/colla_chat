import 'package:colla_chat/pages/chat/chat/video/livekit/sfu_participant_stats.dart';
import 'package:colla_chat/pages/chat/chat/video/livekit/sfu_video_conference_track_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/transport/webrtc/livekit/sfu_room_client.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as livekit_client;

///Sfu会议池的会议的远程参与者列表显示界面
class SfuVideoConferenceParticipantWidget extends StatelessWidget
    with TileDataMixin {
  final SfuVideoConferenceTrackWidget sfuVideoConferenceTrackWidget =
      const SfuVideoConferenceTrackWidget();

  SfuVideoConferenceParticipantWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(sfuVideoConferenceTrackWidget);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'video_conference_participant';

  @override
  IconData get iconData => Icons.connecting_airports_outlined;

  @override
  String get title => 'Video conference participant';

  Future<List<TileData>> _buildRemoteParticipantTileData(
      BuildContext context) async {
    LiveKitConferenceClient? liveKitConferenceClient =
        liveKitConferenceClientPool.conferenceClient;
    List<TileData> tiles = [];
    if (liveKitConferenceClient != null) {
      List<livekit_client.RemoteParticipant> remoteParticipants =
          liveKitConferenceClient.remoteParticipants.values.toList();
      for (livekit_client.RemoteParticipant remoteParticipant
          in remoteParticipants) {
        var identity = remoteParticipant.identity;
        var name = remoteParticipant.name;
        var joinedAt = remoteParticipant.joinedAt;
        var connectionQuality = remoteParticipant.connectionQuality;
        TileData tile = TileData(
          prefix:
              connectionQuality == livekit_client.ConnectionQuality.excellent ||
                      connectionQuality == livekit_client.ConnectionQuality.good
                  ? const Icon(
                      Icons.light_mode,
                      color: Colors.yellow,
                    )
                  : const Icon(
                      Icons.light_mode,
                      color: Colors.grey,
                    ),
          title: name,
          titleTail: joinedAt.toIso8601String(),
          subtitle: identity,
          isThreeLine: false,
          onTap: (int index, String title, {String? subtitle}) {
            indexWidgetProvider.push('video_conference_track');
          },
        );

        tiles.add(tile);
      }
    }
    return tiles;
  }

  Widget _buildRemoteParticipantListView(BuildContext context) {
    var remoteParticipantView = FutureBuilder(
        future: _buildRemoteParticipantTileData(context),
        builder:
            (BuildContext context, AsyncSnapshot<List<TileData>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            List<TileData>? tileData = snapshot.data;
            tileData ??= [];
            return DataListView(tileData: tileData);
          }
          return LoadingUtil.buildLoadingIndicator();
        });

    return remoteParticipantView;
  }

  Widget _buildLiveKitConferenceClientView(
      livekit_client.RemoteParticipant remoteParticipant) {
    List<Widget> children = [];
    children.add(CommonAutoSizeText('name:${remoteParticipant.name}'));
    children.add(CommonAutoSizeText(
        'connectionQuality:${remoteParticipant.connectionQuality}'));
    children.add(CommonAutoSizeText('joinedAt:${remoteParticipant.joinedAt}'));
    children.add(CommonAutoSizeText('identity:${remoteParticipant.identity}'));
    children
        .add(CommonAutoSizeText('audioLevel:${remoteParticipant.audioLevel}'));
    children.add(CommonAutoSizeText(
        'firstTrackEncryptionType:${remoteParticipant.firstTrackEncryptionType}'));
    children.add(CommonAutoSizeText('hasAudio:${remoteParticipant.hasAudio}'));
    children.add(CommonAutoSizeText('hashCode:${remoteParticipant.hashCode}'));
    children.add(CommonAutoSizeText('hasInfo:${remoteParticipant.hasInfo}'));
    children.add(CommonAutoSizeText('hasVideo:${remoteParticipant.hasVideo}'));
    children.add(
        CommonAutoSizeText('isEncrypted:${remoteParticipant.isEncrypted}'));
    children.add(CommonAutoSizeText('isMuted:${remoteParticipant.isMuted}'));
    children.add(
        CommonAutoSizeText('lastSpokeAt:${remoteParticipant.lastSpokeAt}'));
    children.add(
        CommonAutoSizeText('permissions:${remoteParticipant.permissions}'));
    children.add(CommonAutoSizeText('sid:${remoteParticipant.sid}'));
    children.add(CommonAutoSizeText(
        'isCameraEnabled:${remoteParticipant.isCameraEnabled()}'));
    children.add(CommonAutoSizeText(
        'isMicrophoneEnabled:${remoteParticipant.isMicrophoneEnabled()}'));
    children.add(CommonAutoSizeText(
        'isScreenShareEnabled:${remoteParticipant.isScreenShareEnabled()}'));
    children.add(SfuParticipantStatsWidget(
      participant: remoteParticipant,
    ));

    return ListView(
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: title,
      withLeading: withLeading,
      child: _buildRemoteParticipantListView(context),
    );
  }
}
