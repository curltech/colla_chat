import 'package:align_positioned/align_positioned.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/majiang/card.dart';
import 'package:colla_chat/pages/majiang/participant_card.dart';
import 'package:colla_chat/pages/majiang/room.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
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

  /// 上家手牌
  Widget _buildPreviousHand() {
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> children = [];
      int pos = majiangRoom.previous(current.value);
      ParticipantCard participantCard = majiangRoom.participantCards[pos];

      for (var card in participantCard.allDrawingCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget previousTouchCard = majiangCard.previousTouchCard();
        children.add(previousTouchCard);
      }
      for (var card in participantCard.allTouchCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget previousTouchCard = majiangCard.previousTouchCard();
        children.add(previousTouchCard);
      }
      int i = 0;
      for (var card in participantCard.handCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget previousHand =
            majiangCard.previousHand(clip: i < 12 ? true : false);
        children.add(previousHand);
        i++;
      }
      return Wrap(
        direction: Axis.vertical,
        children: children,
      );
    });
  }

  /// 上家河牌
  Widget _buildPreviousTouchCard() {
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> children = [];
      int pos = majiangRoom.previous(current.value);
      ParticipantCard participantCard = majiangRoom.participantCards[pos];
      for (var card in participantCard.poolCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget previousTouchCard = majiangCard.previousTouchCard(ratio: 0.8);
        children.add(previousTouchCard);
      }
      return Wrap(direction: Axis.vertical, children: children);
    });
  }

  /// 下家手牌
  Widget _buildNextHand() {
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> children = [];
      int pos = majiangRoom.next(current.value);
      ParticipantCard participantCard = majiangRoom.participantCards[pos];

      for (var card in participantCard.allDrawingCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget nextTouchCard = majiangCard.nextTouchCard();
        children.add(nextTouchCard);
      }
      for (var card in participantCard.allTouchCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget nextTouchCard = majiangCard.nextTouchCard();
        children.add(nextTouchCard);
      }
      int i = 0;
      for (var card in participantCard.handCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget nextHand = majiangCard.nextHand(clip: i < 12 ? true : false);
        children.add(nextHand);
        i++;
      }
      return Wrap(
        direction: Axis.vertical,
        children: children,
      );
    });
  }

  /// 下家河牌
  Widget _buildNextTouchCard() {
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> children = [];
      int pos = majiangRoom.next(current.value);
      ParticipantCard participantCard = majiangRoom.participantCards[pos];
      for (var card in participantCard.poolCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget nextTouchCard = majiangCard.nextTouchCard(ratio: 0.8);
        children.add(nextTouchCard);
      }
      return Wrap(direction: Axis.vertical, children: children);
    });
  }

  /// 自己的手牌
  Widget _buildHandCard() {
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
        Widget handcard = majiangCard.handCard(ratio: 0.8);
        handcard = InkWell(
            onTap: () {
              majiangRoom.send(pos, card);
              majiangRoom.sendCheck(pos, card);
            },
            child: handcard);
        children.add(handcard);
        children.add(const SizedBox(
          width: 1.0,
        ));
      }
      return Wrap(
        children: children,
      );
    });
  }

  /// 自己的河牌，碰牌或者杠牌
  Widget _buildTouchCard() {
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> children = [];
      int pos = current.value;
      ParticipantCard participantCard = majiangRoom.participantCards[pos];
      for (var card in participantCard.poolCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget touchCard = majiangCard.touchCard(ratio: 0.8);
        children.add(touchCard);
      }
      return Wrap(children: children);
    });
  }

  /// 对家手牌
  Widget _buildOpponentHand() {
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> children = [];
      int pos = majiangRoom.opponent(current.value);
      ParticipantCard participantCard = majiangRoom.participantCards[pos];

      for (var card in participantCard.allDrawingCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget opponentTouchCard = majiangCard.opponentTouchCard();
        children.add(opponentTouchCard);
      }
      for (var card in participantCard.allTouchCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget opponentTouchCard = majiangCard.opponentTouchCard();
        children.add(opponentTouchCard);
      }
      for (var card in participantCard.handCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget opponentHand = majiangCard.opponentHand();
        children.add(opponentHand);
      }
      return Center(
          child: Wrap(
        children: children,
      ));
    });
  }

  /// 对家河牌
  Widget _buildOpponentTouchCard() {
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> children = [];
      int pos = majiangRoom.opponent(current.value);
      ParticipantCard participantCard = majiangRoom.participantCards[pos];
      int i = 0;
      for (var card in participantCard.poolCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget opponentTouchCard = majiangCard.opponentTouchCard(ratio: 0.8);
        children.add(opponentTouchCard);
      }
      return Wrap(
        children: children,
      );
    });
  }

  Widget _buildIncomingCard() {
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      int pos = current.value;
      ParticipantCard participantCard = majiangRoom.participantCards[pos];
      var card = participantCard.comingCard.value;
      Widget? handcard;
      if (card != null) {
        MajiangCard majiangCard = MajiangCard(card);
        handcard = majiangCard.handCard();
        handcard = InkWell(
            onTap: () {
              majiangRoom.send(pos, card);
            },
            child: handcard);
      }
      return Container(
        child: handcard,
      );
    });
  }

  Widget _buildCardPool() {
    double bodyWidth = appDataProvider.secondaryBodyWidth;
    double bodyHeight =
        appDataProvider.portraitSize.height - appDataProvider.toolbarHeight;
    return Stack(children: [
      //对家
      AlignPositioned(
        alignment: Alignment.topLeft,
        dx: (bodyWidth * 0.7 - 400) / 2,
        dy: 0.0,
        touch: Touch.inside,
        child: Container(
          color: Colors.white,
          height: 200,
          width: 400,
          child: _buildOpponentTouchCard(),
        ),
      ),
      //上家
      AlignPositioned(
        alignment: Alignment.topLeft,
        dx: 0.0,
        dy: (bodyHeight * 0.65 - 400) / 2,
        touch: Touch.inside,
        child: Container(
          color: Colors.white,
          height: 400,
          width: 200,
          child: _buildPreviousTouchCard(),
        ),
      ),
      AlignPositioned(
        alignment: Alignment.bottomLeft,
        dx: (bodyWidth * 0.7 - 400) / 2,
        dy: 0.0,
        touch: Touch.inside,
        child: Container(
          // color: Colors.white,
          height: 200,
          width: 400,
          child: _buildTouchCard(),
        ),
      ),
      AlignPositioned(
        alignment: Alignment.topRight,
        dx: 0.0,
        dy: (bodyHeight * 0.65 - 400) / 2,
        touch: Touch.inside,
        child: Container(
          color: Colors.white,
          height: 400,
          width: 200,
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
    double bodyWidth = appDataProvider.secondaryBodyWidth;
    double bodyHeight =
        appDataProvider.portraitSize.height - appDataProvider.toolbarHeight;
    return Column(children: [
      Container(
          height: bodyHeight * 0.15,
          color: Colors.blue,
          child: Row(children: [Spacer(), _buildOpponentHand(), Spacer()])),
      Container(
          height: bodyHeight * 0.65,
          // color: Colors.green,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: bodyWidth * 0.15,
                color: Colors.cyan,
                child: _buildPreviousHand(),
              ),
              Container(
                width: bodyWidth * 0.7,
                // color: Colors.purple,
                child: _buildCardPool(),
              ),
              Expanded(
                  child: Container(
                color: Colors.cyan,
                child: _buildNextHand(),
              )),
            ],
          )),
      // _buildHandPool(),
      Expanded(
          child: Container(
              color: Colors.yellow,
              child: Row(children: [
                Spacer(),
                _buildHandCard(),
                SizedBox(
                  width: 10.0,
                ),
                _buildIncomingCard(),
                Spacer()
              ]))),
    ]);
  }

  TextEditingController textEditingController = TextEditingController();
  List<String> peerIds = [];

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

  void createRoom(String name) {
    List<ParticipantCard> participantCards = [];
    for (var peerId in peerIds) {
      participantCards.add(ParticipantCard(peerId,
          roomEventStreamController:
              majiangRoomPool.roomEventStreamController));
    }
    if (peerIds.length < 4) {
      for (int i = 0; i < 4 - peerIds.length; i++) {
        ParticipantCard participantCard = ParticipantCard('robot$i',
            robot: true,
            roomEventStreamController:
                majiangRoomPool.roomEventStreamController);
        participantCards.add(participantCard);
      }
    }
    majiangRoom.value = majiangRoomPool.createRoom(name, participantCards);
    current.value = majiangRoom.value!.current;
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
            children: [backgroundImage.get('background')!, _buildDesktop()],
          ));
    });

    return majiangMain;
  }
}
