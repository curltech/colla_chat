import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/service/chat/conference.dart';

enum ManageType { get, create, delete, list, listParticipants }

/// ManageRoom
class ManageRoomAction extends BaseAction {
  ManageRoomAction(MsgType msgType) : super(msgType);

  Future<bool> manageRoom(ManageType manageType,
      {String? roomName,
      int emptyTimeout = 12 * 3600,
      List<String>? identities,
      List<String>? names}) async {
    ChainMessage? chainMessage = await prepareSend({
      'roomName': roomName,
      'manageType': manageType.name,
      'emptyTimeout': emptyTimeout,
      'identities': identities,
      'names': names
    });

    return await send(chainMessage);
  }

  @override
  Future<void> transferPayload(ChainMessage chainMessage) async {
    super.transferPayload(chainMessage);
    if (chainMessage.payloadType == PayloadType.map.name) {
      LiveKitManageRoom liveKitManageRoom =
          LiveKitManageRoom.fromJson(chainMessage.payload);
      chainMessage.payload = liveKitManageRoom;
    }
  }
}

final manageRoomAction = ManageRoomAction(MsgType.MANAGEROOM);
