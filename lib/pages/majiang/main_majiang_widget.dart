import 'package:align_positioned/align_positioned.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/majiang/card.dart';
import 'package:colla_chat/pages/majiang/participant_card.dart';
import 'package:colla_chat/pages/majiang/room.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
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

/// 股票功能主页面，带有路由回调函数
class MainMajiangWidget extends StatelessWidget with TileDataMixin {
  MainMajiangWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'majiang_main';

  @override
  IconData get iconData => Icons.card_giftcard_outlined;

  @override
  String get title => 'Majiang';

  final Rx<MajiangRoom?> majiangRoom = Rx<MajiangRoom?>(null);

  final RxInt current = 0.obs;

  /// 自己的手牌
  Widget _buildHandCard() {
    double ratio = 0.75;
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> children = [];
      int pos = current.value;
      ParticipantCard participantCard = majiangRoom.participantCards[pos];
      for (var card in participantCard.allDrawingCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget touchCard = majiangCard.touchCard();
        children.add(touchCard);
      }
      for (var card in participantCard.allTouchCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget touchCard = majiangCard.touchCard();
        children.add(touchCard);
      }
      for (var card in participantCard.handCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget handcard = majiangCard.handCard(ratio: ratio);
        handcard = InkWell(
            onTap: () {
              majiangRoom.send(pos, card);
            },
            child: handcard);
        children.add(handcard);
        children.add(const SizedBox(
          width: 0.5,
        ));
      }
      var card = participantCard.comingCard.value;

      if (card != null) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget handcard = majiangCard.handCard(ratio: ratio);
        handcard = InkWell(
            onTap: () {
              majiangRoom.send(pos, card);
            },
            child: handcard);
        children.add(const SizedBox(
          width: 15.0,
        ));
        children.add(handcard);
      }

      return Wrap(
        children: children,
      );
    });
  }

  /// 上家手牌
  Widget _buildPreviousHand() {
    double ratio = 0.8;
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> children = [];
      int pos = majiangRoom.previous(current.value);
      ParticipantCard participantCard = majiangRoom.participantCards[pos];

      for (var card in participantCard.allDrawingCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget previousTouchCard = majiangCard.previousTouchCard(ratio: ratio);
        children.add(previousTouchCard);
      }
      for (var card in participantCard.allTouchCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget previousTouchCard = majiangCard.previousTouchCard(ratio: ratio);
        children.add(previousTouchCard);
      }
      for (var i = 0; i < participantCard.handCards.length; ++i) {
        var card = participantCard.handCards[i];
        MajiangCard majiangCard = MajiangCard(card);
        Widget previousHand =
            majiangCard.previousHand(clip: i < 12 ? true : false, ratio: ratio);
        children.add(previousHand);
      }
      String? card = participantCard.comingCard.value;
      if (card != null) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget previousHand =
            majiangCard.previousHand(clip: false, ratio: ratio);
        children.add(previousHand);
      }
      return Wrap(
        direction: Axis.vertical,
        children: children,
      );
    });
  }

  /// 对家手牌
  Widget _buildOpponentHand() {
    double ratio = 0.8;
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> children = [];
      int pos = majiangRoom.opponent(current.value);
      ParticipantCard participantCard = majiangRoom.participantCards[pos];

      for (var card in participantCard.allDrawingCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget opponentTouchCard = majiangCard.opponentTouchCard(ratio: ratio);
        children.add(opponentTouchCard);
      }
      for (var card in participantCard.allTouchCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget opponentTouchCard = majiangCard.opponentTouchCard(ratio: ratio);
        children.add(opponentTouchCard);
      }
      String? card = participantCard.comingCard.value;
      if (card != null) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget opponentHand = majiangCard.opponentHand(ratio: ratio);
        children.add(opponentHand);
        children.add(const SizedBox(
          width: 15.0,
        ));
      }
      for (var card in participantCard.handCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget opponentHand = majiangCard.opponentHand(ratio: ratio);
        children.add(opponentHand);
      }
      return Center(
          child: Wrap(
        children: children,
      ));
    });
  }

  /// 下家手牌
  Widget _buildNextHand() {
    double ratio = 0.8;
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> children = [];
      int pos = majiangRoom.next(current.value);
      ParticipantCard participantCard = majiangRoom.participantCards[pos];

      for (var card in participantCard.allDrawingCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget nextTouchCard = majiangCard.nextTouchCard(ratio: ratio);
        children.add(nextTouchCard);
      }
      for (var card in participantCard.allTouchCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget nextTouchCard = majiangCard.nextTouchCard(ratio: ratio);
        children.add(nextTouchCard);
      }
      String? card = participantCard.comingCard.value;
      if (card != null) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget nextHand = majiangCard.nextHand(clip: false, ratio: ratio);
        children.add(nextHand);
      }
      for (var i = 0; i < participantCard.handCards.length; ++i) {
        var card = participantCard.handCards[i];
        MajiangCard majiangCard = MajiangCard(card);
        Widget nextHand =
            majiangCard.nextHand(clip: i < 12 ? true : false, ratio: ratio);
        children.add(nextHand);
      }
      return Wrap(
        direction: Axis.vertical,
        children: children,
      );
    });
  }

  /// 上家河牌
  Widget _buildPreviousTouchCard() {
    double ratio = 0.9;
    int segment = 11;
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      int pos = majiangRoom.previous(current.value);
      ParticipantCard participantCard = majiangRoom.participantCards[pos];
      int length = participantCard.poolCards.length;
      List<Widget> rowChildren = [];
      for (var i = 0; i < length; i = i + 11) {
        List<Widget> columnChildren = [];
        for (int j = 0; j < segment; ++j) {
          if (j + i < length) {
            var card = participantCard.poolCards[j + i];
            MajiangCard majiangCard = MajiangCard(card);
            bool clip = true;
            if (j == segment - 1 || j + i == length - 1) {
              clip = false;
            }
            Widget previousTouchCard =
                majiangCard.previousTouchCard(ratio: ratio, clip: clip);
            columnChildren.add(previousTouchCard);
          }
        }
        Widget columnWidget = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: columnChildren,
        );
        rowChildren.add(columnWidget);
      }
      return Row(children: rowChildren);
    });
  }

  /// 下家河牌
  Widget _buildNextTouchCard() {
    double ratio = 0.9;
    int segment = 11;
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      int pos = majiangRoom.next(current.value);
      ParticipantCard participantCard = majiangRoom.participantCards[pos];
      int length = participantCard.poolCards.length;
      List<Widget> rowChildren = [];
      for (var i = 0; i < length; i = i + segment) {
        List<Widget> columnChildren = [];
        for (int j = 0; j < segment; ++j) {
          if (j + i < length) {
            var card = participantCard.poolCards[j + i];
            MajiangCard majiangCard = MajiangCard(card);
            bool clip = true;
            if (j == segment - 1 || j + i == length - 1) {
              clip = false;
            }
            Widget nextTouchCard =
                majiangCard.nextTouchCard(ratio: ratio, clip: clip);
            columnChildren.add(nextTouchCard);
          }
        }
        Widget columnWidget = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: columnChildren,
        );
        rowChildren.add(columnWidget);
      }
      rowChildren = rowChildren.reversed.toList();
      rowChildren.insert(0, const Spacer());
      return Row(
          crossAxisAlignment: CrossAxisAlignment.start, children: rowChildren);
    });
  }

  /// 自己的河牌，碰牌或者杠牌
  Widget _buildTouchCard() {
    double ratio = 0.7;
    int segment = 11;
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      int pos = current.value;
      ParticipantCard participantCard = majiangRoom.participantCards[pos];
      int length = participantCard.poolCards.length;
      List<Widget> columnChildren = [];
      for (var i = 0; i < length; i = i + segment) {
        List<Widget> rowChildren = [];
        for (int j = 0; j < segment; ++j) {
          if (j + i < length) {
            var card = participantCard.poolCards[j + i];
            MajiangCard majiangCard = MajiangCard(card);
            Widget touchCard = majiangCard.touchCard(ratio: ratio);
            rowChildren.add(touchCard);
          }
        }
        Widget rowWidget = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: rowChildren,
        );
        columnChildren.add(rowWidget);
      }
      columnChildren = columnChildren.reversed.toList();
      columnChildren.insert(0, const Spacer());
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columnChildren);
    });
  }

  /// 对家河牌
  Widget _buildOpponentTouchCard() {
    double ratio = 0.7;
    int segment = 11;
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      int pos = majiangRoom.opponent(current.value);
      ParticipantCard participantCard = majiangRoom.participantCards[pos];
      int length = participantCard.poolCards.length;
      List<Widget> columnChildren = [];
      for (var i = 0; i < length; i = i + segment) {
        List<Widget> rowChildren = [];
        for (int j = 0; j < segment; ++j) {
          if (j + i < length) {
            var card = participantCard.poolCards[j + i];
            MajiangCard majiangCard = MajiangCard(card);
            Widget opponentTouchCard =
                majiangCard.opponentTouchCard(ratio: ratio);
            rowChildren.add(opponentTouchCard);
          }
        }
        Widget rowWidget = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: rowChildren,
        );
        columnChildren.add(rowWidget);
      }
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columnChildren);
    });
  }

  Widget _buildCardPool() {
    double poolWidth = 180;
    double poolHeight = 400;
    double bodyWidth = appDataProvider.secondaryBodyWidth;
    double bodyHeight =
        appDataProvider.portraitSize.height - appDataProvider.toolbarHeight;
    return Stack(children: [
      //对家
      AlignPositioned(
        alignment: Alignment.topLeft,
        dx: (bodyWidth * 0.7 - poolHeight) / 2,
        dy: 0.0,
        touch: Touch.inside,
        child: Container(
          color: Colors.red,
          height: poolWidth,
          width: poolHeight,
          child: _buildOpponentTouchCard(),
        ),
      ),
      //上家
      AlignPositioned(
        alignment: Alignment.topLeft,
        dx: 0.0,
        dy: (bodyHeight * 0.65 - poolHeight) / 2,
        touch: Touch.inside,
        child: Container(
          color: Colors.cyan,
          height: poolHeight,
          width: poolWidth,
          child: _buildPreviousTouchCard(),
        ),
      ),
      AlignPositioned(
        alignment: Alignment.bottomLeft,
        dx: (bodyWidth * 0.7 - poolHeight) / 2,
        dy: 0.0,
        touch: Touch.inside,
        child: Container(
          color: Colors.yellow,
          height: poolWidth,
          width: poolHeight,
          child: _buildTouchCard(),
        ),
      ),
      AlignPositioned(
        alignment: Alignment.topRight,
        dx: 0.0,
        dy: (bodyHeight * 0.65 - poolHeight) / 2,
        touch: Touch.inside,
        child: Container(
          color: Colors.white,
          height: poolHeight,
          width: poolWidth,
          child: _buildNextTouchCard(),
        ),
      ),
    ]);
  }

  Widget _buildDesktop() {
    MajiangRoom? majiangRoom = this.majiangRoom.value;
    if (majiangRoom == null) {
      return nilBox;
    }
    int pos = current.value;
    ParticipantCard participantCard = majiangRoom.participantCards[pos];
    pos = majiangRoom.next(current.value);
    ParticipantCard nextParticipantCard = majiangRoom.participantCards[pos];
    pos = majiangRoom.previous(current.value);
    ParticipantCard previousParticipantCard = majiangRoom.participantCards[pos];
    pos = majiangRoom.opponent(current.value);
    ParticipantCard opponentParticipantCard = majiangRoom.participantCards[pos];
    double bodyWidth = appDataProvider.secondaryBodyWidth;
    double bodyHeight =
        appDataProvider.portraitSize.height - appDataProvider.toolbarHeight;
    return Column(children: [
      SizedBox(
          height: bodyHeight * 0.15,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(
              width: 10.0,
            ),
            IconTextButton(
              label: opponentParticipantCard.name,
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
            width: bodyWidth * 0.15,
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const SizedBox(
                width: 10.0,
              ),
              IconTextButton(
                label: previousParticipantCard.name,
                icon: previousParticipantCard.avatarWidget!,
                onPressed: null,
              ),
              const SizedBox(
                width: 10.0,
              ),
              Expanded(
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: _buildPreviousHand())),
              const SizedBox(
                width: 30.0,
              ),
            ]),
          ),
          Expanded(
              child: Container(
            child: _buildCardPool(),
          )),
          SizedBox(
            width: bodyWidth * 0.15,
            child: Row(children: [
              const SizedBox(
                width: 30.0,
              ),
              Expanded(child: _buildNextHand()),
              const SizedBox(
                width: 10.0,
              ),
              IconTextButton(
                label: nextParticipantCard.name,
                icon: nextParticipantCard.avatarWidget!,
                onPressed: null,
              ),
              const SizedBox(
                width: 10.0,
              ),
            ]),
          ),
        ],
      )),
      SizedBox(
          height: bodyHeight * 0.2,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(
              width: 10.0,
            ),
            IconTextButton(
              label: participantCard.name,
              icon: participantCard.avatarWidget!,
              onPressed: null,
            ),
            const SizedBox(
              width: 10.0,
            ),
            Expanded(
                child: Align(
                    alignment: Alignment.centerRight, child: _buildHandCard())),
            const SizedBox(
              width: 30.0,
            ),
          ])),
    ]);
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
            peerIds.assign(myself.peerId!);
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
    List<ParticipantCard> participantCards = [];
    for (var peerId in peerIds) {
      Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
      String name =
          linkman == null ? AppLocalizations.t('unknown') : linkman.name;
      ParticipantCard participantCard = ParticipantCard(peerId, name,
          roomEventStreamController: majiangRoomPool.roomEventStreamController);
      participantCard.avatarWidget =
          linkman == null ? AppImage.mdAppImage : linkman.avatarImage;
      participantCard.avatarWidget ??= AppImage.mdAppImage;
      participantCards.add(participantCard);
    }
    if (peerIds.length < 4) {
      for (int i = 0; i < 4 - peerIds.length; i++) {
        ParticipantCard participantCard = ParticipantCard(
            'robot$i', '${AppLocalizations.t('robot')}$i',
            robot: true,
            roomEventStreamController:
                majiangRoomPool.roomEventStreamController);
        participantCards.add(participantCard);
      }
    }
    majiangRoom.value =
        await majiangRoomPool.createRoom(name, participantCards);
    current.value = majiangRoom.value!.current;
  }

  Widget _buildEventActionWidget(BuildContext context) {
    ButtonStyle style = StyleUtil.buildButtonStyle();
    ButtonStyle mainStyle = StyleUtil.buildButtonStyle(
        backgroundColor: myself.primary, elevation: 10.0);
    return Container(
        child: Padding(
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
                    child: CommonAutoSizeText(AppLocalizations.t('Cancel'))),
                TextButton(
                    style: mainStyle,
                    onPressed: () {
                      Navigator.pop(context);
                      String name = textEditingController.text;
                      if (name.isNotEmpty) {
                        createRoom(name);
                      }
                    },
                    child: CommonAutoSizeText(AppLocalizations.t('Ok'))),
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    var majiangMain = Obx(() {
      MajiangRoom? majiangRoom = this.majiangRoom.value;
      List<Widget>? rightWidgets = [
        IconButton(
            tooltip: AppLocalizations.t('New majiang room'),
            onPressed: () {
              _createMajiangRoom(context);
            },
            icon: const Icon(Icons.new_label)),
        IconButton(
            tooltip: AppLocalizations.t('New majiang card'),
            onPressed: majiangRoom != null
                ? () {
                    majiangRoom.play();
                  }
                : null,
            icon: const Icon(Icons.newspaper_outlined)),
        IconButton(
            tooltip: AppLocalizations.t('Next participant'),
            onPressed: majiangRoom != null
                ? () {
                    int next = majiangRoom.next(current.value);
                    current.value = next;
                  }
                : null,
            icon: const Icon(Icons.next_plan_outlined)),
      ];

      String? title = majiangRoom?.name;
      return AppBarView(
          title: title ?? this.title,
          withLeading: true,
          rightWidgets: rightWidgets,
          child: Stack(
            fit: StackFit.expand,
            children: [
              backgroundImage.get('background')!,
              _buildDesktop(),
            ],
          ));
    });

    return majiangMain;
  }
}
