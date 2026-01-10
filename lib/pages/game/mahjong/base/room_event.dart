import 'dart:ui';

import 'package:colla_chat/pages/game/mahjong/base/tile.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

/// 参与者的方位，房间创建时候固定的方位，用于获取牌的数据
/// east表示参与者数组的index为0，以此类推
enum ParticipantDirection { east, south, west, north }

/// 显示的角度，用于牌的显示方式
/// self表示自己，隐藏手牌会显示在屏幕上
/// 其他的代表next下家，opponent对家和previous上家，隐藏手牌手牌不会显示在屏幕上，只有碰杠牌财显示
enum AreaDirection { self, next, opponent, previous }

enum RoomEventAction {
  room, //新房间
  round, //新局
  deal, //发牌
  barDeal, //杠上发牌
  discard, //打牌
  outstanding,
  checkOutstanding,
  touch, //碰牌
  bar, //杠牌：包括sendBar和takeBar
  discardBar, //打牌杠牌
  drawBar, //摸牌杠牌和手牌杠牌
  darkBar, //暗杠
  chow, //吃
  check, //检查
  robotCheck,
  checkWin, //检查胡牌
  win, //胡
  rob, //抢杠胡牌
  seaWin, //海底捞胡
  pass, //过牌
  score, //计分
}

/// 房间事件，一个房间事件由系统或者某个参与者触发，通知其他参与者，会触发一些检查动作或者其他的事件
/// 比如参与者打牌事件将发送到房间，然后房间分发到所有的参与者
/// 事件处理原则：参与者的事件也是先发送到房间，再分发到所有参与者，然后自己再进行处理，原因是考虑到网络环境
class RoomEvent {
  late final String id;

  /// 房间的名称
  final String name;

  final int? roundId;

  /// 事件的拥有者，-1表示房间或者系统，0，1，2，3表示参与者的位置
  /// 比如0打出的牌
  final int owner;

  /// 事件消息的发送者，0，1，2，3表示参与者的位置
  /// sender和receiver必有一个为creator
  int? sender;

  /// 最简单的例子是加入creator为0，owner为1，1打牌，1发送消息给creator，creator接收处理后转发给2和3
  int? receiver;

  /// RoomAction事件的枚举
  late RoomEventAction action;

  late Tile? tile;

  /// 行为发生的来源参与者，比如0胡了1打出的牌
  int? src;

  /// 事件指定的牌的位置
  late int? pos;

  /// 每个事件的内容不同，
  /// 新房间事件是一个参与者数组
  /// 新局事件是庄家的位置和一个随机数的数组，代表发牌
  /// 其他的事件都是参与者的事件，表示牌
  final dynamic content;

  RoomEvent(this.name,
      {String? id,
      this.roundId,
      required this.owner,
      this.sender,
      this.receiver,
      required this.action,
      this.tile,
      this.pos,
      this.content,
      this.src}) {
    if (id == null) {
      this.id = StringUtil.uuid();
    } else {
      this.id = id;
    }
  }

  RoomEvent.fromJson(Map json)
      : id = json['id'],
        name = json['name'],
        roundId = json['roundId'],
        owner = json['owner'],
        sender = json['sender'],
        receiver = json['receiver'],
        pos = json['pos'],
        content = json['content'],
        src = json['src'] {
    if (json['tile'] != null) {
      tile = Tile.fromJson(json['tile']);
    } else {
      tile = null;
    }
    RoomEventAction? action;
    if (json['action'] != null) {
      action =
          StringUtil.enumFromString(RoomEventAction.values, json['action']);
    }
    if (action == null) {
      throw 'action has no right RoomEventAction';
    }
    this.action = action;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'roundId': roundId,
      'owner': owner,
      'sender': sender,
      'receiver': receiver,
      'action': action.name,
      'tile': JsonUtil.toJson(tile),
      'pos': pos,
      'content': content,
      'src': src,
    };
  }

  @override
  String toString() {
    return 'name:$name,roundId:$roundId,action:${action.name},owner:$owner,src:$src,tile:$tile,pos:$pos,sender:$sender,receiver:$receiver,content:$content';
  }
}

enum RoomEventActionResult {
  // 成功
  success,
  // 参与者不匹配
  error,
  // 牌不存在
  exist,
  // 牌的数目不对
  count,
  // 检查有待定的行为
  check
}

class RoomEventActions {
  static const String mahjongPath = 'mahjong/';
  final Map<RoomEventAction, Sprite> roomEventActions = {};

  RoomEventActions() {
    init();
  }

  Future<Sprite?> loadSprite(RoomEventAction outstandingAction) async {
    try {
      Image image =
          await Flame.images.load('$mahjongPath${outstandingAction.name}.webp');

      return Sprite(image);
    } catch (e) {
      logger.e('loadSprite failure:$e');
    }

    return null;
  }

  Future<void> init() async {
    for (var outstandingAction in RoomEventAction.values) {
      Sprite? sprite = await loadSprite(outstandingAction);
      if (sprite != null) {
        roomEventActions[outstandingAction] = sprite;
      }
    }
  }

  Sprite? operator [](RoomEventAction outstandingAction) {
    return roomEventActions[outstandingAction];
  }
}

final RoomEventActions allOutstandingActions = RoomEventActions();
