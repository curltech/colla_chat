import 'dart:async';
import 'dart:collection';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/pages/chat/chat/controller/conference_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/index/global_chat_message.dart';
import 'package:colla_chat/plugin/logger.dart' as log;
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/local_peer_media_stream_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:colla_chat/widgets/media/audio/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:synchronized/synchronized.dart';

/// LiveKit的房间连接客户端,ws协议
class LiveKitRoomClient {
  final String uri;
  final String token;
  final String? sharedKey;
  final bool adaptiveStream;
  final bool dynacast;
  final bool simulcast;
  final bool fastConnect;
  final bool e2ee;
  final Room room = Room();
  EventsListener<RoomEvent>? _listener;

  LiveKitRoomClient(
      {required this.uri,
      required this.token,
      this.sharedKey,
      this.adaptiveStream = true,
      this.dynacast = false,
      this.simulcast = true,
      this.fastConnect = false,
      this.e2ee = false});

  /// 连接服务器，根据token建立房间的连接
  Future<void> connect() async {
    E2EEOptions? e2eeOptions;
    if (e2ee && sharedKey != null) {
      final keyProvider = await BaseKeyProvider.create();
      e2eeOptions = E2EEOptions(keyProvider: keyProvider);
      await keyProvider.setKey(sharedKey!);
    }

    // Create a Listener before connecting
    _listener = room.createListener();
    await room.connect(
      uri,
      token,
      connectOptions: const ConnectOptions(),
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
  /// ParticipantEvent,LocalTrackPublishedEvent,LocalTrackUnpublishedEvent三个事件很重要
  CancelListenFunc? onRoomEvent<E>(
    FutureOr<void> Function(E) then, {
    bool Function(E)? filter,
  }) {
    return _listener?.on<E>(then, filter: filter);
  }

  /// 本地参与者的监听器
  onLocalParticipantEvent(void Function() listener) {
    room.localParticipant?.addListener(listener);
  }

  /// 订阅远程参与者的轨道
  subscribe(List<String> participants) async {
    for (String participantId in participants) {
      Map<String, RemoteParticipant> remoteParticipants =
          room.remoteParticipants;
      if (remoteParticipants.containsKey(participantId)) {
        RemoteParticipant participant = remoteParticipants[participantId]!;
        for (RemoteTrackPublication publication
            in participant.trackPublications.values) {
          await publication.subscribe();
        }
      }
    }
  }

  /// 解除订阅远程参与者的轨道
  unsubscribe(List<String> participants) async {
    for (String participantId in participants) {
      Map<String, RemoteParticipant> remoteParticipants =
          room.remoteParticipants;
      if (remoteParticipants.containsKey(participantId)) {
        RemoteParticipant participant = remoteParticipants[participantId]!;
        for (RemoteTrackPublication publication
            in participant.trackPublications.values) {
          await publication.unsubscribe();
        }
      }
    }
  }

  /// 激活参与者的轨道
  enable(List<String> participants) async {
    for (String participantId in participants) {
      Map<String, RemoteParticipant> remoteParticipants =
          room.remoteParticipants;
      if (remoteParticipants.containsKey(participantId)) {
        RemoteParticipant participant = remoteParticipants[participantId]!;
        for (RemoteTrackPublication publication
            in participant.trackPublications.values) {
          await publication.enable();
        }
      }
    }
  }

  /// 关闭参与者的轨道
  disable(List<String> participants) async {
    for (String participantId in participants) {
      Map<String, RemoteParticipant> remoteParticipants =
          room.remoteParticipants;
      if (remoteParticipants.containsKey(participantId)) {
        RemoteParticipant participant = remoteParticipants[participantId]!;
        for (RemoteTrackPublication publication
            in participant.trackPublications.values) {
          await publication.disable();
        }
      }
    }
  }

  /// 设置参与者的轨道的fps
  setVideoFPS(List<String> participants, int fps) async {
    for (String participantId in participants) {
      Map<String, RemoteParticipant> remoteParticipants =
          room.remoteParticipants;
      if (remoteParticipants.containsKey(participantId)) {
        RemoteParticipant participant = remoteParticipants[participantId]!;
        for (RemoteTrackPublication publication
            in participant.trackPublications.values) {
          await publication.setVideoFPS(fps);
        }
      }
    }
  }

  /// 设置参与者的轨道的质量
  setVideoQuality(List<String> participants, VideoQuality videoQuality) async {
    for (String participantId in participants) {
      Map<String, RemoteParticipant> remoteParticipants =
          room.remoteParticipants;
      if (remoteParticipants.containsKey(participantId)) {
        RemoteParticipant participant = remoteParticipants[participantId]!;
        for (RemoteTrackPublication publication
            in participant.trackPublications.values) {
          await publication.setVideoQuality(videoQuality);
        }
      }
    }
  }

  /// 对远程参与者排序，排序的次序为：音量，最后说话的时间，是否视频，加入时间
  List<RemoteParticipant> sort() {
    Map<String, RemoteParticipant> remoteParticipants = room.remoteParticipants;
    List<RemoteParticipant> participants = remoteParticipants.values.toList();
    participants.sort((a, b) {
      if (a.isSpeaking && b.isSpeaking) {
        if (a.audioLevel > b.audioLevel) {
          return -1;
        } else {
          return 1;
        }
      }

      // last spoken at
      final aSpokeAt = a.lastSpokeAt?.millisecondsSinceEpoch ?? 0;
      final bSpokeAt = b.lastSpokeAt?.millisecondsSinceEpoch ?? 0;

      if (aSpokeAt != bSpokeAt) {
        return aSpokeAt > bSpokeAt ? -1 : 1;
      }

      // video on
      if (a.hasVideo != b.hasVideo) {
        return a.hasVideo ? -1 : 1;
      }

      // joinedAt
      return a.joinedAt.millisecondsSinceEpoch -
          b.joinedAt.millisecondsSinceEpoch;
    });

    return participants;
  }

  ///发送数据
  Future<void> publishData(
    List<int> data, {
    bool? reliable,
    List<String>? destinationIdentities,
    String? topic,
  }) async {
    await room.localParticipant?.publishData(data,
        reliable: reliable,
        destinationIdentities: destinationIdentities,
        topic: topic);
  }

  ///激活远程轨道
  Future<void> enableTrack(RemoteTrackPublication publication) async {
    await publication.enable();
  }

  ///禁止远程轨道
  Future<void> disableTrack(RemoteTrackPublication publication) async {
    await publication.disable();
  }

  /// 创建并且发布本地视频的快捷方法，必须room已经连接上
  Future<LocalTrackPublication<LocalTrack>?> setCameraEnabled(bool enabled,
      {CameraCaptureOptions? cameraCaptureOptions}) async {
    return await room.localParticipant
        ?.setCameraEnabled(enabled, cameraCaptureOptions: cameraCaptureOptions);
  }

  /// 发布本地视频
  Future<LocalTrackPublication<LocalVideoTrack>?> publishVideoTrack(
      LocalVideoTrack localVideo,
      {VideoPublishOptions? publishOptions}) async {
    try {
      return await room.localParticipant?.publishVideoTrack(localVideo);
    } catch (e) {
      log.logger.e('could not publish video: $e');
    }
    return null;
  }

  /// 创建并且发布本地音频的快捷方法
  Future<LocalTrackPublication<LocalTrack>?> setMicrophoneEnabled(bool enabled,
      {AudioCaptureOptions? audioCaptureOptions}) async {
    return await room.localParticipant?.setMicrophoneEnabled(enabled,
        audioCaptureOptions: audioCaptureOptions);
  }

  /// 发布本地音频
  Future<LocalTrackPublication<LocalAudioTrack>?> publishAudioTrack(
      LocalAudioTrack localAudio,
      {AudioPublishOptions? publishOptions}) async {
    try {
      return await room.localParticipant
          ?.publishAudioTrack(localAudio, publishOptions: publishOptions);
    } catch (e) {
      logger.warning('could not publish audio: $e');
    }
    return null;
  }

  /// 创建并且发布屏幕共享的快捷方法，screenShareCaptureOptions包含源界面的编号
  Future<LocalTrackPublication<LocalTrack>?> setScreenShareEnabled(
    bool enabled, {
    bool? captureScreenAudio,
    ScreenShareCaptureOptions? screenShareCaptureOptions,
  }) async {
    return await room.localParticipant?.setScreenShareEnabled(enabled,
        captureScreenAudio: captureScreenAudio,
        screenShareCaptureOptions: screenShareCaptureOptions);
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

  /// 关闭本地的某个轨道或者流
  removePublishedTrack(String trackSid, {bool notify = true}) async {
    await room.localParticipant?.removePublishedTrack(trackSid, notify: notify);
  }

  /// 关闭本地的所有的轨道或者流
  unpublishAll({bool notify = true, bool? stopOnUnpublish}) async {
    await room.localParticipant
        ?.unpublishAllTracks(notify: notify, stopOnUnpublish: stopOnUnpublish);
  }

  /// 断开连接，退出会议
  disconnect() async {
    await room.disconnect();
  }

  Future<void> setCameraPosition(CameraPosition position) async {
    LocalTrackPublication<LocalVideoTrack>? videoTrackPublication =
        room.localParticipant?.videoTrackPublications.firstOrNull;
    if (videoTrackPublication != null) {
      var videoTrack = videoTrackPublication.track;
      try {
        await videoTrack?.setCameraPosition(position);
      } catch (error) {
        log.logger.e('switchCamera error: $error');
      }
    }
  }

  Future<void> setSpeakerphoneOn(bool enable) async {
    await Hardware.instance.setPreferSpeakerOutput(false);
    await Hardware.instance.setSpeakerphoneOn(enable);
  }
}

/// 会议客户端，包含有房间客户端和会议的消息控制器
class LiveKitConferenceClient {
  final LiveKitRoomClient roomClient;
  final PeerMediaStreamController remotePeerMediaStreamController =
      PeerMediaStreamController();
  final ConferenceChatMessageController conferenceChatMessageController;
  bool joined = false;

  LiveKitConferenceClient(
      this.roomClient, this.conferenceChatMessageController);

  // ParticipantConnected	A RemoteParticipant joins after the local participant.	x
  // ParticipantDisconnected	A RemoteParticipant leaves	x
  // Reconnecting	The connection to the server has been interrupted and it's attempting to reconnect.	x
  // Reconnected	Reconnection has been successful	x
  // Disconnected	Disconnected from room due to the room closing or unrecoverable failure	x
  // TrackPublished	A new track is published to room after the local participant has joined	x	x
  // TrackUnpublished	A RemoteParticipant has unpublished a track	x	x
  /// 初始化会议，先连接，然后注册事件
  join() async {
    Conference? conference = conferenceChatMessageController.conference;
    if (conference == null) {
      return;
    }
    bool isValid = conferenceService.isValid(conference);
    if (!isValid) {
      log.logger.e('conference ${conference.name} is invalid');
      return;
    }
    await roomClient.connect();
    roomClient
        .onRoomEvent<ParticipantConnectedEvent>(_onParticipantConnectedEvent);
    roomClient.onRoomEvent<ParticipantDisconnectedEvent>(
        _onParticipantDisconnectedEvent);
    roomClient.onRoomEvent<TrackPublishedEvent>(_onTrackPublishedEvent);
    roomClient.onRoomEvent<TrackUnpublishedEvent>(_onTrackUnpublishedEvent);
    roomClient.onRoomEvent<TrackSubscribedEvent>(_onTrackSubscribedEvent);
    roomClient.onRoomEvent<TrackUnsubscribedEvent>(_onTrackUnsubscribedEvent);
    roomClient
        .onRoomEvent<LocalTrackPublishedEvent>(_onLocalTrackPublishedEvent);
    roomClient
        .onRoomEvent<LocalTrackUnpublishedEvent>(_onLocalTrackUnpublishedEvent);
    roomClient.onLocalParticipantEvent(_onLocalParticipantEvent);
    roomClient.onRoomEvent<DataReceivedEvent>(_onDataReceivedEvent);
    roomClient
        .onRoomEvent<AudioPlaybackStatusChanged>(_onAudioPlaybackStatusChanged);
    joined = true;
    log.logger.w('i joined conference ${conference.name}');
    await publish(
        peerMediaStreams: localPeerMediaStreamController.peerMediaStreams);
    liveKitConferenceClientPool.join(conference.conferenceId);
    await globalAudioSession.initSpeech();
  }

  LocalParticipant? get localParticipant {
    return roomClient.room.localParticipant;
  }

  List<RemoteParticipant> get remoteParticipants {
    return roomClient.sort();
  }

  /// 发布本地视频或者音频，如果参数的流为null，则创建本地主视频并发布
  Future<void> publish({List<PeerMediaStream>? peerMediaStreams}) async {
    if (!joined) {
      return;
    }
    if (peerMediaStreams != null && peerMediaStreams.isNotEmpty) {
      for (PeerMediaStream peerMediaStream in peerMediaStreams) {
        if (peerMediaStream.videoTrack != null && peerMediaStream.local) {
          await roomClient.publishVideoTrack(
              peerMediaStream.videoTrack! as LocalVideoTrack);
        }
        if (peerMediaStream.audioTrack != null && peerMediaStream.local) {
          await roomClient.publishAudioTrack(
              peerMediaStream.audioTrack! as LocalAudioTrack);
        }
        peerMediaStream.participant = roomClient.room.localParticipant;
      }
    } else {
      LocalTrackPublication<LocalTrack>? localVideoTrackPublication;
      bool? video = conferenceChatMessageController.conference?.video;
      LocalTrackPublication<LocalTrack>? localAudioTrackPublication;
      if (video != null && video) {
        try {
          localVideoTrackPublication = await setCameraEnabled(true);
        } catch (error) {
          log.logger.e('could not publish video: $error');
        }
      }
      try {
        localAudioTrackPublication = await setMicrophoneEnabled(true);
      } catch (error) {
        log.logger.e('could not publish audio: $error');
      }
      PlatformParticipant platformParticipant = PlatformParticipant(
          myself.peerId!,
          clientId: myself.clientId,
          name: myself.name);
      PeerMediaStream peerMediaStream =
          await PeerMediaStream.createPeerMediaStream(
        videoTrack: localVideoTrackPublication != null
            ? localVideoTrackPublication.track as VideoTrack
            : null,
        audioTrack: localAudioTrackPublication != null
            ? localAudioTrackPublication.track as AudioTrack
            : null,
        platformParticipant: platformParticipant,
      );
      peerMediaStream.participant = roomClient.room.localParticipant;
      localPeerMediaStreamController.mainPeerMediaStream = peerMediaStream;
      localPeerMediaStreamController.add(peerMediaStream);
    }
  }

  /// 退出发布并且关闭本地的某个轨道或者流
  closeLocal(List<PeerMediaStream> peerMediaStreams, {bool notify = true}) async {
    if (joined) {
      for (PeerMediaStream peerMediaStream in peerMediaStreams) {
        String? trackId = peerMediaStream.videoTrack?.sid;
        if (trackId != null) {
          await roomClient.removePublishedTrack(trackId, notify: notify);
        }
        trackId = peerMediaStream.audioTrack?.sid;
        if (trackId != null) {
          await roomClient.removePublishedTrack(trackId, notify: notify);
        }

        if (peerMediaStream.id != null) {
          await localPeerMediaStreamController.close(peerMediaStream.id!);
        }
      }
    }
  }

  /// 退出发布并且关闭本地的所有的轨道或者流
  closeAllLocal({bool notify = true}) async {
    if (joined) {
      await roomClient.unpublishAll(notify: notify, stopOnUnpublish: true);
    }
    await localPeerMediaStreamController.closeAll();
  }

  /// 远程参与者加入会议
  FutureOr<void> _onParticipantConnectedEvent(ParticipantConnectedEvent event) {
    log.logger.i(
        'on ParticipantConnectedEvent:${event.participant.identity}:${event.participant.name}');
  }

  /// 远程参与者退出会议
  FutureOr<void> _onParticipantDisconnectedEvent(
      ParticipantDisconnectedEvent event) {
    log.logger.i(
        'on ParticipantDisconnectedEvent:${event.participant.identity}:${event.participant.name}');
  }

  Future<FutureOr<void>> _onTrackPublishedEvent(
      TrackPublishedEvent event) async {
    log.logger.i(
        'on TrackPublishedEvent:${event.participant.identity}:${event.participant.name}');
  }

  /// 获取所有的远程参与者的所有流
  Future<List<PeerMediaStream>> get remotePeerMediaStreams async {
    /// 遍历所有的参与者的所有流
    Map<String, PeerMediaStream> peerMediaStreams = {};
    for (RemoteParticipant remoteParticipant in remoteParticipants) {
      for (RemoteTrackPublication<RemoteAudioTrack> audioTrack
          in remoteParticipant.audioTrackPublications) {
        RemoteTrack? remoteTrack = audioTrack.track;
        if (remoteTrack == null) {
          continue;
        }
        String streamId = remoteTrack.mediaStream.id;
        PeerMediaStream? peerMediaStream =
            await remotePeerMediaStreamController.getPeerMediaStream(streamId);
        if (peerMediaStream == null) {
          peerMediaStream =
              _buildRemotePeerMediaStream(remoteTrack, remoteParticipant);
          if (peerMediaStream != null) {
            remotePeerMediaStreamController.add(peerMediaStream);
          }
        }
        if (peerMediaStream != null) {
          peerMediaStreams[streamId] = peerMediaStream;
        }
      }
      for (RemoteTrackPublication<RemoteVideoTrack> videoTrack
          in remoteParticipant.videoTrackPublications) {
        RemoteTrack? remoteTrack = videoTrack.track;
        if (remoteTrack == null) {
          continue;
        }
        String streamId = remoteTrack.mediaStream.id;
        PeerMediaStream? peerMediaStream =
            await remotePeerMediaStreamController.getPeerMediaStream(streamId);
        if (peerMediaStream == null) {
          peerMediaStream =
              _buildRemotePeerMediaStream(remoteTrack, remoteParticipant);
          if (peerMediaStream != null) {
            remotePeerMediaStreamController.add(peerMediaStream);
          }
        }
        if (peerMediaStream != null) {
          peerMediaStreams[streamId] = peerMediaStream;
        }
      }
    }

    ///  关闭不在远程参与者中的流，这些流没有及时被关闭
    for (PeerMediaStream peerMediaStream
        in remotePeerMediaStreamController.peerMediaStreams) {
      String streamId = peerMediaStream.id!;
      if (!peerMediaStreams.containsKey(streamId)) {
        remotePeerMediaStreamController.close(streamId);
      }
    }

    return [...peerMediaStreams.values];
  }

  PeerMediaStream? _buildRemotePeerMediaStream(
      RemoteTrack track, RemoteParticipant remoteParticipant) {
    String identity = remoteParticipant.identity;
    String name = remoteParticipant.name;
    PlatformParticipant platformParticipant =
        PlatformParticipant(identity, name: name);
    PeerMediaStream? peerMediaStream;
    if (track is RemoteVideoTrack) {
      peerMediaStream = PeerMediaStream(
          videoTrack: track,
          platformParticipant: platformParticipant,
          participant: remoteParticipant);
    }
    if (track is RemoteAudioTrack) {
      peerMediaStream = PeerMediaStream(
          audioTrack: track,
          platformParticipant: platformParticipant,
          participant: remoteParticipant);
    }
    return peerMediaStream;
  }

  Future<FutureOr<void>> _onTrackSubscribedEvent(
      TrackSubscribedEvent event) async {
    log.logger.i(
        'on TrackSubscribedEvent:${event.participant.identity}:${event.participant.name}');
    RemoteTrack? track = event.publication.track;
    if (track != null) {
      RemoteParticipant remoteParticipant = event.participant;
      String streamId = track.mediaStream.id;
      PeerMediaStream? peerMediaStream =
          await remotePeerMediaStreamController.getPeerMediaStream(streamId);
      if (peerMediaStream == null) {
        peerMediaStream = _buildRemotePeerMediaStream(track, remoteParticipant);
        if (peerMediaStream != null) {
          remotePeerMediaStreamController.add(peerMediaStream);
          log.logger.i(
              'remotePeerMediaStreamController add peerMediaStream:${peerMediaStream.id}');
        }
      }
    } else {
      log.logger.e('on TrackSubscribedEvent track is null');
    }
  }

  Future<FutureOr<void>> _onTrackUnpublishedEvent(
      TrackUnpublishedEvent event) async {
    log.logger.i(
        'on TrackUnpublishedEvent:${event.participant.identity}:${event.participant.name}');
    RemoteTrack? track = event.publication.track;
    if (track != null) {
      String streamId = track.mediaStream.id;
      PeerMediaStream? peerMediaStream =
          await remotePeerMediaStreamController.getPeerMediaStream(streamId);
      if (peerMediaStream != null) {
        remotePeerMediaStreamController.close(streamId);
      }
    }
  }

  Future<FutureOr<void>> _onTrackUnsubscribedEvent(
      TrackUnsubscribedEvent event) async {
    log.logger.i(
        'on TrackUnsubscribedEvent:${event.participant.identity}:${event.participant.name}');
    RemoteTrack? track = event.publication.track;
    if (track != null) {
      String streamId = track.mediaStream.id;
      PeerMediaStream? peerMediaStream =
          await remotePeerMediaStreamController.getPeerMediaStream(streamId);
      if (peerMediaStream != null) {
        remotePeerMediaStreamController.close(streamId);
      }
    }
  }

  /// 本地发布事件，本地轨道发生变化
  FutureOr<void> _onLocalTrackPublishedEvent(LocalTrackPublishedEvent event) {
    log.logger.i(
        'on LocalTrackPublishedEvent:${event.participant.identity}:${event.participant.name}');
  }

  /// 本地退出事件，本地轨道发生变化
  FutureOr<void> _onLocalTrackUnpublishedEvent(
      LocalTrackUnpublishedEvent event) {
    log.logger.i(
        'on LocalTrackUnpublishedEvent:${event.participant.identity}:${event.participant.name}');
  }

  /// 本地参与者事件
  void _onLocalParticipantEvent() {
    log.logger.i('on LocalParticipantEvent');
  }

  /// 创建并且发布本地视频的快捷方法，必须room已经连接上
  Future<LocalTrackPublication<LocalTrack>?> setCameraEnabled(bool enabled,
      {CameraCaptureOptions? cameraCaptureOptions}) async {
    return await roomClient.setCameraEnabled(enabled,
        cameraCaptureOptions: cameraCaptureOptions);
  }

  /// 创建并且发布本地音频的快捷方法
  Future<LocalTrackPublication<LocalTrack>?> setMicrophoneEnabled(bool enabled,
      {AudioCaptureOptions? audioCaptureOptions}) async {
    return await roomClient.setMicrophoneEnabled(enabled,
        audioCaptureOptions: audioCaptureOptions);
  }

  /// 创建并且发布屏幕共享的快捷方法，screenShareCaptureOptions包含源界面的编号
  Future<LocalTrackPublication<LocalTrack>?> setScreenShareEnabled(
    bool enabled, {
    bool? captureScreenAudio,
    ScreenShareCaptureOptions? screenShareCaptureOptions,
  }) async {
    return await roomClient.setScreenShareEnabled(enabled,
        captureScreenAudio: captureScreenAudio,
        screenShareCaptureOptions: screenShareCaptureOptions);
  }

  /// 断开连接，退出会议
  _disconnect() async {
    if (joined) {
      await roomClient.disconnect();
    }
    await localPeerMediaStreamController.closeAll();
    joined = false;
  }

  FutureOr<void> _onDataReceivedEvent(DataReceivedEvent event) {
    log.logger.i(
        'on DataReceivedEvent:${event.participant?.identity}:${event.participant?.name}');
    List<int> data = event.data;
    globalChatMessage.onData(data, TransportType.sfu);
  }

  FutureOr<void> _onAudioPlaybackStatusChanged(
      AudioPlaybackStatusChanged event) {
    log.logger.i('on AudioPlaybackStatusChanged isPlaying:${event.isPlaying}');
    // roomClient.room.startAudio();
  }

  publishData(List<int> data) async {
    await roomClient.publishData(data);
  }
}

///所有的正在视频会议的池，包含多个视频会议，每个会议的会议号是视频通话邀请的消息号
class LiveKitConferenceClientPool with ChangeNotifier {
  final Map<String, LiveKitConferenceClient> _conferenceClients = {};

  final Lock _clientLock = Lock();

  //当前会议编号
  String? _conferenceId;

  LiveKitConferenceClientPool();

  List<LiveKitConferenceClient> get conferenceClients {
    return [..._conferenceClients.values];
  }

  ///根据当前的视频邀请消息，查找或者创建当前消息对应的会议，并设置为当前会议
  ///在发起者接收到至少一个同意回执，开始重新协商，或者接收者发送出同意回执的时候调用
  Future<LiveKitConferenceClient?> createConferenceClient(
      ChatMessage chatMessage,
      {ChatSummary? chatSummary}) async {
    return await _clientLock.synchronized(() async {
      LiveKitConferenceClient? liveKitConferenceClient;
      //创建基于当前聊天的视频消息控制器
      if (chatMessage.subMessageType == ChatMessageSubType.videoChat.name) {
        String conferenceId = chatMessage.messageId!;
        liveKitConferenceClient = _conferenceClients[conferenceId];
        if (liveKitConferenceClient == null) {
          ConferenceChatMessageController conferenceChatMessageController =
              ConferenceChatMessageController();
          await conferenceChatMessageController.setChatMessage(chatMessage,
              chatSummary: chatSummary);
          String? token = conferenceChatMessageController.conference?.sfuToken;
          String? uri = conferenceChatMessageController.conference?.sfuUri;
          String? password =
              conferenceChatMessageController.conference?.password;
          if (uri != null && token != null) {
            if (!uri.startsWith('ws://')) {
              uri = 'ws://$uri';
            }
            LiveKitRoomClient liveKitRoomClient = LiveKitRoomClient(
                uri: uri, token: token, sharedKey: password, e2ee: false);
            liveKitConferenceClient = LiveKitConferenceClient(
                liveKitRoomClient, conferenceChatMessageController);
            _conferenceClients[conferenceId] = liveKitConferenceClient;
          } else {
            log.logger.e('createConferenceClient sfu uri or token is null');
          }
        } else {
          ConferenceChatMessageController conferenceChatMessageController =
              liveKitConferenceClient.conferenceChatMessageController;
          if (conferenceChatMessageController.chatMessage == null) {
            await conferenceChatMessageController.setChatMessage(chatMessage,
                chatSummary: chatSummary);
          }
        }
        this.conferenceId = conferenceId;
        return liveKitConferenceClient;
      }

      return liveKitConferenceClient;
    });
  }

  ///获取当前会议号
  String? get conferenceId {
    return _conferenceId;
  }

  ///设置当前会议号
  set conferenceId(String? conferenceId) {
    if (_conferenceId != conferenceId) {
      if (conferenceId != null) {
        if (_conferenceClients.containsKey(conferenceId)) {
          _conferenceId = conferenceId;
        } else {
          _conferenceId = null;
        }
      } else {
        _conferenceId = conferenceId;
      }
      notifyListeners();
    }
  }

  join(String conferenceId) {
    if (_conferenceId == conferenceId) {
      notifyListeners();
    }
  }

  ///获取当前的会议
  LiveKitConferenceClient? get conferenceClient {
    if (_conferenceId != null) {
      return _conferenceClients[_conferenceId];
    }
    return null;
  }

  ///获取当前会议控制器
  ConferenceChatMessageController? get conferenceChatMessageController {
    if (_conferenceId != null) {
      return _conferenceClients[_conferenceId]?.conferenceChatMessageController;
    }
    return null;
  }

  ///根据会议号返回会议控制器，没有则返回null
  LiveKitConferenceClient? getConferenceClient(String conferenceId) {
    return _conferenceClients[conferenceId];
  }

  ConferenceChatMessageController? getConferenceChatMessageController(
      String conferenceId) {
    return getConferenceClient(conferenceId)?.conferenceChatMessageController;
  }

  Conference? getConference(String conferenceId) {
    return getConferenceClient(conferenceId)
        ?.conferenceChatMessageController
        .conference;
  }

  ///把本地新的peerMediaStream加入到会议的所有连接中，并且都重新协商
  publish(String conferenceId, List<PeerMediaStream> peerMediaStreams,
      {AdvancedPeerConnection? peerConnection}) async {
    LiveKitConferenceClient? conferenceClient =
        _conferenceClients[conferenceId];
    if (conferenceClient != null) {
      conferenceClient.publish(peerMediaStreams: peerMediaStreams);
    }
  }

  ///会议的指定连接或者所有连接中移除本地或者远程的peerMediaStream，并且都重新协商
  close(String conferenceId, List<PeerMediaStream> peerMediaStreams) async {
    LiveKitConferenceClient? conferenceClient =
        _conferenceClients[conferenceId];
    if (conferenceClient != null) {
      await conferenceClient.closeLocal(peerMediaStreams);
    }
  }

  ///根据会议编号退出会议
  ///调用对应会议的退出方法
  closeAll(String conferenceId) async {
    await _clientLock.synchronized(() async {
      LiveKitConferenceClient? conferenceClient =
          _conferenceClients[conferenceId];
      if (conferenceClient != null) {
        await conferenceClient.closeAllLocal();
        notifyListeners();
      }
    });
  }

  ///根据会议编号终止会议
  ///调用对应会议的终止方法，然后从会议池中删除，设置当前会议编号为null
  disconnect({String? conferenceId}) async {
    await _clientLock.synchronized(() async {
      conferenceId ??= _conferenceId;
      LiveKitConferenceClient? liveKitConferenceClient =
          _conferenceClients[conferenceId];
      if (liveKitConferenceClient != null) {
        await liveKitConferenceClient._disconnect();
        _conferenceClients.remove(conferenceId);
        if (conferenceId == _conferenceId) {
          _conferenceId = null;
        }
        notifyListeners();
      }
    });
  }
}

///存放已经开始的会议，就是发起者接收到至少一个同意回执，开始重新协商，或者接收者发送出同意回执
final LiveKitConferenceClientPool liveKitConferenceClientPool =
    LiveKitConferenceClientPool();
