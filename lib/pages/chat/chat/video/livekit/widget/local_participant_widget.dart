import 'package:colla_chat/pages/chat/chat/video/livekit/widget/no_video.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';

import 'participant_info.dart';
import 'participant_stats.dart';

class LocalParticipantWidget extends StatefulWidget {
  final LocalParticipant participant;
  final VideoTrack? videoTrack;
  final bool isScreenShare;
  final bool showStatsLayer;
  final VideoQuality quality;

  const LocalParticipantWidget(
    this.participant,
    this.videoTrack,
    this.isScreenShare,
    this.showStatsLayer, {
    super.key,
    this.quality = VideoQuality.MEDIUM,
  });

  @override
  State<StatefulWidget> createState() => _LocalParticipantWidgetState();
}

class _LocalParticipantWidgetState<T extends LocalParticipantWidget>
    extends State<T> {
  bool _visible = true;

  LocalTrackPublication<LocalVideoTrack>? get videoPublication =>
      widget.participant.videoTracks
          .where((element) => element.sid == widget.videoTrack?.sid)
          .firstOrNull;

  LocalTrackPublication<LocalAudioTrack>? get firstAudioPublication =>
      widget.participant.audioTracks.firstOrNull;

  VideoTrack? get activeVideoTrack => widget.videoTrack;

  @override
  void initState() {
    super.initState();
    widget.participant.addListener(_onParticipantChanged);
    _onParticipantChanged();
  }

  @override
  void dispose() {
    widget.participant.removeListener(_onParticipantChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    oldWidget.participant.removeListener(_onParticipantChanged);
    widget.participant.addListener(_onParticipantChanged);
    _onParticipantChanged();
    super.didUpdateWidget(oldWidget);
  }

  // Notify Flutter that UI re-build is required, but we don't set anything here
  // since the updated values are computed properties.
  void _onParticipantChanged() => setState(() {});

  // Widgets to show above the info bar
  List<Widget> extraWidgets(bool isScreenShare) => [];

  @override
  Widget build(BuildContext ctx) => Container(
        foregroundDecoration: BoxDecoration(
          border: widget.participant.isSpeaking && !widget.isScreenShare
              ? Border.all(
                  width: 5,
                  color: Colors.blue,
                )
              : null,
        ),
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
        ),
        child: Stack(
          children: [
            // Video
            InkWell(
              onTap: () => setState(() => _visible = !_visible),
              child: activeVideoTrack != null && !activeVideoTrack!.muted
                  ? VideoTrackRenderer(
                      activeVideoTrack!,
                      fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                    )
                  : const NoVideoWidget(),
            ),
            if (widget.showStatsLayer)
              Positioned(
                  top: 30,
                  right: 30,
                  child: ParticipantStatsWidget(
                    participant: widget.participant,
                  )),
            // Bottom bar
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...extraWidgets(widget.isScreenShare),
                  ParticipantInfoWidget(
                    title: widget.participant.name.isNotEmpty
                        ? '${widget.participant.name} (${widget.participant.identity})'
                        : widget.participant.identity,
                    audioAvailable: firstAudioPublication?.muted == false &&
                        firstAudioPublication?.subscribed == true,
                    connectionQuality: widget.participant.connectionQuality,
                    isScreenShare: widget.isScreenShare,
                    enabledE2EE: widget.participant.firstTrackEncryptionType !=
                        EncryptionType.kNone,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
