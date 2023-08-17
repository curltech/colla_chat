import 'package:livekit_client/livekit_client.dart';

class LiveKitClient {
  final bool _e2ee = true;
  final String sharedKey = '';
  final String uri = '';
  final String token = '';
  final bool adaptiveStream = true;
  final bool dynacast = false;
  final bool simulcast = true;
  final bool fastConnect = false;
  final room = Room();

  Future<void> connect() async {
    // Create a Listener before connecting
    EventsListener<RoomEvent> listener = room.createListener();
    E2EEOptions? e2eeOptions;
    if (_e2ee) {
      final keyProvider = await BaseKeyProvider.create();
      e2eeOptions = E2EEOptions(keyProvider: keyProvider);
      await keyProvider.setKey(sharedKey);
    }

    // Try to connect to the room
    // This will throw an Exception if it fails for any reason.
    await room.connect(
      uri,
      token,
      roomOptions: RoomOptions(
        adaptiveStream: adaptiveStream,
        dynacast: dynacast,
        defaultAudioPublishOptions:
            const AudioPublishOptions(name: 'custom_audio_track_name'),
        defaultVideoPublishOptions: VideoPublishOptions(
          simulcast: simulcast,
        ),
        defaultScreenShareCaptureOptions: const ScreenShareCaptureOptions(
            useiOSBroadcastExtension: true,
            params: VideoParameters(
                dimensions: VideoDimensionsPresets.h1080_169,
                encoding: VideoEncoding(
                  maxBitrate: 3 * 1000 * 1000,
                  maxFramerate: 15,
                ))),
        e2eeOptions: e2eeOptions,
        defaultCameraCaptureOptions: const CameraCaptureOptions(
            maxFrameRate: 30,
            params: VideoParameters(
                dimensions: VideoDimensionsPresets.h720_169,
                encoding: VideoEncoding(
                  maxBitrate: 2 * 1000 * 1000,
                  maxFramerate: 30,
                ))),
      ),
      fastConnectOptions: fastConnect
          ? FastConnectOptions(
              microphone: const TrackOption(enabled: true),
              camera: const TrackOption(enabled: true),
            )
          : null,
    );

    room.localParticipant?.addListener(_onChange);

    // ParticipantConnected	A RemoteParticipant joins after the local participant.	x
    // ParticipantDisconnected	A RemoteParticipant leaves	x
    // Reconnecting	The connection to the server has been interrupted and it's attempting to reconnect.	x
    // Reconnected	Reconnection has been successful	x
    // Disconnected	Disconnected from room due to the room closing or unrecoverable failure	x
    // TrackPublished	A new track is published to room after the local participant has joined	x	x
    // TrackUnpublished	A RemoteParticipant has unpublished a track	x	x
    // TrackSubscribed	The LocalParticipant has subscribed to a track	x	x
    // TrackUnsubscribed	A previously subscribed track has been unsubscribed	x	x
    // TrackMuted	A track was muted, fires for both local tracks and remote tracks	x	x
    // TrackUnmuted	A track was unmuted, fires for both local tracks and remote tracks	x	x
    // LocalTrackPublished	A local track was published successfully	x	x
    // LocalTrackUnpublished	A local track was unpublished	x	x
    // ActiveSpeakersChanged	Current active speakers has changed	x
    // IsSpeakingChanged	The current participant has changed speaking status		x
    // ConnectionQualityChanged	Connection quality was changed for a Participant	x	x
    // ParticipantMetadataChanged	A participant's metadata was updated via server API	x	x
    // RoomMetadataChanged	Metadata associated with the room has changed	x
    // DataReceived	Data received from another participant or server	x	x
    // TrackStreamStateChanged	Indicates if a subscribed track has been paused due to bandwidth	x	x
    // TrackSubscriptionPermissionChanged	One of subscribed tracks have changed track-level permissions for the current participant	x	x
    // ParticipantPermissionsChanged	When the current participant's permissions have changed

    listener.on<DataReceivedEvent>((e) {
      // process received data: e.data
    });
    listener.on<SpeakingChangedEvent>((e) {
      // handle isSpeaking change
    });
    listener.on<TrackPublishedEvent>((e) {
      e.publication.subscribe();
    });
    listener.on<TrackSubscribedEvent>((e) {
      if (e.publication.kind == TrackType.VIDEO) {
        e.publication.videoQuality = VideoQuality.LOW;
      }
    });
    listener
      ..on<RoomDisconnectedEvent>((_) {
        // handle disconnect
      })
      ..on<ParticipantConnectedEvent>((e) {
        print("participant joined: ${e.participant.identity}");
      });

    // also subscribe to tracks published before participant joined
    for (RemoteParticipant participant in room.participants.values) {
      for (RemoteTrackPublication publication
          in participant.trackPublications.values) {
        publication.subscribe();
      }
    }
  }

  ///参与者的轨道改变
  void _onChange() {
    TrackPublication? pub;
    var videoTracks = room.localParticipant?.videoTracks;
    if (videoTracks != null && videoTracks.isNotEmpty) {
      for (LocalTrackPublication<LocalVideoTrack> videoTrack in videoTracks) {
        videoTrack.kind == TrackType.VIDEO &&
            videoTrack.subscribed &&
            !videoTrack.muted;
      }
    }
  }

  void publishData(
    List<int> data, {
    Reliability reliability = Reliability.reliable,
    List<String>? destinationSids,
    String? topic,
  }) {
    // publish lossy data to the entire room
    room.localParticipant?.publishData(data,
        reliability: reliability,
        destinationSids: destinationSids,
        topic: topic);
  }

  void disableTrack(RemoteTrackPublication publication) {
    publication.enabled;
  }

  ///打开本地视频
  setCameraEnabled() {
    // Turns camera track on
    room.localParticipant?.setCameraEnabled(true);
  }

  ///打开本地音频
  setMicrophoneEnabled() {
    // Turns microphone track on
    room.localParticipant?.setMicrophoneEnabled(true);
  }

  setScreenShareEnabled() {
    room.localParticipant?.setScreenShareEnabled(true);
  }

  setTrackSubscriptionPermissions() {
    room.localParticipant?.setTrackSubscriptionPermissions(
      allParticipantsAllowed: false,
      trackPermissions: [
        const ParticipantTrackPermission('allowed-identity', true, null)
      ],
    );
  }

  createCameraTrack() async {
    try {
      // video will fail when running in ios simulator
      LocalVideoTrack localVideo =
          await LocalVideoTrack.createCameraTrack(const CameraCaptureOptions(
        cameraPosition: CameraPosition.front,
        params: VideoParametersPresets.h720_169,
      ));
      await room.localParticipant?.publishVideoTrack(localVideo);
    } catch (e) {
      print('could not publish video: $e');
    }

    LocalAudioTrack localAudio =
        await LocalAudioTrack.create(const AudioCaptureOptions());
    await room.localParticipant?.publishAudioTrack(localAudio);
  }

  VideoTrackRenderer buildVideoTrackRenderer(VideoTrack track) {
    return VideoTrackRenderer(track);
  }

  disconnect() {
    room.disconnect();
  }
}
