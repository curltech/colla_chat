import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/service/chat/conference.dart';

enum ManageType { get, create, delete, list, listParticipants }

/// ManageRoom
class ManageRoomAction extends BaseAction {
  ManageRoomAction(MsgType msgType) : super(msgType);

  Future<bool> manageRoom(ManageType manageType,
      {LiveKitManageRoom? liveKitManageRoom}) async {
    liveKitManageRoom ??= LiveKitManageRoom();
    liveKitManageRoom.manageType = manageType.name;
    ChainMessage? chainMessage = await prepareSend(liveKitManageRoom);

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
