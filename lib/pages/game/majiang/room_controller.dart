import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:get/get.dart';

class RoomController {
  final Rx<Room?> room = Rx<Room?>(null);

  /// 自己是哪个方位的参与者，因为系统支持以哪个方位的参与者游戏
  /// 所以在玩的过程中可以切换方位，即可以模拟或者代替其他的参与者玩
  /// 比如，当前登录用户是东，除了可以打东的牌以外，通过切换方位也可以打南的牌
  final Rx<ParticipantDirection?> currentDirection =
      Rx<ParticipantDirection?>(null);
}

final RoomController roomController = RoomController();
