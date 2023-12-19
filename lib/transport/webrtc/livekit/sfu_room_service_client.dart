import 'package:colla_chat/plugin/logger.dart';
import 'package:livekit_server_sdk/livekit_server_sdk.dart';
import 'package:livekit_server_sdk/src/proto/livekit_models.pb.dart';

///创建直连LiveKit服务器的连接客户端，一般不用
class LiveKitRoomServiceClient {
  String host;
  String apiKey;
  String apiSecret;
  late RoomServiceClient roomServiceClient;

  LiveKitRoomServiceClient(this.host, this.apiKey, this.apiSecret) {
    roomServiceClient =
        RoomServiceClient(host: host, apiKey: apiKey, secret: apiSecret);
  }

  /// CreateToken 创建新的token，这个token在客户端连接房间的时候要使用
  List<String> createTokens(
      {required String roomName,
      required List<String> identities,
      List<String>? names,
      Duration? ttl,
      String? metadata}) {
    List<String> tokens = [];
    int i = 0;
    for (String identity in identities) {
      String? name;
      if (names != null) {
        name = names[i];
      }
      String token = createToken(roomName, identity,
          name: name, ttl: ttl, metadata: metadata);
      tokens.add(token);
      i++;
    }

    return tokens;
  }

  String createToken(
    String roomName,
    String identity, {
    String? name,
    Duration? ttl,
    String? metadata,
  }) {
    var ato = AccessTokenOptions(
        ttl: ttl, name: name, identity: identity, metadata: metadata);
    var videoGrant = VideoGrant(room: roomName, roomJoin: true);
    var claimGrants = ClaimGrants(name: name, video: videoGrant);
    var at = AccessToken(apiKey, apiSecret,
        identity: identity, ttl: ttl, options: ato, grants: claimGrants);
    String token = at.toJwt();

    return token;
  }

  Future<List<String>?> createRoom({
    required String roomName,
    Duration? emptyTimeout,
    int? maxParticipants,
    String? nodeId,
    List<String>? identities,
    List<String>? names,
  }) async {
    emptyTimeout ??= const Duration(hours: 12);
    CreateOptions options = CreateOptions(
        name: roomName,
        emptyTimeout: emptyTimeout,
        maxParticipants: maxParticipants,
        nodeId: nodeId);
    try {
      Room room = await roomServiceClient.createRoom(options);
      if (identities != null) {
        List<String> tokens = createTokens(
            roomName: roomName, identities: identities, names: names);

        return tokens;
      }
    } catch (e) {
      logger.e('roomServiceClient createRoom failure:$e');
    }

    return null;
  }

  deleteRoom(String roomName) async {
    await roomServiceClient.deleteRoom(roomName);
  }

  Future<List<Room>> listRooms(List<String>? roomNames) async {
    return await roomServiceClient.listRooms(roomNames);
  }

  Future<ParticipantInfo> getParticipant(
      String roomName, String participant) async {
    return await roomServiceClient.getParticipant(roomName, participant);
  }

  Future<List<ParticipantInfo>> listParticipants(String roomName) async {
    return await roomServiceClient.listParticipants(roomName);
  }

  removeParticipant(String roomName, String participant) async {
    await roomServiceClient.removeParticipant(roomName, participant);
  }

  Future<ParticipantInfo?> updateParticipant(String roomName, String identity,
      String? metadata, ParticipantPermission? permission) async {
    return await roomServiceClient.updateParticipant(
        roomName, identity, metadata, permission);
  }

  Future<TrackInfo?> mutePublishedTrack(
      String roomName, String participant, String trackSid, bool muted) async {
    return roomServiceClient.mutePublishedTrack(
        roomName, participant, trackSid, muted);
  }

  Future<Room?> updateRoomMetadata(String roomName, String metadata) async {
    return await roomServiceClient.updateRoomMetadata(roomName, metadata);
  }

  updateSubscriptions(String roomName, String identity, List<String> trackSids,
      bool subscribe) async {
    await roomServiceClient.updateSubscriptions(
        roomName, identity, trackSids, subscribe);
  }
}
