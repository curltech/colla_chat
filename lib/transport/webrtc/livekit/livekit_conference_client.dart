import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:webrtc_interface/webrtc_interface.dart';

///LiveKit的房间连接客户端
class LiveKitConferenceClient {
  final bool _e2ee = true;
  final String sharedKey = '';
  final String uri = '';
  final String token = '';
  final bool adaptiveStream = true;
  final bool dynacast = false;
  final bool simulcast = true;
  final bool fastConnect = false;
  final Room room = Room();

  String? get id {
    return room.sid;
  }

  String? get name {
    return room.name;
  }

  ///连接服务器，根据token建立房间的连接
  Future<void> connect() async {
    E2EEOptions? e2eeOptions;
    if (_e2ee) {
      final keyProvider = await BaseKeyProvider.create();
      e2eeOptions = E2EEOptions(keyProvider: keyProvider);
      await keyProvider.setKey(sharedKey);
    }

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

    // Create a Listener before connecting
    EventsListener<RoomEvent> listener = room.createListener();
    //接收数据
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

    //本地参与者的监听器
    room.localParticipant?.addListener(_onLocalParticipantChange);
  }

  ///订阅远程参与者的轨道
  subscribe(List<String> participants) {
    for (MapEntry<String, RemoteParticipant> entry
        in room.participants.entries) {
      String participantId = entry.key;
      if (participants.contains(participantId)) {
        RemoteParticipant participant = entry.value;
        for (RemoteTrackPublication publication
            in participant.trackPublications.values) {
          publication.subscribe();
        }
      }
    }
  }

  ///参与者的轨道改变
  void _onLocalParticipantChange() {
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

  ///发送数据
  Future<void> publishData(
    List<int> data, {
    Reliability reliability = Reliability.reliable,
    List<String>? destinationSids,
    String? topic,
  }) async {
    await room.localParticipant?.publishData(data,
        reliability: reliability,
        destinationSids: destinationSids,
        topic: topic);
  }

  ///激活轨道
  Future<void> enableTrack(RemoteTrackPublication publication) async {
    await publication.enable();
  }

  ///禁止轨道
  Future<void> disableTrack(RemoteTrackPublication publication) async {
    await publication.disable();
  }

  ///打开发布本地视频
  Future<LocalTrackPublication<LocalTrack>?> setCameraEnabled(bool enabled,
      {CameraCaptureOptions? cameraCaptureOptions}) async {
    return await room.localParticipant
        ?.setCameraEnabled(enabled, cameraCaptureOptions: cameraCaptureOptions);
  }

  ///打开发布本地音频
  Future<LocalTrackPublication<LocalTrack>?> setMicrophoneEnabled(bool enabled,
      {AudioCaptureOptions? audioCaptureOptions}) async {
    return await room.localParticipant?.setMicrophoneEnabled(enabled,
        audioCaptureOptions: audioCaptureOptions);
  }

  ///打开发布屏幕共享，screenShareCaptureOptions包含源界面的编号
  Future<LocalTrackPublication<LocalTrack>?> setScreenShareEnabled(
    bool enabled, {
    bool? captureScreenAudio,
    ScreenShareCaptureOptions? screenShareCaptureOptions,
  }) async {
    return await room.localParticipant?.setScreenShareEnabled(enabled,
        captureScreenAudio: captureScreenAudio,
        screenShareCaptureOptions: screenShareCaptureOptions);
  }

  Future<LocalVideoTrack> createScreenShareTrack({
    ScreenShareCaptureOptions? screenShareCaptureOptions,
  }) async {
    return await LocalVideoTrack.createScreenShareTrack(
        screenShareCaptureOptions);
  }

  ///设置可否订阅本地轨道的参与人
  setTrackSubscriptionPermissions(
      {required bool allParticipantsAllowed,
      List<String> participants = const []}) {
    List<ParticipantTrackPermission> trackPermissions = [];
    for (var participant in participants) {
      trackPermissions.add(ParticipantTrackPermission(participant, true, null));
    }
    room.localParticipant?.setTrackSubscriptionPermissions(
      allParticipantsAllowed: allParticipantsAllowed,
      trackPermissions: trackPermissions,
    );
  }

  ///创建本地视频并发布
  Future<LocalTrackPublication<LocalVideoTrack>?> publishVideoTrack(
      {CameraCaptureOptions options = const CameraCaptureOptions(
        cameraPosition: CameraPosition.front,
        params: VideoParametersPresets.h720_169,
      )}) async {
    try {
      LocalVideoTrack localVideo =
          await LocalVideoTrack.createCameraTrack(options);
      return await room.localParticipant?.publishVideoTrack(localVideo);
    } catch (e) {
      logger.warning('could not publish video: $e');
    }
  }

  ///创建本地音频并发布
  Future<LocalTrackPublication<LocalAudioTrack>?> publishAudioTrack(
      {AudioCaptureOptions options = const AudioCaptureOptions()}) async {
    try {
      LocalAudioTrack localAudio = await LocalAudioTrack.create(options);
      return await room.localParticipant?.publishAudioTrack(localAudio);
    } catch (e) {
      logger.warning('could not publish audio: $e');
    }
  }

  VideoTrackRenderer buildVideoTrackRenderer(
    VideoTrack track, {
    RTCVideoViewObjectFit fit =
        RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    VideoViewMirrorMode mirrorMode = VideoViewMirrorMode.auto,
    Key? key,
  }) {
    return VideoTrackRenderer(track);
  }

  ///断开连接
  disconnect() async {
    await room.disconnect();
  }
}

class LiveKitConferenceClientPool {
  final Map<String, LiveKitConferenceClient> clients = {};

  Future<LiveKitConferenceClient> createLiveKitConferenceClient(
      String name) async {
    if (clients.containsKey(name)) {
      return clients[name]!;
    }
    LiveKitConferenceClient client = LiveKitConferenceClient();
    await client.connect();
    clients[name] = client;

    return client;
  }

  LiveKitConferenceClient? getLiveKitConferenceClient(String name) {
    return clients[name];
  }
}

final LiveKitConferenceClientPool liveKitConferenceClientPool =
    LiveKitConferenceClientPool();
