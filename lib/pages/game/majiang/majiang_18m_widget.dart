import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/game/majiang/base/RoundParticipant.dart';
import 'package:colla_chat/pages/game/majiang/base/card.dart' as majiangCard;
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/base/room_pool.dart';
import 'package:colla_chat/pages/game/majiang/base/round.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
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
  ModelFlameGame? modelFlameGame;

  Majiang18mWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'majiang_18m';

  @override
  IconData get iconData => Icons.model_training_outlined;

  @override
  String get title => 'Majiang 18m';

  MajiangFlameGame? majiangFlameGame;

  final Rx<Room?> room = Rx<Room?>(null);

  final Rx<ParticipantDirection> currentDirection =
      ParticipantDirection.east.obs;

  final Map<int, String> directions = {
    0: AppLocalizations.t('East'),
    1: AppLocalizations.t('South'),
    2: AppLocalizations.t('West'),
    3: AppLocalizations.t('North'),
    4: AppLocalizations.t('East'),
    5: AppLocalizations.t('South'),
    6: AppLocalizations.t('West'),
  };

  RxBool fullscreen = false.obs;

  TextEditingController textEditingController = TextEditingController();
  List<String> peerIds = [myself.peerId!];

  //房间成员显示界面
  Widget _buildRoomPartcipantWidget(BuildContext context) {
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
            if (!selected.contains(myself.peerId)) {
              selected.add(myself.peerId!);
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
    room.value = await roomPool.createRoom(name, peerIds);
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
                      child: _buildRoomPartcipantWidget(context)),
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
    Room? room = this.room.value;
    List<Widget>? rightWidgets = [
      IconButton(
          tooltip: AppLocalizations.t('Full screen'),
          onPressed: () async {
            fullscreen.value = true;
            await DialogUtil.showFullScreen(
                context: context, child: GameWidget(game: majiangFlameGame!));
            fullscreen.value = false;
          },
          icon: const Icon(Icons.fullscreen)),
      IconButton(
          tooltip: AppLocalizations.t('New room'),
          onPressed: () {
            _createRoomWidget(context);
          },
          icon: const Icon(Icons.new_label))
    ];
    if (room != null) {
      rightWidgets.add(IconButton(
          tooltip: AppLocalizations.t('New round'),
          onPressed: () {
            room.onRoomEvent(RoomEvent(room.name, null,
                room.currentDirection.index, RoomEventAction.round));
          },
          icon: const Icon(Icons.newspaper_outlined)));
      rightWidgets.add(IconButton(
          tooltip: AppLocalizations.t('Check complete'),
          onPressed: () {
            Round? currentRound = room.currentRound;
            if (currentRound == null) {
              return;
            }
            RoundParticipant? currentRoundParticipant =
                room.currentRoundParticipant;
            if (currentRoundParticipant == null) {
              return;
            }
            majiangCard.Card? sendCard = currentRound.sendCard;
            majiangCard.Card? takeCard =
                currentRoundParticipant.handPile.takeCard;
            if (sendCard != null) {
              currentRoundParticipant.onRoomEvent(RoomEvent(
                  room.name,
                  currentRound.id,
                  currentRoundParticipant.direction.index,
                  RoomEventAction.checkComplete,
                  card: sendCard));
            }
            if (takeCard != null) {
              currentRoundParticipant.onRoomEvent(RoomEvent(
                  room.name,
                  currentRound.id,
                  currentRoundParticipant.direction.index,
                  RoomEventAction.checkComplete,
                  card: takeCard));
            }
          },
          icon: const Icon(Icons.check)));
      rightWidgets.add(IconButton(
          tooltip: AppLocalizations.t('Check take'),
          onPressed: () {
            Round? currentRound = room.currentRound;
            if (currentRound == null) {
              return;
            }
            RoundParticipant currentRoundParticipant =
                currentRound.currentRoundParticipant;
            majiangCard.Card? takeCard =
                currentRoundParticipant.handPile.takeCard;
            if (takeCard != null) {
              currentRoundParticipant.onRoomEvent(RoomEvent(
                  room.name,
                  currentRound.id,
                  currentRoundParticipant.direction.index,
                  RoomEventAction.checkComplete,
                  card: takeCard));
            }
          },
          icon: const Icon(Icons.takeout_dining_outlined)));
    }
    ;

    return rightWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      majiangFlameGame = MajiangFlameGame();
      return AppBarView(
          title: title,
          withLeading: true,
          rightWidgets: _buildRightWidgets(context),
          child: GameWidget(game: majiangFlameGame!));
    });
  }
}
