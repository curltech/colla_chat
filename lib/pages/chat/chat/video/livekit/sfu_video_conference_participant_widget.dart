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
  final ValueNotifier<livekit_client.RemoteParticipant?>
      remoteParticipantNotifier =
      ValueNotifier<livekit_client.RemoteParticipant?>(null);

  SfuVideoConferenceParticipantWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(sfuVideoConferenceTrackWidget);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'sfu_video_conference_participant';

  @override
  IconData get iconData => Icons.connecting_airports_outlined;

  @override
  String get title => 'Sfu video conference participant';

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
            remoteParticipantNotifier.value = remoteParticipant;
            // indexWidgetProvider.push('sfu_video_conference_track');
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
            return SizedBox(
                height: 200, child: DataListView(tileData: tileData));
          }
          return LoadingUtil.buildLoadingIndicator();
        });

    return remoteParticipantView;
  }

  Widget _buildRemoteParticipantWidget(BuildContext context) {
    return ValueListenableBuilder<livekit_client.RemoteParticipant?>(
        valueListenable: remoteParticipantNotifier,
        builder: (BuildContext context,
            livekit_client.RemoteParticipant? remoteParticipant,
            Widget? child) {
          if (remoteParticipant == null) {
            return Container();
          }
          return _buildParticipantWidget(remoteParticipant);
        });
  }

  Widget _buildLocalParticipantWidget(BuildContext context) {
    LiveKitConferenceClient? liveKitConferenceClient =
        liveKitConferenceClientPool.conferenceClient;
    if (liveKitConferenceClient != null) {
      livekit_client.LocalParticipant? localParticipant =
          liveKitConferenceClient.localParticipant;
      if (localParticipant != null) {
        return SizedBox(
            height: 200, child: _buildParticipantWidget(localParticipant));
      }
    }

    return Container();
  }

  Widget _buildParticipantWidget(livekit_client.Participant participant) {
    List<Widget> children = [];
    children.add(CommonAutoSizeText('name:${participant.name}'));
    children.add(CommonAutoSizeText(
        'connectionQuality:${participant.connectionQuality}'));
    children.add(CommonAutoSizeText('joinedAt:${participant.joinedAt}'));
    children.add(CommonAutoSizeText('identity:${participant.identity}'));
    children.add(CommonAutoSizeText('audioLevel:${participant.audioLevel}'));
    children.add(CommonAutoSizeText(
        'firstTrackEncryptionType:${participant.firstTrackEncryptionType}'));
    children.add(CommonAutoSizeText('hasAudio:${participant.hasAudio}'));
    children.add(CommonAutoSizeText('hashCode:${participant.hashCode}'));
    children.add(CommonAutoSizeText('hasVideo:${participant.hasVideo}'));
    children.add(CommonAutoSizeText('isEncrypted:${participant.isEncrypted}'));
    children.add(CommonAutoSizeText('isMuted:${participant.isMuted}'));
    children.add(CommonAutoSizeText('lastSpokeAt:${participant.lastSpokeAt}'));
    children.add(CommonAutoSizeText('permissions:${participant.permissions}'));
    children.add(CommonAutoSizeText('sid:${participant.sid}'));
    children.add(
        CommonAutoSizeText('isCameraEnabled:${participant.isCameraEnabled()}'));
    children.add(CommonAutoSizeText(
        'isMicrophoneEnabled:${participant.isMicrophoneEnabled()}'));
    children.add(CommonAutoSizeText(
        'isScreenShareEnabled:${participant.isScreenShareEnabled()}'));
    children.add(SfuParticipantStatsWidget(
      participant: participant,
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
        child: Column(children: [
          _buildLocalParticipantWidget(context),
          _buildRemoteParticipantListView(context),
          Expanded(child: _buildRemoteParticipantWidget(context)),
        ]));
  }
}
