import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as livekit_client;
import 'package:webrtc_interface/webrtc_interface.dart';

ValueNotifier<livekit_client.RemoteParticipant?> remoteParticipantNotifier =
    ValueNotifier<livekit_client.RemoteParticipant?>(null);

///Sfu会议池的会议的远程参与者的轨道列表显示界面
class SfuVideoConferenceTrackWidget extends StatelessWidget with TileDataMixin {
  const SfuVideoConferenceTrackWidget({Key? key}) : super(key: key);

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'sfu_video_conference_track';

  @override
  IconData get iconData => Icons.art_track_outlined;

  @override
  String get title => 'Sfu video conference track';

  List<TileData> _buildAudioTrackTileData(BuildContext context) {
    livekit_client.RemoteParticipant? remoteParticipant =
        remoteParticipantNotifier.value;
    List<TileData> tiles = [];
    if (remoteParticipant == null) {
      return tiles;
    }
    List<livekit_client.RemoteTrackPublication<livekit_client.RemoteAudioTrack>>
        remoteAudioTrackPublications = remoteParticipant.audioTracks;
    for (livekit_client.RemoteTrackPublication remoteAudioTrackPublication
        in remoteAudioTrackPublications) {
      livekit_client.RemoteTrack? remoteAudioTrack =
          remoteAudioTrackPublication.track;
      if (remoteAudioTrack == null) {
        continue;
      }
      MediaStream stream = remoteAudioTrack.mediaStream;
      MediaStreamTrack track = remoteAudioTrack.mediaStreamTrack;
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
          routeName: 'peer_connection_show');

      tiles.add(tile);
    }
    return tiles;
  }

  List<TileData> _buildVideoTrackTileData(BuildContext context) {
    livekit_client.RemoteParticipant? remoteParticipant =
        remoteParticipantNotifier.value;
    List<TileData> tiles = [];
    if (remoteParticipant == null) {
      return tiles;
    }
    List<livekit_client.RemoteTrackPublication<livekit_client.RemoteVideoTrack>>
        remoteVideoTrackPublications = remoteParticipant.videoTracks;
    for (livekit_client.RemoteTrackPublication remoteVideoTrackPublication
        in remoteVideoTrackPublications) {
      livekit_client.RemoteTrack? remoteVideoTrack =
          remoteVideoTrackPublication.track;
      if (remoteVideoTrack == null) {
        continue;
      }
      MediaStream stream = remoteVideoTrack.mediaStream;
      MediaStreamTrack track = remoteVideoTrack.mediaStreamTrack;
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
          routeName: 'peer_connection_show');

      tiles.add(tile);
    }
    return tiles;
  }

  Widget _buildTrackListView(BuildContext context) {
    var trackView = Column(children: [
      CommonAutoSizeText(AppLocalizations.t('AudioTrack')),
      DataListView(
        tileData: _buildAudioTrackTileData(context),
      ),
      const SizedBox(
        height: 15.0,
      ),
      CommonAutoSizeText(AppLocalizations.t('VideoTrack')),
      DataListView(
        tileData: _buildVideoTrackTileData(context),
      )
    ]);

    return trackView;
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
