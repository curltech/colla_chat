import 'package:colla_chat/pages/chat/chat/video/livekit/widget/no_video.dart';
import 'package:colla_chat/pages/chat/chat/video/livekit/widget/participant_info.dart';
import 'package:colla_chat/pages/chat/chat/video/livekit/widget/participant_stats.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';

class RemoteParticipantWidget extends StatefulWidget {
  final RemoteParticipant participant;
  final VideoTrack? videoTrack;
  final bool isScreenShare;
  final bool showStatsLayer;
  final VideoQuality quality;

  const RemoteParticipantWidget(
    this.participant,
    this.videoTrack,
    this.isScreenShare,
    this.showStatsLayer, {
    super.key,
    this.quality = VideoQuality.MEDIUM,
  });

  @override
  State<StatefulWidget> createState() => _RemoteParticipantWidgetState();
}

class _RemoteParticipantWidgetState<T extends RemoteParticipantWidget>
    extends State<T> {
  //
  bool _visible = true;

  RemoteTrackPublication<RemoteVideoTrack>? get videoPublication =>
      widget.participant.videoTracks
          .where((element) => element.sid == widget.videoTrack?.sid)
          .firstOrNull;

  RemoteTrackPublication<RemoteAudioTrack>? get firstAudioPublication =>
      widget.participant.audioTracks.firstOrNull;

  VideoTrack? get activeVideoTrack => widget.videoTrack;

  List<Widget> extraWidgets(bool isScreenShare) => [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Menu for RemoteTrackPublication<RemoteAudioTrack>
            if (firstAudioPublication != null && !isScreenShare)
              RemoteTrackPublicationMenuWidget(
                pub: firstAudioPublication!,
                icon: Icons.volume_up,
              ),
            // Menu for RemoteTrackPublication<RemoteVideoTrack>
            if (videoPublication != null)
              RemoteTrackPublicationMenuWidget(
                pub: videoPublication!,
                icon: isScreenShare ? Icons.monitor : Icons.videocam,
              ),
            if (videoPublication != null)
              RemoteTrackFPSMenuWidget(
                pub: videoPublication!,
                icon: Icons.menu,
              ),
          ],
        ),
      ];

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

class RemoteTrackPublicationMenuWidget extends StatelessWidget {
  final IconData icon;
  final RemoteTrackPublication pub;

  const RemoteTrackPublicationMenuWidget({
    required this.pub,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black.withOpacity(0.3),
        child: PopupMenuButton<Function>(
          tooltip: 'Subscribe menu',
          icon: Icon(icon,
              color: {
                TrackSubscriptionState.notAllowed: Colors.red,
                TrackSubscriptionState.unsubscribed: Colors.grey,
                TrackSubscriptionState.subscribed: Colors.green,
              }[pub.subscriptionState]),
          onSelected: (value) => value(),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<Function>>[
            // Subscribe/Unsubscribe
            if (pub.subscribed == false)
              PopupMenuItem(
                child: const Text('Subscribe'),
                value: () => pub.subscribe(),
              )
            else if (pub.subscribed == true)
              PopupMenuItem(
                child: const Text('Un-subscribe'),
                value: () => pub.unsubscribe(),
              ),
          ],
        ),
      );
}

class RemoteTrackFPSMenuWidget extends StatelessWidget {
  final IconData icon;
  final RemoteTrackPublication pub;

  const RemoteTrackFPSMenuWidget({
    required this.pub,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black.withOpacity(0.3),
        child: PopupMenuButton<Function>(
          tooltip: 'PreferredFPS',
          icon: Icon(icon, color: Colors.white),
          onSelected: (value) => value(),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<Function>>[
            PopupMenuItem(
              child: const Text('30'),
              value: () => pub.setVideoFPS(30),
            ),
            PopupMenuItem(
              child: const Text('15'),
              value: () => pub.setVideoFPS(15),
            ),
            PopupMenuItem(
              child: const Text('8'),
              value: () => pub.setVideoFPS(8),
            ),
          ],
        ),
      );
}
