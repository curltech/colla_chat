import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/game/mahjong/base/full_pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/room.dart';
import 'package:colla_chat/pages/game/mahjong/base/room_event.dart';
import 'package:colla_chat/pages/game/mahjong/base/room_pool.dart';
import 'package:colla_chat/pages/game/mahjong/base/round.dart';
import 'package:colla_chat/pages/game/mahjong/base/round_participant.dart';
import 'package:colla_chat/pages/game/mahjong/base/tile.dart' as mahjongCard;
import 'package:colla_chat/pages/game/mahjong/component/mahjong_flame_game.dart';
import 'package:colla_chat/pages/game/mahjong/room_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 18m麻将游戏
class Majiang18mWidget extends StatelessWidget with TileDataMixin {
  Majiang18mWidget({super.key}) {
    logger.i('Full mahjong cards category number is:${fullPile.tiles.length}');
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'mahjong_18m';

  @override
  IconData get iconData => Icons.diamond_outlined;

  @override
  String get title => 'Mahjong 18m';

  RxBool fullscreen = false.obs;

  TextEditingController textEditingController = TextEditingController();
  List<String> peerIds = [myself.peerId!];

  //房间成员显示界面
  Widget _buildRoomParticipantWidget(BuildContext context) {
    return Column(children: [
      CommonAutoSizeTextFormField(
        controller: textEditingController,
        labelText: AppLocalizations.t('Name'),
      ),
      const SizedBox(
        height: 20.0,
      ),
      LinkmanGroupSearchWidget(
        key: UniqueKey(),
        selectType: SelectType.chipMultiSelectField,
        onSelected: (List<String>? selected) async {
          if (selected != null) {
            if (selected.contains(myself.peerId)) {
              selected.remove(myself.peerId!);
              selected.insert(0, myself.peerId!);
            } else {
              selected.insert(0, myself.peerId!);
            }
            peerIds = selected;
          } else {
            peerIds.clear();
            peerIds.add(myself.peerId!);
          }
        },
        selected: [myself.peerId!],
        includeGroup: false,
      ),
    ]);
  }

  Future<void> createRoom(String name) async {
    roomController.room.value = await roomPool.startRoomEvent(RoomEvent(name,
        owner: -1, action: RoomEventAction.room, content: peerIds));
  }

  /// 弹出对话框，输入名称，选择参加的人
  _createRoomWidget(BuildContext context) async {
    ButtonStyle style = StyleUtil.buildButtonStyle();
    ButtonStyle mainStyle = StyleUtil.buildButtonStyle(
        backgroundColor: myself.primary, elevation: 10.0);
    await DialogUtil.show(builder: (BuildContext context) {
      return Dialog(
          child: Card(
              elevation: 0.0,
              margin: const EdgeInsets.all(0.0),
              shape: const ContinuousRectangleBorder(),
              child: Column(
                children: [
                  AppBarWidget.buildTitleBar(
                      title: CommonAutoSizeText(
                    AppLocalizations.t('Majiang room and participants'),
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  )),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: _buildRoomParticipantWidget(context)),
                  const Spacer(),
                  Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: OverflowBar(
                        spacing: 10.0,
                        alignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              style: style,
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: CommonAutoSizeText(
                                  AppLocalizations.t('Cancel'))),
                          TextButton(
                              style: mainStyle,
                              onPressed: () {
                                Navigator.pop(context);
                                String name = textEditingController.text;
                                if (name.isNotEmpty) {
                                  createRoom(name);
                                }
                              },
                              child:
                                  CommonAutoSizeText(AppLocalizations.t('Ok'))),
                        ],
                      ))
                ],
              )));
    });
  }

  List<Widget> _buildRightWidgets(BuildContext context) {
    Room? room = roomController.room.value;
    List<Widget>? rightWidgets = [
      IconButton(
          tooltip: AppLocalizations.t('Logger console'),
          onPressed: () async {
            indexWidgetProvider.push('logger');
          },
          icon: const Icon(Icons.list_outlined)),
      IconButton(
          tooltip: AppLocalizations.t('New room'),
          onPressed: () {
            _createRoomWidget(context);
          },
          icon: const Icon(Icons.new_label))
    ];
    if (room != null &&
        room.creator == roomController.selfParticipantDirection.value.index) {
      rightWidgets.add(IconButton(
          tooltip: AppLocalizations.t('New round'),
          onPressed: () {
            /// 新的一轮的庄家是当前选择的参与者
            room.startRoomEvent(RoomEvent(room.name,
                owner: room.banker, action: RoomEventAction.round));
          },
          icon: const Icon(Icons.newspaper_outlined)));
    }
    if (room != null) {
      rightWidgets.add(IconButton(
          tooltip: AppLocalizations.t('Check'),
          onPressed: () {
            Round? currentRound = room.currentRound;
            if (currentRound == null) {
              return;
            }
            RoundParticipant? currentRoundParticipant =
                roomController.getRoundParticipant(
                    roomController.selfParticipantDirection.value);
            if (currentRoundParticipant == null) {
              return;
            }
            mahjongCard.Tile? discardTile =
                currentRound.discardToken?.discardTile;
            mahjongCard.Tile? drawTile =
                currentRoundParticipant.handPile.drawTile;
            Map<RoomEventAction, Set<int>> outstandingActions;
            if (drawTile != null) {
              outstandingActions =
                  currentRoundParticipant.check(tile: drawTile);
            } else if (discardTile != null) {
              outstandingActions =
                  currentRoundParticipant.check(tile: discardTile);
            }
            mahjongFlameGame.reloadSelf();
          },
          icon: const Icon(Icons.check)));
      rightWidgets.add(IconButton(
          tooltip: AppLocalizations.t('score'),
          onPressed: () {
            Round? currentRound = room.currentRound;
            if (currentRound == null) {
              return;
            }
            RoundParticipant? currentRoundParticipant =
                roomController.getRoundParticipant(
                    roomController.selfParticipantDirection.value);
            if (currentRoundParticipant == null) {
              return;
            }
            mahjongCard.Tile? drawTile =
                currentRoundParticipant.handPile.drawTile;
            Map<mahjongCard.Tile, int> scores;
            if (drawTile != null) {
              scores = currentRoundParticipant.drawScore();
            }
          },
          icon: const Icon(Icons.score_outlined)));
    }

    return rightWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return AppBarView(
          title: title,
          withLeading: true,
          rightWidgets: _buildRightWidgets(context),
          child: GameWidget(game: mahjongFlameGame));
    });
  }
}
