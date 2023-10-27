import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:webrtc_interface/webrtc_interface.dart';

ValueNotifier<AdvancedPeerConnection?> peerConnectionNotifier =
    ValueNotifier<AdvancedPeerConnection?>(null);

///会议池的会议的连接的轨道列表显示界面
class VideoConferenceTrackWidget extends StatelessWidget with TileDataMixin {
  const VideoConferenceTrackWidget({Key? key}) : super(key: key);

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'video_conference_track';

  @override
  IconData get iconData => Icons.art_track_outlined;

  @override
  String get title => 'Video conference track';

  Future<List<TileData>> _buildTrackSenderTileData(BuildContext context) async {
    AdvancedPeerConnection? advancedPeerConnection =
        peerConnectionNotifier.value;
    List<TileData> tiles = [];
    if (advancedPeerConnection == null) {
      return tiles;
    }
    RTCPeerConnection? peerConnection =
        advancedPeerConnection.basePeerConnection.peerConnection;
    if (peerConnection == null) {
      return tiles;
    }
    List<RTCRtpSender>? trackSenders = await peerConnection.getSenders();
    for (var trackSender in trackSenders) {
      MediaStreamTrack? track = trackSender.track;
      String senderId = trackSender.senderId;
      if (track != null) {
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
            title: senderId,
            titleTail: platformParams.desktop ? label : null,
            subtitle: trackId,
            isThreeLine: false,
            onTap: (int index, String title, {String? subtitle}) {},
            routeName: 'peer_connection_show');

        tiles.add(tile);
      }
    }

    return tiles;
  }

  List<TileData> _buildTrackTileData(BuildContext context) {
    AdvancedPeerConnection? advancedPeerConnection =
        peerConnectionNotifier.value;
    List<TileData> tiles = [];
    if (advancedPeerConnection == null) {
      return tiles;
    }
    RTCPeerConnection? peerConnection =
        advancedPeerConnection.basePeerConnection.peerConnection;
    if (peerConnection == null) {
      return tiles;
    }
    List<MediaStream?> streams = [];
    List<MediaStream?> localStreams = peerConnection.getLocalStreams();
    streams.addAll(localStreams);
    List<MediaStream?> remoteStreams = peerConnection.getRemoteStreams();
    streams.addAll(remoteStreams);
    for (MediaStream? stream in streams) {
      if (stream == null) {
        continue;
      }
      String streamId = stream.id;
      String ownerTag = stream.ownerTag;
      List<MediaStreamTrack> tracks = [];
      List<MediaStreamTrack> videoTracks = stream.getVideoTracks();
      tracks.addAll(videoTracks);
      List<MediaStreamTrack> audioTracks = stream.getAudioTracks();
      tracks.addAll(audioTracks);
      for (MediaStreamTrack track in tracks) {
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
    }
    return tiles;
  }

  Widget _buildTrackListView(BuildContext context) {
    var trackView = Column(children: [
      CommonAutoSizeText(AppLocalizations.t('TrackSender')),
      FutureBuilder(
          future: _buildTrackSenderTileData(context),
          builder:
              (BuildContext context, AsyncSnapshot<List<TileData>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              List<TileData>? tiles = snapshot.data;
              if (tiles != null) {
                return DataListView(
                  tileData: tiles,
                );
              }
            }
            return LoadingUtil.buildLoadingIndicator();
          }),
      const SizedBox(
        height: 15.0,
      ),
      CommonAutoSizeText(AppLocalizations.t('Track')),
      DataListView(
        tileData: _buildTrackTileData(context),
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
