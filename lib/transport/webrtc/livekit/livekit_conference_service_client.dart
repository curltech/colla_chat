import 'package:livekit_server_sdk/livekit_server_sdk.dart';
import 'package:livekit_server_sdk/src/proto/livekit_models.pb.dart';

///创建LiveKit房间的连接客户端
class LiveKitConferenceServiceClient {
  String host = "https://my.livekit.host";
  RoomServiceClient? roomServiceClient;

  connect({required String host, String? apiKey, String? secret}) {
    roomServiceClient =
        RoomServiceClient(host: host, apiKey: apiKey, secret: secret);
  }

  /// CreateToken 创建新的token，这个token在客户端连接房间的时候要使用
  String createToken(String apiKey, String apiSecret, String roomName,
      String identity, String name, Duration? ttl, String? metadata) {
    var ato = AccessTokenOptions(
        ttl: ttl, name: name, identity: identity, metadata: metadata);
    var videoGrant = VideoGrant(room: roomName, roomJoin: true);
    var claimGrants = ClaimGrants(name: name, video: videoGrant);
    var at = AccessToken(apiKey, apiSecret,
        identity: identity, ttl: ttl, options: ato, grants: claimGrants);

    return at.toJwt();
  }

  Future<Room?> createRoom(
      {required String name,
      Duration? emptyTimeout,
      int? maxParticipants,
      String? nodeId}) async {
    CreateOptions options = CreateOptions(
        name: name,
        emptyTimeout: emptyTimeout,
        maxParticipants: maxParticipants,
        nodeId: nodeId);
    Room? room = await roomServiceClient?.createRoom(options);

    return room;
  }

  deleteRoom(String roomName) async {
    await roomServiceClient?.deleteRoom(roomName);
  }

  Future<List<Room>?> listRooms(List<String>? roomNames) async {
    return await roomServiceClient?.listRooms(roomNames);
  }

  Future<ParticipantInfo?> getParticipant(
      String roomName, String participant) async {
    return await roomServiceClient?.getParticipant(roomName, participant);
  }

  Future<List<ParticipantInfo>?> listParticipants(String roomName) async {
    return await roomServiceClient?.listParticipants(roomName);
  }

  removeParticipant(String roomName, String participant) async {
    await roomServiceClient?.removeParticipant(roomName, participant);
  }

  Future<ParticipantInfo?> updateParticipant(String roomName, String identity,
      String? metadata, ParticipantPermission? permission) async {
    return await roomServiceClient?.updateParticipant(
        roomName, identity, metadata, permission);
  }

  Future<TrackInfo?> mutePublishedTrack(
      String roomName, String participant, String trackSid, bool muted) async {
    return roomServiceClient?.mutePublishedTrack(
        roomName, participant, trackSid, muted);
  }

  Future<Room?> updateRoomMetadata(String roomName, String metadata) async {
    return await roomServiceClient?.updateRoomMetadata(roomName, metadata);
  }

  updateSubscriptions(String roomName, String identity, List<String> trackSids,
      bool subscribe) async {
    await roomServiceClient?.updateSubscriptions(
        roomName, identity, trackSids, subscribe);
  }
}
