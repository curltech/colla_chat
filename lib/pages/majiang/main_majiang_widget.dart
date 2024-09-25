import 'package:align_positioned/align_positioned.dart';
import 'package:colla_chat/pages/majiang/card.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
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

  final MajiangRoom majiangRoom = MajiangRoom();

  /// 对家手牌
  Widget _buildOpponentHand() {
    return Obx(() {
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
      List<Widget> children = [];
      ParticipantCard participantCard = majiangRoom.participantCards[2];
      for (var card in participantCard.poolCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget opponentTouchCard = majiangCard.opponentTouchCard();
        children.add(opponentTouchCard);
      }
      return Container(
          child: Row(
        children: children,
      ));
    });
  }

  /// 上家手牌
  Widget _buildLeftSideHand() {
    return Obx(() {
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
      List<Widget> children = [];
      ParticipantCard participantCard = majiangRoom.participantCards[3];
      for (var card in participantCard.poolCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget leftSideTouchCard = majiangCard.leftSideTouchCard();
        children.add(leftSideTouchCard);
      }
      return Container(
          child: Row(
        children: children,
      ));
    });
  }

  /// 下家手牌
  Widget _buildRightSideHand() {
    return Obx(() {
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
      List<Widget> children = [];
      ParticipantCard participantCard = majiangRoom.participantCards[1];

      for (var card in participantCard.poolCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget rightSideTouchCard = majiangCard.rightSideTouchCard();
        children.add(rightSideTouchCard);
      }
      return Container(
          child: Row(
        children: children,
      ));
    });
  }

  /// 自己的手牌
  Widget _buildHandCard() {
    return Obx(() {
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
      List<Widget> columnChildren = [];
      List<Widget> rowChildren = [];
      ParticipantCard participantCard = majiangRoom.participantCards[0];
      int i = 0;
      for (var card in participantCard.poolCards) {
        MajiangCard majiangCard = MajiangCard(card);
        Widget touchCard = majiangCard.touchCard(ratio: 0.8);
        rowChildren.add(touchCard);
        int reminder = i % 11;
        if (reminder == 10 || i == participantCard.poolCards.length-1) {
          Widget row = Row(
            children: rowChildren,
          );
          columnChildren.add(row);
          rowChildren = [];
        }
        i++;
      }
      return Container(
        child: Wrap(children: columnChildren),
      );
    });
  }

  Widget _buildIncomingCard() {
    return Obx(() {
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

  @override
  Widget build(BuildContext context) {
    List<Widget>? rightWidgets = [
      IconButton(
          onPressed: () {
            majiangRoom.play();
          },
          icon: const Icon(Icons.new_label))
    ];
    var majiangMain = AppBarView(
        title: title,
        withLeading: true,
        rightWidgets: rightWidgets,
        child: Stack(
          fit: StackFit.expand,
          children: [backgroundImage.get('background')!, _buildDesktop()],
        ));

    return majiangMain;
  }
}
