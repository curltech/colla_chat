import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/video/livekit/sfu_video_conference_track_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
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
      SfuVideoConferenceTrackWidget();

  SfuVideoConferenceParticipantWidget({super.key}) {
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

  List<TileData> _buildRemoteParticipantTileData(BuildContext context) {
    LiveKitConferenceClient? liveKitConferenceClient =
        liveKitConferenceClientPool.conferenceClient;
    List<TileData> tiles = [];
    if (liveKitConferenceClient != null) {
      List<livekit_client.RemoteParticipant> remoteParticipants =
          liveKitConferenceClient.remoteParticipants;
      for (livekit_client.RemoteParticipant remoteParticipant
          in remoteParticipants) {
        TileData tile = _buildTileData(remoteParticipant);

        tiles.add(tile);
      }
    }
    return tiles;
  }

  TileData _buildTileData(livekit_client.Participant participant) {
    var identity = participant.identity;
    var name = participant.name;
    var joinedAt = participant.joinedAt;
    var connectionQuality = participant.connectionQuality;
    TileData tile = TileData(
      prefix: connectionQuality.name,
      title: name,
      titleTail: joinedAt.toIso8601String(),
      subtitle: identity,
      isThreeLine: false,
      onTap: (int index, String title, {String? subtitle}) {
        participantNotifier.value = participant;
      },
    );
    List<TileData> slideActions = [];
    TileData checkSlideAction = TileData(
        title: 'Track',
        prefix: Icons.multitrack_audio_outlined,
        onTap: (int index, String label, {String? subtitle}) async {
          participantNotifier.value = participant;
          indexWidgetProvider.push('sfu_video_conference_track');
        });
    slideActions.add(checkSlideAction);
    tile.slideActions = slideActions;
    return tile;
  }

  Widget _buildRemoteParticipantListView(BuildContext context) {
    List<TileData> tileData = _buildRemoteParticipantTileData(context);
    return SizedBox(height: 200, child: DataListView(tileData: tileData));
  }

  Widget _buildParticipantWidget(BuildContext context) {
    return ValueListenableBuilder<livekit_client.Participant?>(
        valueListenable: participantNotifier,
        builder: (BuildContext context, livekit_client.Participant? participant,
            Widget? child) {
          if (participant == null) {
            return Container();
          }
          List<Widget> children = [];
          children.add(CommonAutoSizeText('name:${participant.name}'));
          children.add(CommonAutoSizeText(
              'connectionQuality:${participant.connectionQuality}'));
          children.add(CommonAutoSizeText('joinedAt:${participant.joinedAt}'));
          children.add(CommonAutoSizeText('identity:${participant.identity}'));
          children
              .add(CommonAutoSizeText('audioLevel:${participant.audioLevel}'));
          children.add(CommonAutoSizeText(
              'firstTrackEncryptionType:${participant.firstTrackEncryptionType}'));
          children.add(CommonAutoSizeText('hasAudio:${participant.hasAudio}'));
          children.add(CommonAutoSizeText('hashCode:${participant.hashCode}'));
          children.add(CommonAutoSizeText('hasVideo:${participant.hasVideo}'));
          children.add(
              CommonAutoSizeText('isEncrypted:${participant.isEncrypted}'));
          children.add(CommonAutoSizeText('isMuted:${participant.isMuted}'));
          children.add(
              CommonAutoSizeText('lastSpokeAt:${participant.lastSpokeAt}'));
          children.add(
              CommonAutoSizeText('permissions:${participant.permissions}'));
          children.add(CommonAutoSizeText('sid:${participant.sid}'));
          children.add(CommonAutoSizeText(
              'isCameraEnabled:${participant.isCameraEnabled()}'));
          children.add(CommonAutoSizeText(
              'isMicrophoneEnabled:${participant.isMicrophoneEnabled()}'));
          children.add(CommonAutoSizeText(
              'isScreenShareEnabled:${participant.isScreenShareEnabled()}'));
          // children.add(SfuParticipantStatsWidget(
          //   participant: participant,
          // ));
          return ListView(
            children: children,
          );
        });
  }

  Widget _buildLocalParticipantWidget(BuildContext context) {
    List<TileData> tileData = [];
    LiveKitConferenceClient? liveKitConferenceClient =
        liveKitConferenceClientPool.conferenceClient;
    if (liveKitConferenceClient != null) {
      livekit_client.LocalParticipant? localParticipant =
          liveKitConferenceClient.localParticipant;
      if (localParticipant != null) {
        tileData.add(_buildTileData(localParticipant));
      }
    }

    return SizedBox(height: 80, child: DataListView(tileData: tileData));
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: title,
        withLeading: withLeading,
        child: Column(children: [
          CommonAutoSizeText(AppLocalizations.t('LocalParticipant')),
          _buildLocalParticipantWidget(context),
          const SizedBox(
            height: 15.0,
          ),
          CommonAutoSizeText(AppLocalizations.t('RemoteParticipant')),
          _buildRemoteParticipantListView(context),
          const SizedBox(
            height: 15.0,
          ),
          CommonAutoSizeText(AppLocalizations.t('Participant info')),
          Expanded(child: _buildParticipantWidget(context)),
        ]));
  }
}
