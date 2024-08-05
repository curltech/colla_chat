import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as livekit_client;
import 'package:webrtc_interface/webrtc_interface.dart';

ValueNotifier<livekit_client.Participant?> participantNotifier =
    ValueNotifier<livekit_client.Participant?>(null);

///Sfu会议池的会议的远程参与者的轨道列表显示界面
class SfuVideoConferenceTrackWidget extends StatelessWidget with TileDataMixin {
  ValueNotifier<livekit_client.TrackPublication?> trackPublication =
      ValueNotifier<livekit_client.TrackPublication?>(null);

  SfuVideoConferenceTrackWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'sfu_video_conference_track';

  @override
  IconData get iconData => Icons.art_track_outlined;

  @override
  String get title => 'Sfu video conference track';

  List<TileData> _buildAudioTrackTileData(BuildContext context) {
    livekit_client.Participant? participant = participantNotifier.value;
    List<TileData> tiles = [];
    if (participant == null) {
      return tiles;
    }
    List<livekit_client.TrackPublication<livekit_client.Track>>
        audioTrackPublications = participant.audioTrackPublications;
    for (livekit_client
        .TrackPublication<livekit_client.Track> audioTrackPublication
        in audioTrackPublications) {
      livekit_client.Track? audioTrack = audioTrackPublication.track;
      if (audioTrack == null) {
        continue;
      }
      MediaStream stream = audioTrack.mediaStream;
      MediaStreamTrack track = audioTrack.mediaStreamTrack;
      String streamId = stream.id;
      String ownerTag = stream.ownerTag;
      var trackId = track.id;
      var kind = track.kind;
      var label = track.label;
      TileData tile = TileData(
        prefix: kind == 'video'
            ? const Icon(
                Icons.video_call_outlined,
              )
            : const Icon(
                Icons.audiotrack_outlined,
              ),
        title: streamId,
        titleTail: platformParams.desktop ? ownerTag : null,
        subtitle: trackId,
        isThreeLine: false,
        onTap: (int index, String title, {String? subtitle}) {},
      );

      tiles.add(tile);
    }
    return tiles;
  }

  List<TileData> _buildVideoTrackTileData(BuildContext context) {
    livekit_client.Participant? participant = participantNotifier.value;
    List<TileData> tiles = [];
    if (participant == null) {
      return tiles;
    }
    List<livekit_client.TrackPublication<livekit_client.Track>>
        videoTrackPublications = participant.videoTrackPublications;
    for (livekit_client.TrackPublication videoTrackPublication
        in videoTrackPublications) {
      livekit_client.Track? videoTrack = videoTrackPublication.track;
      if (videoTrack == null) {
        continue;
      }
      MediaStream stream = videoTrack.mediaStream;
      MediaStreamTrack track = videoTrack.mediaStreamTrack;
      String streamId = stream.id;
      String ownerTag = stream.ownerTag;
      var trackId = track.id;
      var kind = track.kind;
      var label = track.label;
      TileData tile = TileData(
        prefix: kind == 'video'
            ? const Icon(
                Icons.video_call_outlined,
              )
            : const Icon(
                Icons.audiotrack_outlined,
              ),
        title: 'streamId:$streamId',
        titleTail: platformParams.desktop ? ownerTag : null,
        subtitle: 'trackId:$trackId',
        isThreeLine: false,
        onTap: (int index, String title, {String? subtitle}) {},
      );

      tiles.add(tile);
    }
    return tiles;
  }

  Widget _buildTrackListView(BuildContext context) {
    var audioTileData = _buildAudioTrackTileData(context);
    var videoTileData = _buildVideoTrackTileData(context);
    var trackView = Column(children: [
      CommonAutoSizeText(AppLocalizations.t('AudioTrack')),
      DataListView(
        itemCount: audioTileData.length,
        itemBuilder: (BuildContext context, int index) {
          return audioTileData[index];
        },
      ),
      const SizedBox(
        height: 15.0,
      ),
      CommonAutoSizeText(AppLocalizations.t('VideoTrack')),
      DataListView(
        itemCount: videoTileData.length,
        itemBuilder: (BuildContext context, int index) {
          return videoTileData[index];
        },
      ),
      const SizedBox(
        height: 15.0,
      ),
      _buildTrackPublicationWidget(context),
    ]);

    return trackView;
  }

  Widget _buildTrackPublicationWidget(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: trackPublication,
        builder: (BuildContext context,
            livekit_client.TrackPublication<livekit_client.Track>?
                trackPublication,
            Widget? child) {
          if (trackPublication == null) {
            return nil;
          }
          List<Widget> children = [];
          children.add(CommonAutoSizeText('name:${trackPublication.name}'));
          children.add(CommonAutoSizeText(
              'encryptionType:${trackPublication.encryptionType}'));
          children.add(CommonAutoSizeText(
              'isScreenShare:${trackPublication.isScreenShare}'));
          children
              .add(CommonAutoSizeText('mimeType:${trackPublication.mimeType}'));
          children.add(CommonAutoSizeText('muted:${trackPublication.muted}'));
          children.add(CommonAutoSizeText(
              'simulcasted:${trackPublication.simulcasted}'));
          children.add(
              CommonAutoSizeText('subscribed:${trackPublication.subscribed}'));

          livekit_client.Track? track = trackPublication.track;
          if (track != null) {
            children.add(CommonAutoSizeText('sid:${track.sid}'));
            children.add(CommonAutoSizeText('kind:${track.kind}'));
            children.add(CommonAutoSizeText('muted:${track.muted}'));
            children.add(CommonAutoSizeText('isActive:${track.isActive}'));
            children.add(CommonAutoSizeText('mediaType:${track.mediaType}'));
          }
          return ListView(
            children: children,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: title,
      withLeading: withLeading,
      child: _buildTrackListView(context),
    );
  }
}
