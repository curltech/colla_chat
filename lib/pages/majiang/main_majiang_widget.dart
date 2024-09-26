import 'package:align_positioned/align_positioned.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/majiang/card.dart';
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

  /// 上家手牌
  Widget _buildLeftSideHand() {
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> children = [];
      ParticipantCard participantCard = majiangRoom.participantCards[3];

      for (var card in participantCard.drawingCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget leftSideTouchCard = majiangCard.leftSideTouchCard();
        children.add(leftSideTouchCard);
      }
      for (var card in participantCard.touchCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget leftSideTouchCard = majiangCard.leftSideTouchCard();
        children.add(leftSideTouchCard);
      }
      int i = 0;
      for (var card in participantCard.handCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget leftSideHand =
            majiangCard.leftSideHand(clip: i < 12 ? true : false);
        children.add(leftSideHand);
        i++;
      }
      return Container(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ));
    });
  }

  /// 上家河牌
  Widget _buildLeftTouchCard() {
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> columnChildren = [];
      List<Widget> rowChildren = [];
      ParticipantCard participantCard = majiangRoom.participantCards[3];
      int i = 0;
      for (var card in participantCard.poolCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget leftSideTouchCard = majiangCard.leftSideTouchCard(ratio: 0.8);
        columnChildren.add(leftSideTouchCard);
        int reminder = i % 11;
        if (reminder == 10 || i == participantCard.poolCards.length - 1) {
          Widget row = Column(
            children: columnChildren,
          );
          rowChildren.add(row);
          columnChildren = [];
        }
        i++;
      }
      return Wrap(children: rowChildren);
    });
  }

  /// 下家手牌
  Widget _buildRightSideHand() {
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> children = [];
      ParticipantCard participantCard = majiangRoom.participantCards[1];

      for (var card in participantCard.drawingCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget rightSideTouchCard = majiangCard.rightSideTouchCard();
        children.add(rightSideTouchCard);
      }
      for (var card in participantCard.touchCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget rightSideTouchCard = majiangCard.rightSideTouchCard();
        children.add(rightSideTouchCard);
      }
      int i = 0;
      for (var card in participantCard.handCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget rightSideHand =
            majiangCard.rightSideHand(clip: i < 12 ? true : false);
        children.add(rightSideHand);
        i++;
      }
      return Container(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ));
    });
  }

  /// 下家河牌
  Widget _buildRightSideTouchCard() {
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> columnChildren = [];
      List<Widget> rowChildren = [];
      ParticipantCard participantCard = majiangRoom.participantCards[1];
      int i = 0;
      for (var card in participantCard.poolCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget rightSideTouchCard = majiangCard.rightSideTouchCard(ratio: 0.8);
        columnChildren.add(rightSideTouchCard);
        int reminder = i % 11;
        if (reminder == 10 || i == participantCard.poolCards.length - 1) {
          Widget row = Column(
            children: columnChildren,
          );
          rowChildren.add(row);
          columnChildren = [];
        }
        i++;
      }
      return Wrap(children: rowChildren);
    });
  }

  /// 自己的手牌
  Widget _buildHandCard() {
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> children = [];
      ParticipantCard participantCard = majiangRoom.participantCards[0];
      for (var card in participantCard.drawingCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget touchCard = majiangCard.touchCard();
        children.add(touchCard);
      }
      for (var card in participantCard.touchCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget touchCard = majiangCard.touchCard();
        children.add(touchCard);
      }
      for (var card in participantCard.handCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget handcard = majiangCard.handCard();
        handcard = InkWell(
            onTap: () {
              participantCard.send(card);
            },
            child: handcard);
        children.add(handcard);
        children.add(const SizedBox(
          width: 1.0,
        ));
      }
      return Container(
          child: Row(
        children: children,
      ));
    });
  }

  /// 自己的河牌，碰牌或者杠牌
  Widget _buildTouchCard() {
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> columnChildren = [];
      List<Widget> rowChildren = [];
      ParticipantCard participantCard = majiangRoom.participantCards[0];
      int i = 0;
      for (var card in participantCard.poolCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget touchCard = majiangCard.touchCard(ratio: 0.8);
        rowChildren.add(touchCard);
        int reminder = i % 11;
        if (reminder == 10 || i == participantCard.poolCards.length - 1) {
          Widget row = Row(
            children: rowChildren,
          );
          columnChildren.add(row);
          rowChildren = [];
        }
        i++;
      }
      return Wrap(children: columnChildren);
    });
  }

  /// 对家手牌
  Widget _buildOpponentHand() {
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> children = [];
      ParticipantCard participantCard = majiangRoom.participantCards[2];

      for (var card in participantCard.drawingCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget opponentTouchCard = majiangCard.opponentTouchCard();
        children.add(opponentTouchCard);
      }
      for (var card in participantCard.touchCards) {
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
          child: Row(
        children: children,
      ));
    });
  }

  /// 对家河牌
  Widget _buildOpponentTouchCard() {
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      List<Widget> columnChildren = [];
      List<Widget> rowChildren = [];
      ParticipantCard participantCard = majiangRoom.participantCards[2];
      int i = 0;
      for (var card in participantCard.poolCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget opponentTouchCard = majiangCard.opponentTouchCard(ratio: 0.8);
        rowChildren.add(opponentTouchCard);
        int reminder = i % 11;
        if (reminder == 10 || i == participantCard.poolCards.length - 1) {
          Widget row = Row(
            children: rowChildren,
          );
          columnChildren.add(row);
          rowChildren = [];
        }
        i++;
      }
      return Wrap(
        children: columnChildren,
      );
    });
  }

  Widget _buildIncomingCard() {
    return Obx(() {
      MajiangRoom majiangRoom = this.majiangRoom.value!;
      ParticipantCard participantCard = majiangRoom.participantCards[0];
      var card = participantCard.comingCard.value;
      Widget? handcard;
      if (card != null) {
        MajiangCard majiangCard = MajiangCard(card);
        handcard = majiangCard.handCard();
        handcard = InkWell(
            onTap: () {
              participantCard.send(card);
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
          child: _buildLeftTouchCard(),
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
          child: _buildRightSideTouchCard(),
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
                child: _buildLeftSideHand(),
              ),
              Container(
                width: bodyWidth * 0.7,
                // color: Colors.purple,
                child: _buildCardPool(),
              ),
              Expanded(
                  child: Container(
                color: Colors.cyan,
                child: _buildRightSideHand(),
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
                                  majiangRoom.value =
                                      MajiangRoom(name, peerIds);
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
