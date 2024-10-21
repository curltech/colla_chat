import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/game/majiang/card.dart';
import 'package:colla_chat/pages/game/majiang/card_util.dart';
import 'package:colla_chat/pages/game/majiang/participant_card.dart';
import 'package:colla_chat/pages/game/majiang/room.dart';
import 'package:colla_chat/pages/game/majiang/room_pool.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 功能主页面，带有路由回调函数
class MajiangWidget extends StatelessWidget with TileDataMixin {
  MajiangWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'majiang';

  @override
  IconData get iconData => Icons.card_giftcard_outlined;

  @override
  String get title => 'Majiang';

  final Rx<MajiangRoom?> majiangRoom = Rx<MajiangRoom?>(null);

  final RxInt current = 0.obs;

  final double amplyFactor = 1.2;

  final double totalWidth = 1110;
  final double totalHeight = 650;

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

  /// 自己的手牌
  Widget _buildHandCard() {
    double ratio = 0.75;
    return Obx(() {
      MajiangRoom? majiangRoom = this.majiangRoom.value;
      if (majiangRoom == null) {
        return nilBox;
      }
      List<Widget> children = [];
      int owner = current.value;
      ParticipantCard participantCard = majiangRoom.participantCards[owner];
      for (var card in participantCard.drawingCards) {
        Widget touchCard = card.touchCard();
        children.add(touchCard);
        children.add(const SizedBox(
          width: 5,
        ));
      }
      for (var card in participantCard.touchCards) {
        Widget touchCard = card.touchCard();
        children.add(touchCard);
        children.add(const SizedBox(
          width: 5,
        ));
      }
      for (var card in participantCard.handCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget handcard = majiangCard.handCard(ratio: ratio);
        handcard = InkWell(
            onTap: () {
              majiangRoom.onRoomEvent(RoomEvent(
                  majiangRoom.name, owner, RoomEventAction.send,
                  card: card));
            },
            child: handcard);
        children.add(handcard);
        children.add(const SizedBox(
          width: 0.5,
        ));
      }
      var card = participantCard.takeCard.value;

      if (card != null) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget handcard = majiangCard.handCard(ratio: ratio);
        handcard = InkWell(
            onTap: () {
              majiangRoom.onRoomEvent(RoomEvent(
                  majiangRoom.name, owner, RoomEventAction.send,
                  card: card));
            },
            child: handcard);
        children.add(const SizedBox(
          width: 15.0,
        ));
        children.add(handcard);
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      );
    });
  }

  /// 上家手牌
  Widget _buildPreviousHand() {
    double ratio = 0.8;
    return Obx(() {
      MajiangRoom? majiangRoom = this.majiangRoom.value;
      if (majiangRoom == null) {
        return nilBox;
      }
      List<Widget> children = [];
      int owner = majiangRoom.previous(current.value);
      ParticipantCard participantCard = majiangRoom.participantCards[owner];

      for (var card in participantCard.drawingCards) {
        Widget previousTouchCard = card.previousTouchCard(ratio: ratio * 0.8);
        children.add(previousTouchCard);
        children.add(const SizedBox(
          height: 5,
        ));
      }
      for (var card in participantCard.touchCards) {
        Widget previousTouchCard = card.previousTouchCard(ratio: ratio * 0.8);
        children.add(previousTouchCard);
        children.add(const SizedBox(
          height: 5,
        ));
      }
      int length = participantCard.handCards.length;
      for (var i = 0; i < participantCard.handCards.length; ++i) {
        var card = participantCard.handCards[i];
        MajiangCard majiangCard = MajiangCard(card);
        Widget previousHand = majiangCard.previousHand(
            clip: i < length - 1 ? true : false, ratio: ratio);
        children.add(previousHand);
      }
      String? card = participantCard.takeCard.value;
      if (card != null) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget previousHand =
            majiangCard.previousHand(clip: false, ratio: ratio);
        children.add(previousHand);
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      );
    });
  }

  /// 对家手牌
  Widget _buildOpponentHand() {
    double ratio = 0.8;
    return Obx(() {
      MajiangRoom? majiangRoom = this.majiangRoom.value;
      if (majiangRoom == null) {
        return nilBox;
      }
      List<Widget> children = [];
      int owner = majiangRoom.opponent(current.value);
      ParticipantCard participantCard = majiangRoom.participantCards[owner];

      for (var card in participantCard.drawingCards) {
        Widget opponentTouchCard = card.opponentTouchCard(ratio: ratio);
        children.add(opponentTouchCard);
        children.add(const SizedBox(
          width: 5,
        ));
      }
      for (var card in participantCard.touchCards) {
        Widget opponentTouchCard = card.opponentTouchCard(ratio: ratio);
        children.add(opponentTouchCard);
        children.add(const SizedBox(
          width: 5,
        ));
      }
      String? card = participantCard.takeCard.value;
      if (card != null) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget opponentHand = majiangCard.opponentHand(ratio: ratio);
        children.add(opponentHand);
        children.add(const SizedBox(
          width: 5.0,
        ));
      }
      for (var card in participantCard.handCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget opponentHand = majiangCard.opponentHand(ratio: ratio);
        children.add(opponentHand);
      }
      return Center(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ));
    });
  }

  /// 下家手牌
  Widget _buildNextHand() {
    double ratio = 0.8;
    return Obx(() {
      MajiangRoom? majiangRoom = this.majiangRoom.value;
      if (majiangRoom == null) {
        return nilBox;
      }
      List<Widget> children = [];
      int owner = majiangRoom.next(current.value);
      ParticipantCard participantCard = majiangRoom.participantCards[owner];

      String? card = participantCard.takeCard.value;
      if (card != null) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget nextHand = majiangCard.nextHand(clip: false, ratio: ratio);
        children.add(nextHand);
      }
      int length = participantCard.handCards.length;
      for (var i = 0; i < participantCard.handCards.length; ++i) {
        var card = participantCard.handCards[i];
        MajiangCard majiangCard = MajiangCard(card);
        Widget nextHand = majiangCard.nextHand(
            clip: i < length - 1 ? true : false, ratio: ratio);
        children.add(nextHand);
      }
      for (var card in participantCard.drawingCards) {
        Widget nextTouchCard = card.nextTouchCard(ratio: ratio * 0.8);
        children.add(const SizedBox(
          height: 5,
        ));
        children.add(nextTouchCard);
      }
      for (var card in participantCard.touchCards) {
        Widget nextTouchCard = card.nextTouchCard(ratio: ratio * 0.8);
        children.add(const SizedBox(
          height: 5,
        ));
        children.add(nextTouchCard);
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      );
    });
  }

  /// 上家河牌
  Widget _buildPreviousTouchCard() {
    double ratio = 0.9;
    int segment = 11;
    return Obx(() {
      MajiangRoom? majiangRoom = this.majiangRoom.value;
      if (majiangRoom == null) {
        return nilBox;
      }
      int owner = majiangRoom.previous(current.value);
      ParticipantCard participantCard = majiangRoom.participantCards[owner];
      int length = participantCard.poolCards.length;
      List<Widget> rowChildren = [];
      for (var i = 0; i < length; i = i + 11) {
        List<Widget> columnChildren = [];
        for (int j = 0; j < segment; ++j) {
          if (j + i < length) {
            var card = participantCard.poolCards[j + i];
            MajiangCard majiangCard = MajiangCard(card);
            bool clip = true;
            double factRatio = ratio;
            if (j == segment - 1 || j + i == length - 1) {
              clip = false;
            }
            if (j + i == length - 1) {
              if (majiangRoom.sendCard != null &&
                  majiangRoom.sendCard == card) {
                factRatio = ratio * amplyFactor;
              }
            }
            Widget previousTouchCard =
                majiangCard.previousTouchCard(ratio: factRatio, clip: clip);
            columnChildren.add(previousTouchCard);
          }
        }
        Widget columnWidget = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columnChildren,
        );
        rowChildren.add(columnWidget);
      }
      Widget poolCard = Row(children: rowChildren);

      return poolCard;
    });
  }

  /// 下家河牌
  Widget _buildNextTouchCard() {
    double ratio = 0.9;
    int segment = 11;
    return Obx(() {
      MajiangRoom? majiangRoom = this.majiangRoom.value;
      if (majiangRoom == null) {
        return nilBox;
      }
      int owner = majiangRoom.next(current.value);
      ParticipantCard participantCard = majiangRoom.participantCards[owner];
      int length = participantCard.poolCards.length;
      List<Widget> rowChildren = [];
      for (var i = 0; i < length; i = i + segment) {
        List<Widget> columnChildren = [];
        for (int j = 0; j < segment; ++j) {
          if (j + i < length) {
            var card = participantCard.poolCards[j + i];
            MajiangCard majiangCard = MajiangCard(card);
            bool clip = true;
            double factRatio = ratio;
            if (j == segment - 1 || j + i == length - 1) {
              clip = false;
            }
            if (j + i == length - 1) {
              if (majiangRoom.sendCard != null &&
                  majiangRoom.sendCard == card) {
                factRatio = ratio * amplyFactor;
              }
            }
            Widget nextTouchCard =
                majiangCard.nextTouchCard(ratio: factRatio, clip: clip);
            columnChildren.add(nextTouchCard);
          }
        }
        Widget columnWidget = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: columnChildren,
        );
        rowChildren.add(columnWidget);
      }
      rowChildren = rowChildren.reversed.toList();
      rowChildren.insert(0, const Spacer());
      return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowChildren);
    });
  }

  /// 自己的河牌，碰牌或者杠牌
  Widget _buildTouchCard() {
    double ratio = 0.7;
    int segment = 11;
    return Obx(() {
      MajiangRoom? majiangRoom = this.majiangRoom.value;
      if (majiangRoom == null) {
        return nilBox;
      }
      int owner = current.value;
      ParticipantCard participantCard = majiangRoom.participantCards[owner];
      int length = participantCard.poolCards.length;
      List<Widget> columnChildren = [];
      for (var i = 0; i < length; i = i + segment) {
        List<Widget> rowChildren = [];
        for (int j = 0; j < segment; ++j) {
          if (j + i < length) {
            var card = participantCard.poolCards[j + i];
            MajiangCard majiangCard = MajiangCard(card);
            double factRatio = ratio;
            if (j + i == length - 1) {
              if (majiangRoom.sendCard != null &&
                  majiangRoom.sendCard == card) {
                factRatio = ratio * amplyFactor;
              }
            }
            Widget touchCard = majiangCard.touchCard(ratio: factRatio);
            rowChildren.add(touchCard);
          }
        }
        Widget rowWidget = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: rowChildren,
        );
        columnChildren.add(rowWidget);
      }
      columnChildren = columnChildren.reversed.toList();
      columnChildren.insert(0, const Spacer());
      return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: columnChildren);
    });
  }

  /// 对家河牌
  Widget _buildOpponentTouchCard() {
    double ratio = 0.7;
    int segment = 11;
    return Obx(() {
      MajiangRoom? majiangRoom = this.majiangRoom.value;
      if (majiangRoom == null) {
        return nilBox;
      }
      int owner = majiangRoom.opponent(current.value);
      ParticipantCard participantCard = majiangRoom.participantCards[owner];
      int length = participantCard.poolCards.length;
      List<Widget> columnChildren = [];
      for (var i = 0; i < length; i = i + segment) {
        List<Widget> rowChildren = [];
        for (int j = 0; j < segment; ++j) {
          if (j + i < length) {
            var card = participantCard.poolCards[j + i];
            double factRatio = ratio;
            if (majiangRoom.sendCard != null && majiangRoom.sendCard == card) {
              factRatio = ratio * amplyFactor;
            }
            MajiangCard majiangCard = MajiangCard(card);
            Widget opponentTouchCard =
                majiangCard.opponentTouchCard(ratio: factRatio);
            rowChildren.add(opponentTouchCard);
          }
        }
        Widget rowWidget = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowChildren,
        );
        columnChildren.add(rowWidget);
      }

      return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columnChildren);
    });
  }

  Widget _buildCardPool(BuildContext context) {
    MajiangRoom? majiangRoom = this.majiangRoom.value;
    if (majiangRoom == null) {
      return nilBox;
    }
    double poolWidth = totalWidth * 0.17;
    double poolHeight = totalHeight * 0.6;
    return Stack(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        //上家
        InkWell(
            onTap: () {
              MajiangRoom? majiangRoom = this.majiangRoom.value;
              if (majiangRoom != null) {
                int previous = majiangRoom.previous(current.value);
                current.value = previous;
              }
            },
            child: Container(
                color: current.value + 3 == majiangRoom.banker ||
                        current.value + 3 ==
                            (majiangRoom.banker != null
                                ? majiangRoom.banker! + 4
                                : null)
                    ? Colors.yellow.withOpacity(0.2)
                    : Colors.white.withOpacity(0.2),
                height: poolHeight,
                width: poolWidth,
                child: Stack(children: [
                  Center(
                    child: Text(
                      directions[current.value + 3]!,
                      style: const TextStyle(color: Colors.white, fontSize: 28),
                    ),
                  ),
                  _buildPreviousTouchCard(),
                ]))),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //对家
            InkWell(
                onTap: () {
                  MajiangRoom? majiangRoom = this.majiangRoom.value;
                  if (majiangRoom != null) {
                    int opponent = majiangRoom.opponent(current.value);
                    current.value = opponent;
                  }
                },
                child: Container(
                    color: current.value + 2 == majiangRoom.banker ||
                            current.value + 2 ==
                                (majiangRoom.banker != null
                                    ? majiangRoom.banker! + 4
                                    : null)
                        ? Colors.yellow.withOpacity(0.2)
                        : Colors.white.withOpacity(0.2),
                    height: poolWidth,
                    width: poolHeight,
                    child: Stack(children: [
                      Center(
                        child: Text(
                          directions[current.value + 2]!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 28),
                        ),
                      ),
                      _buildOpponentTouchCard(),
                    ]))),
            fullscreen.value
                ? Center(
                    child: IconButton(
                        onPressed: () {
                          if (fullscreen.value) {
                            Navigator.of(context).pop();
                            fullscreen.value = false;
                          }
                        },
                        icon: const Icon(Icons.fullscreen_exit_outlined)))
                : const Spacer(),
            Container(
              color: current.value == majiangRoom.banker ||
                      current.value ==
                          (majiangRoom.banker != null
                              ? majiangRoom.banker! + 4
                              : null)
                  ? Colors.yellow.withOpacity(0.2)
                  : Colors.white.withOpacity(0.2),
              height: poolWidth,
              width: poolHeight,
              child: Stack(children: [
                Center(
                  child: Text(
                    directions[current.value]!,
                    style: const TextStyle(color: Colors.white, fontSize: 28),
                  ),
                ),
                _buildTouchCard(),
              ]),
            ),
          ],
        ),
        InkWell(
          onTap: () {
            MajiangRoom? majiangRoom = this.majiangRoom.value;
            if (majiangRoom != null) {
              int next = majiangRoom.next(current.value);
              current.value = next;
            }
          },
          child: Container(
              color: current.value + 1 == majiangRoom.banker ||
                      current.value + 1 ==
                          (majiangRoom.banker != null
                              ? majiangRoom.banker! + 4
                              : null)
                  ? Colors.yellow.withOpacity(0.2)
                  : Colors.white.withOpacity(0.2),
              height: poolHeight,
              width: poolWidth,
              child: Stack(children: [
                Center(
                  child: Text(
                    directions[current.value + 1]!,
                    style: const TextStyle(color: Colors.white, fontSize: 28),
                  ),
                ),
                _buildNextTouchCard(),
              ])),
        ),
      ])
    ]);
  }

  Widget _buildDesktop(BuildContext context) {
    return Obx(() {
      MajiangRoom? majiangRoom = this.majiangRoom.value;
      if (majiangRoom == null) {
        return nilBox;
      }
      int pos = current.value;
      ParticipantCard participantCard = majiangRoom.participantCards[pos];
      pos = majiangRoom.next(current.value);
      ParticipantCard nextParticipantCard = majiangRoom.participantCards[pos];
      pos = majiangRoom.previous(current.value);
      ParticipantCard previousParticipantCard =
          majiangRoom.participantCards[pos];
      pos = majiangRoom.opponent(current.value);
      ParticipantCard opponentParticipantCard =
          majiangRoom.participantCards[pos];
      return Column(children: [
        SizedBox(
            height: totalHeight * 0.15,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(
                width: 10.0,
              ),
              IconTextButton(
                label:
                    '${opponentParticipantCard.name}(${opponentParticipantCard.score})',
                icon: opponentParticipantCard.avatarWidget!,
                onPressed: null,
              ),
              const SizedBox(
                width: 10.0,
              ),
              Expanded(child: _buildOpponentHand()),
            ])),
        Expanded(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: totalWidth * 0.15,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                const SizedBox(
                  width: 10.0,
                ),
                Expanded(
                    child: IconTextButton(
                  label:
                      '${previousParticipantCard.name}(${previousParticipantCard.score})',
                  icon: previousParticipantCard.avatarWidget!,
                  onPressed: null,
                )),
                const SizedBox(
                  width: 10.0,
                ),
                Align(
                    alignment: Alignment.centerRight,
                    child: _buildPreviousHand()),
                const SizedBox(
                  width: 30.0,
                ),
              ]),
            ),
            Expanded(
                child: Container(
              child: _buildCardPool(context),
            )),
            SizedBox(
              width: totalWidth * 0.15,
              child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                const SizedBox(
                  width: 30.0,
                ),
                _buildNextHand(),
                const SizedBox(
                  width: 10.0,
                ),
                Expanded(
                    child: IconTextButton(
                  label:
                      '${nextParticipantCard.name}(${nextParticipantCard.score})',
                  icon: nextParticipantCard.avatarWidget!,
                  onPressed: null,
                )),
                const SizedBox(
                  width: 10.0,
                ),
              ]),
            ),
          ],
        )),
        SizedBox(
            height: totalHeight * 0.2,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(
                width: 10.0,
              ),
              IconTextButton(
                label: '${participantCard.name}(${participantCard.score})',
                icon: participantCard.avatarWidget!,
                onPressed: null,
              ),
              const SizedBox(
                width: 10.0,
              ),
              Expanded(
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: _buildHandCard())),
              const SizedBox(
                width: 30.0,
              ),
            ])),
      ]);
    });
  }

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

  /// 弹出对话框，输入名称，选择参加的人
  _createMajiangRoom(BuildContext context) async {
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

  Future<void> createRoom(String name) async {
    majiangRoom.value = await majiangRoomPool.createRoom(name, peerIds);
    current.value = majiangRoom.value!.current;
  }

  _call(MajiangRoom majiangRoom, int owner, ParticipantState participantState,
      {List<int>? pos}) async {
    if (participantState == ParticipantState.complete) {
      CompleteType? completeType = await majiangRoom.onRoomEvent(
          RoomEvent(majiangRoom.name, owner, RoomEventAction.complete));
      if (completeType != null) {
        majiangRoom.onRoomEvent(
            RoomEvent(majiangRoom.name, owner, RoomEventAction.round));
      }
    } else if (participantState == ParticipantState.touch) {
      majiangRoom.onRoomEvent(RoomEvent(
          majiangRoom.name, owner, RoomEventAction.touch,
          src: majiangRoom.sender, card: majiangRoom.sendCard, pos: pos![0]));
    } else if (participantState == ParticipantState.bar) {
      majiangRoom.onRoomEvent(RoomEvent(
          majiangRoom.name, owner, RoomEventAction.bar,
          pos: pos![0]));
    } else if (participantState == ParticipantState.darkBar) {
      majiangRoom.onRoomEvent(RoomEvent(
          majiangRoom.name, owner, RoomEventAction.darkBar,
          pos: pos![0]));
    } else if (participantState == ParticipantState.pass) {
      majiangRoom.onRoomEvent(RoomEvent(
          majiangRoom.name, owner, RoomEventAction.pass,
          pos: pos![0]));
    } else if (participantState == ParticipantState.drawing) {
      majiangRoom.onRoomEvent(RoomEvent(
          majiangRoom.name, owner, RoomEventAction.drawing,
          pos: pos![0]));
    }
  }

  Widget _buildParticipantStateWidget(
    BuildContext context,
    Widget desktopWidget,
  ) {
    return Obx(() {
      Widget child = desktopWidget;
      MajiangRoom? majiangRoom = this.majiangRoom.value;
      if (majiangRoom != null) {
        int owner = current.value;
        ParticipantCard participantCard = majiangRoom.participantCards[owner];
        Map<ParticipantState, List<int>> participantState =
            participantCard.participantState;
        if (participantState.isNotEmpty) {
          List<Widget>? stateButtons = [];
          for (var entry in participantState.entries) {
            ParticipantState participantState = entry.key;

            /// 位置，在明杠，暗杠，吃牌的时候有用
            List<int> pos = entry.value;
            Widget? image = cardConcept.getStateImage(participantState.name);
            if (image != null) {
              stateButtons.add(IconButton(
                onPressed: () {
                  _call(majiangRoom, owner, participantState, pos: pos);
                  participantCard.participantState.clear();
                },
                icon: image,
              ));
            }
          }
          Widget? image = cardConcept.getStateImage(ParticipantState.pass.name);
          if (image != null) {
            stateButtons.add(IconButton(
              onPressed: () {
                _call(majiangRoom, owner, ParticipantState.pass);
                participantCard.participantState.clear();
              },
              icon: image,
            ));
          }

          Widget stateWidget = Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                  padding: const EdgeInsets.all(100.0),
                  child: OverflowBar(
                    spacing: 10.0,
                    alignment: MainAxisAlignment.end,
                    children: stateButtons,
                  )));
          child = Stack(
            children: [IgnorePointer(child: child), stateWidget],
          );
        }

        child = FittedBox(
            child:
                SizedBox(height: totalHeight, width: totalWidth, child: child));

        /// 这种做法鼠标点击太慢
        // if (fullscreen.value) {
        //   child = InkWell(
        //       onDoubleTap: () {
        //         if (fullscreen.value) {
        //           fullscreen.value = false;
        //           Navigator.of(context).pop();
        //         }
        //       },
        //       child: child);
        // }
      }

      return child;
    });
  }

  @override
  Widget build(BuildContext context) {
    var majiangMain = Obx(() {
      MajiangRoom? majiangRoom = this.majiangRoom.value;
      String? title = majiangRoom?.name;
      Widget desktopWidget = Stack(
        fit: StackFit.expand,
        children: [
          backgroundImage.get('background')!,
          _buildDesktop(context),
        ],
      );
      desktopWidget = _buildParticipantStateWidget(context, desktopWidget);

      List<Widget>? rightWidgets = [
        IconButton(
            tooltip: AppLocalizations.t('Full screen'),
            onPressed: () async {
              fullscreen.value = true;
              await DialogUtil.showFullScreen(
                  context: context, child: desktopWidget);
              fullscreen.value = false;
            },
            icon: const Icon(Icons.fullscreen)),
        IconButton(
            tooltip: AppLocalizations.t('New room'),
            onPressed: () {
              _createMajiangRoom(context);
            },
            icon: const Icon(Icons.new_label))
      ];
      if (majiangRoom != null) {
        rightWidgets.add(IconButton(
            tooltip: AppLocalizations.t('New round'),
            onPressed: () {
              majiangRoom.onRoomEvent(RoomEvent(
                  majiangRoom.name, current.value, RoomEventAction.round));
            },
            icon: const Icon(Icons.newspaper_outlined)));
        rightWidgets.add(IconButton(
            tooltip: AppLocalizations.t('Check complete'),
            onPressed: () {
              ParticipantCard participantCard =
                  majiangRoom.participantCards[current.value];
              String? sendCard = majiangRoom.sendCard;
              String? comingCard = participantCard.takeCard.value;
              if (sendCard != null) {
                participantCard.onRoomEvent(RoomEvent(majiangRoom.name,
                    current.value, RoomEventAction.checkComplete,
                    card: sendCard));
              }
              if (comingCard != null) {
                participantCard.onRoomEvent(RoomEvent(majiangRoom.name,
                    current.value, RoomEventAction.checkComplete,
                    card: comingCard));
              }
            },
            icon: const Icon(Icons.check)));
        rightWidgets.add(IconButton(
            tooltip: AppLocalizations.t('Check take'),
            onPressed: () {
              ParticipantCard participantCard =
                  majiangRoom.participantCards[current.value];
              String? comingCard = participantCard.takeCard.value;
              if (comingCard != null) {
                participantCard.onRoomEvent(RoomEvent(
                    majiangRoom.name, current.value, RoomEventAction.check,
                    card: comingCard));
              }
            },
            icon: const Icon(Icons.takeout_dining_outlined)));
      }

      return AppBarView(
          title: title ?? this.title,
          withLeading: true,
          rightWidgets: rightWidgets,
          child: desktopWidget);
    });

    return majiangMain;
  }
}
