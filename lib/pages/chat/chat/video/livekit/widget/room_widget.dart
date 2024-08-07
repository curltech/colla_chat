import 'dart:convert';
import 'dart:math' as math;

import 'package:colla_chat/pages/chat/chat/video/livekit/widget/controls.dart';
import 'package:colla_chat/pages/chat/chat/video/livekit/widget/local_participant_widget.dart';
import 'package:colla_chat/pages/chat/chat/video/livekit/widget/participant_info.dart';
import 'package:colla_chat/pages/chat/chat/video/livekit/widget/remote_participant_widget.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

enum SimulateScenarioResult {
  signalReconnect,
  nodeFailure,
  migration,
  serverLeave,
  switchCandidate,
  clear,
  e2eeKeyRatchet,
}

class RoomWidget extends StatefulWidget {
  final Room room;
  final EventsListener<RoomEvent> listener;

  const RoomWidget(
    this.room,
    this.listener, {
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _RoomWidgetState();
}

class _RoomWidgetState extends State<RoomWidget> {
  List<ParticipantTrack> participantTracks = [];

  EventsListener<RoomEvent> get _listener => widget.listener;

  bool get fastConnection => widget.room.engine.fastConnectOptions != null;

  @override
  void initState() {
    super.initState();
    // add callback for a `RoomEvent` as opposed to a `ParticipantEvent`
    widget.room.addListener(_onRoomDidUpdate);
    // add callbacks for finer grained events
    _setUpListeners();
    _sortParticipants();
    WidgetsBindingCompatible.instance?.addPostFrameCallback((_) {
      if (!fastConnection) {
        _askPublish();
      }
    });

    if (lkPlatformIsMobile()) {
      Hardware.instance.setSpeakerphoneOn(true);
    }
  }

  @override
  void dispose() {
    // always dispose listener
    (() async {
      widget.room.removeListener(_onRoomDidUpdate);
      await _listener.dispose();
      await widget.room.dispose();
    })();
    super.dispose();
  }

  Future<bool?> showPublishDialog() async {
    bool? confirm = await DialogUtil.confirm(
        title: 'Publish',
        content: 'Would you like to publish your Camera & Mic ?');
    return confirm;
  }

  Future<bool?> showPlayAudioManuallyDialog() async {
    bool? confirm = await DialogUtil.confirm(
      title: 'Play Audio',
      content: 'You need to manually activate audio PlayBack for iOS Safari !',
      okLabel: 'Play Audio',
      cancelLabel: 'Ignore',
    );

    return confirm;
  }

  showErrorDialog(dynamic exception) {
    DialogUtil.error(content: exception.toString());
  }

  Future<bool?> showReconnectDialog() async {
    bool? confirm = await DialogUtil.confirm(
        title: 'Reconnect', content: 'This will force a reconnection');
    return confirm;
  }

  showReconnectSuccessDialog() {
    DialogUtil.info(content: 'Reconnection was successful.');
  }

  Future<bool?> showDataReceivedDialog(String data) async {
    bool? confirm =
        await DialogUtil.confirm(title: 'Received data', content: data);
    return confirm;
  }

  Future<bool?> showRecordingStatusChangedDialog(bool isActiveRecording) async {
    bool? confirm = await DialogUtil.confirm(
        title: 'Room recording reminder',
        content: isActiveRecording
            ? 'Room recording is active.'
            : 'Room recording is stoped.');
    return confirm;
  }

  /// 注册房间的监听器
  void _setUpListeners() {
    _listener
      ..on<RoomDisconnectedEvent>((event) async {
        if (event.reason != null) {
          print('Room disconnected: reason => ${event.reason}');
        }
        WidgetsBindingCompatible.instance
            ?.addPostFrameCallback((timeStamp) => Navigator.pop(context));
      })
      ..on<ParticipantEvent>((event) {
        print('Participant event');
        // sort participants on many track events as noted in documentation linked above
        _sortParticipants();
      })
      ..on<RoomRecordingStatusChanged>((event) {
        showRecordingStatusChangedDialog(event.activeRecording);
      })
      ..on<LocalTrackPublishedEvent>((_) => _sortParticipants())
      ..on<LocalTrackUnpublishedEvent>((_) => _sortParticipants())
      ..on<TrackE2EEStateEvent>(_onE2EEStateEvent)
      ..on<ParticipantNameUpdatedEvent>((event) {
        print(
            'Participant name updated: ${event.participant.identity}, name => ${event.name}');
      })
      ..on<DataReceivedEvent>((event) {
        String decoded = 'Failed to decode';
        try {
          decoded = utf8.decode(event.data);
        } catch (_) {
          print('Failed to decode: $_');
        }
        showDataReceivedDialog(decoded);
      })
      ..on<AudioPlaybackStatusChanged>((event) async {
        if (!widget.room.canPlaybackAudio) {
          print('Audio playback failed for iOS Safari ..........');
          bool? yesno = await showPlayAudioManuallyDialog();
          if (yesno == true) {
            await widget.room.startAudio();
          }
        }
      });
  }

  /// 发布本地视频
  void _askPublish() async {
    final result = await showPublishDialog();
    if (result != true) return;
    try {
      await widget.room.localParticipant?.setCameraEnabled(true);
    } catch (error) {
      print('could not publish video: $error');
      await showErrorDialog(error);
    }
    try {
      await widget.room.localParticipant?.setMicrophoneEnabled(true);
    } catch (error) {
      print('could not publish audio: $error');
      await showErrorDialog(error);
    }
  }

  void _onRoomDidUpdate() {
    _sortParticipants();
  }

  void _onE2EEStateEvent(TrackE2EEStateEvent e2eeState) {
    print('e2ee state: $e2eeState');
  }

  /// 排列参与者的视频轨道
  void _sortParticipants() {
    List<ParticipantTrack> userMediaTracks = [];
    List<ParticipantTrack> screenTracks = [];
    for (var participant in widget.room.remoteParticipants.values) {
      for (var t in participant.videoTrackPublications) {
        if (t.isScreenShare) {
          screenTracks.add(ParticipantTrack(
            participant: participant,
            videoTrack: t.track,
            isScreenShare: true,
          ));
        } else {
          userMediaTracks.add(ParticipantTrack(
            participant: participant,
            videoTrack: t.track,
            isScreenShare: false,
          ));
        }
      }
    }
    // sort speakers for the grid
    userMediaTracks.sort((a, b) {
      // loudest speaker first
      if (a.participant.isSpeaking && b.participant.isSpeaking) {
        if (a.participant.audioLevel > b.participant.audioLevel) {
          return -1;
        } else {
          return 1;
        }
      }

      // last spoken at
      final aSpokeAt = a.participant.lastSpokeAt?.millisecondsSinceEpoch ?? 0;
      final bSpokeAt = b.participant.lastSpokeAt?.millisecondsSinceEpoch ?? 0;

      if (aSpokeAt != bSpokeAt) {
        return aSpokeAt > bSpokeAt ? -1 : 1;
      }

      // video on
      if (a.participant.hasVideo != b.participant.hasVideo) {
        return a.participant.hasVideo ? -1 : 1;
      }

      // joinedAt
      return a.participant.joinedAt.millisecondsSinceEpoch -
          b.participant.joinedAt.millisecondsSinceEpoch;
    });

    final localParticipantTracks =
        widget.room.localParticipant?.videoTrackPublications;
    if (localParticipantTracks != null) {
      for (var t in localParticipantTracks) {
        if (t.isScreenShare) {
          screenTracks.add(ParticipantTrack(
            participant: widget.room.localParticipant!,
            videoTrack: t.track,
            isScreenShare: true,
          ));
        } else {
          userMediaTracks.add(ParticipantTrack(
            participant: widget.room.localParticipant!,
            videoTrack: t.track,
            isScreenShare: false,
          ));
        }
      }
    }
    setState(() {
      participantTracks = [...screenTracks, ...userMediaTracks];
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                    child: participantTracks.isNotEmpty
                        ? LocalParticipantWidget(
                            participantTracks.first.participant
                                as LocalParticipant,
                            participantTracks.first.videoTrack,
                            participantTracks.first.isScreenShare,
                            true)
                        : nil),
                if (widget.room.localParticipant != null)
                  SafeArea(
                    top: false,
                    child: ControlsWidget(
                        widget.room, widget.room.localParticipant!),
                  )
              ],
            ),
            Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: SizedBox(
                  height: 120,
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: math.max(0, participantTracks.length - 1),
                      itemBuilder: (BuildContext context, int index) {
                        ParticipantTrack remoteParticipantTrack =
                            participantTracks[index + 1];
                        return SizedBox(
                          width: 180,
                          height: 120,
                          child: RemoteParticipantWidget(
                              remoteParticipantTrack.participant
                                  as RemoteParticipant,
                              remoteParticipantTrack.videoTrack,
                              remoteParticipantTrack.isScreenShare,
                              true),
                        );
                      }),
                )),
          ],
        ),
      );
}
