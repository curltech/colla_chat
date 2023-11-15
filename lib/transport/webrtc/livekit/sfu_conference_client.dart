import 'dart:async';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/pages/chat/chat/controller/conference_chat_message_controller.dart';
import 'package:colla_chat/plugin/logger.dart' as log;
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/local_peer_media_stream_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:synchronized/synchronized.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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
      {this.uri = 'ws://192.168.1.50:7880',
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
    if (e2ee) {
      final keyProvider = await BaseKeyProvider.create();
      e2eeOptions = E2EEOptions(keyProvider: keyProvider);
      await keyProvider.setKey(sharedKey!);
    }

    // Create a Listener before connecting
    _listener = room.createListener();
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
  unpublish(String trackSid, {bool notify = true}) async {
    await room.localParticipant?.unpublishTrack(trackSid, notify: notify);
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
    await roomClient.connect();
    roomClient
        .onRoomEvent<ParticipantConnectedEvent>(onParticipantConnectedEvent);
    roomClient.onRoomEvent<ParticipantDisconnectedEvent>(
        onParticipantDisconnectedEvent);
    roomClient.onRoomEvent<TrackPublishedEvent>(onTrackPublishedEvent);
    roomClient.onRoomEvent<TrackUnpublishedEvent>(onTrackUnpublishedEvent);
    roomClient
        .onRoomEvent<LocalTrackPublishedEvent>(onLocalTrackPublishedEvent);
    roomClient
        .onRoomEvent<LocalTrackUnpublishedEvent>(onLocalTrackUnpublishedEvent);
    roomClient.onLocalParticipantEvent(onLocalParticipantEvent);
    await conferenceChatMessageController.join();
    joined = true;
  }

  Map<String, RemoteParticipant> remoteParticipants() {
    return roomClient.room.participants;
  }

  /// 发布本地视频或者音频，如果参数的流为null，则创建本地主视频并发布
  Future<void> publish({List<PeerMediaStream>? peerMediaStreams}) async {
    if (!joined) {
      return;
    }
    if (peerMediaStreams != null) {
      for (PeerMediaStream peerMediaStream in peerMediaStreams) {
        if (peerMediaStream.videoTrack != null && peerMediaStream.local) {
          await roomClient.publishVideoTrack(
              peerMediaStream.videoTrack! as LocalVideoTrack);
        }
        if (peerMediaStream.audioTrack != null && peerMediaStream.local) {
          await roomClient.publishAudioTrack(
              peerMediaStream.audioTrack! as LocalAudioTrack);
        }
      }
    } else {
      bool? video = conferenceChatMessageController.conference?.video;
      if (video != null && video) {
        try {
          LocalTrackPublication<LocalTrack>? localTrackPublication =
              await setCameraEnabled(true);
          if (localTrackPublication != null) {
            PlatformParticipant platformParticipant = PlatformParticipant(
                myself.peerId!,
                clientId: myself.clientId,
                name: myself.name);
            PeerMediaStream peerMediaStream =
                await PeerMediaStream.createPeerMediaStream(
              videoTrack: localTrackPublication.track! as VideoTrack,
              platformParticipant: platformParticipant,
            );
            localPeerMediaStreamController.mainPeerMediaStream =
                peerMediaStream;
          }
        } catch (error) {
          log.logger.e('could not publish video: $error');
        }
      }
      try {
        LocalTrackPublication<LocalTrack>? localTrackPublication =
            await setMicrophoneEnabled(true);
        if (localTrackPublication != null) {
          PlatformParticipant platformParticipant = PlatformParticipant(
              myself.peerId!,
              clientId: myself.clientId,
              name: myself.name);
          PeerMediaStream peerMediaStream =
              await PeerMediaStream.createPeerMediaStream(
            audioTrack: localTrackPublication.track! as AudioTrack,
            platformParticipant: platformParticipant,
          );
          localPeerMediaStreamController.mainPeerMediaStream = peerMediaStream;
        }
      } catch (error) {
        log.logger.e('could not publish audio: $error');
      }
    }
  }

  /// 退出发布并且关闭本地的某个轨道或者流
  close(List<PeerMediaStream> peerMediaStreams, {bool notify = true}) async {
    if (joined) {
      for (PeerMediaStream peerMediaStream in peerMediaStreams) {
        List<MediaStreamTrack>? tracks =
            peerMediaStream.mediaStream?.getTracks();
        if (tracks == null) {
          return;
        }
        for (MediaStreamTrack track in tracks) {
          String? id = track.id;
          if (id != null) {
            await roomClient.unpublish(id, notify: notify);
          }
        }

        if (peerMediaStream.id != null) {
          await localPeerMediaStreamController.close(peerMediaStream.id!);
        }
      }
    }
  }

  /// 退出发布并且关闭本地的所有的轨道或者流
  closeAll({bool notify = true}) async {
    if (joined) {
      await roomClient.unpublishAll(notify: notify, stopOnUnpublish: true);
    }
    await localPeerMediaStreamController.closeAll();
  }

  /// 远程参与者加入会议
  FutureOr<void> onParticipantConnectedEvent(ParticipantConnectedEvent event) {
    log.logger.i('on ParticipantConnectedEvent');
  }

  /// 远程参与者退出会议
  FutureOr<void> onParticipantDisconnectedEvent(
      ParticipantDisconnectedEvent event) {
    log.logger.i('on ParticipantDisconnectedEvent');
  }

  Future<FutureOr<void>> onTrackPublishedEvent(
      TrackPublishedEvent event) async {
    log.logger.i('on TrackPublishedEvent');
    RemoteTrack? track = event.publication.track;
    RemoteParticipant remoteParticipant = event.participant;
    if (track != null) {
      String streamId = track.mediaStream.id;
      PeerMediaStream? peerMediaStream =
          await remotePeerMediaStreamController.getPeerMediaStream(streamId);
      if (peerMediaStream == null) {
        String identity = remoteParticipant.identity;
        String name = remoteParticipant.name;
        PlatformParticipant platformParticipant =
            PlatformParticipant(identity, name: name);
        if (track is RemoteVideoTrack) {
          peerMediaStream = PeerMediaStream(
              videoTrack: track, platformParticipant: platformParticipant);
        }
        if (track is RemoteAudioTrack) {
          peerMediaStream = PeerMediaStream(
              audioTrack: track, platformParticipant: platformParticipant);
        }
        if (peerMediaStream != null) {
          remotePeerMediaStreamController.add(peerMediaStream);
        }
      }
    }
  }

  Future<FutureOr<void>> onTrackUnpublishedEvent(
      TrackUnpublishedEvent event) async {
    log.logger.i('on TrackUnpublishedEvent');
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
  FutureOr<void> onLocalTrackPublishedEvent(LocalTrackPublishedEvent event) {
    log.logger.i('on LocalTrackPublishedEvent');
    LocalTrackPublication<LocalTrack> localTrackPublication = event.publication;
    LocalTrack? track = localTrackPublication.track;
    if (track != null) {
      RTCRtpMediaType mediaType = track.mediaType;
      if (mediaType == RTCRtpMediaType.RTCRtpMediaTypeVideo) {
        localPeerMediaStreamController
            .add(PeerMediaStream(videoTrack: track as LocalVideoTrack));
      } else if (mediaType == RTCRtpMediaType.RTCRtpMediaTypeAudio) {
        localPeerMediaStreamController
            .add(PeerMediaStream(audioTrack: track as LocalAudioTrack));
      }
    }
  }

  /// 本地退出事件，本地轨道发生变化
  FutureOr<void> onLocalTrackUnpublishedEvent(
      LocalTrackUnpublishedEvent event) {
    log.logger.i('on LocalTrackUnpublishedEvent');
    LocalTrackPublication<LocalTrack> localTrackPublication = event.publication;
    LocalTrack? track = localTrackPublication.track;
    if (track != null) {
      localPeerMediaStreamController.remove(track.mediaStream.id);
    }
  }

  /// 本地参与者事件
  void onLocalParticipantEvent() {
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
          if (token != null) {
            LiveKitRoomClient liveKitRoomClient =
                LiveKitRoomClient(token: token);
            liveKitConferenceClient = LiveKitConferenceClient(
                liveKitRoomClient, conferenceChatMessageController);
            _conferenceClients[conferenceId] = liveKitConferenceClient;
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
      await conferenceClient.close(peerMediaStreams);
    }
  }

  ///根据会议编号退出会议
  ///调用对应会议的退出方法
  closeAll(String conferenceId) async {
    await _clientLock.synchronized(() async {
      LiveKitConferenceClient? conferenceClient =
          _conferenceClients[conferenceId];
      if (conferenceClient != null) {
        await conferenceClient.closeAll();
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
