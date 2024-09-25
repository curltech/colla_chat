import 'package:align_positioned/align_positioned.dart';
import 'package:colla_chat/pages/majiang/card.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

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

  Widget _buildOpponentHand() {
    List<Widget> children = [];
    ParticipantCard participantCard = majiangRoom.participantCards[2];
    for (var card in participantCard.handCards) {
      MajiangCard majiangCard = MajiangCard(card);
      Widget opponenthand = majiangCard.opponenthand();
      children.add(opponenthand);
    }
    return Center(
        child: Row(
      children: children,
    ));
  }

  Widget _buildOpponentPool() {
    List<Widget> children = [];
    ParticipantCard participantCard = majiangRoom.participantCards[2];
    for (var card in participantCard.poolCards) {
      MajiangCard majiangCard = MajiangCard(card);
      Widget poolcard = majiangCard.poolcard();
      children.add(poolcard);
    }
    return Container(
        child: Row(
      children: children,
    ));
  }

  Widget _buildLeftSide() {
    List<Widget> children = [];
    ParticipantCard participantCard = majiangRoom.participantCards[3];
    int i = 0;
    for (var card in participantCard.handCards) {
      MajiangCard majiangCard = MajiangCard(card);
      Widget sidehand = majiangCard.leftSidehand(clip: i < 12 ? true : false);
      children.add(sidehand);
      i++;
    }
    return Container(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ));
  }

  Widget _buildLeftPool() {
    List<Widget> children = [];
    ParticipantCard participantCard = majiangRoom.participantCards[3];
    for (var card in participantCard.poolCards) {
      MajiangCard majiangCard = MajiangCard(card);
      Widget sidecard = majiangCard.sidecard();
      children.add(sidecard);
    }
    return Container(
        child: Row(
      children: children,
    ));
  }

  Widget _buildRightPool() {
    List<Widget> children = [];
    ParticipantCard participantCard = majiangRoom.participantCards[1];
    for (var card in participantCard.poolCards) {
      MajiangCard majiangCard = MajiangCard(card);
      Widget sidecard = majiangCard.sidecard();
      children.add(sidecard);
    }
    return Container(
        child: Row(
      children: children,
    ));
  }

  Widget _buildRightSide() {
    List<Widget> children = [];
    ParticipantCard participantCard = majiangRoom.participantCards[1];
    int i = 0;
    for (var card in participantCard.handCards) {
      MajiangCard majiangCard = MajiangCard(card);
      Widget sidehand = majiangCard.rightSidehand(clip: i < 12 ? true : false);
      children.add(sidehand);
      i++;
    }
    return Container(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ));
  }

  Widget _buildHandPool() {
    List<Widget> children = [];
    ParticipantCard participantCard = majiangRoom.participantCards[0];
    for (var card in participantCard.poolCards) {
      MajiangCard majiangCard = MajiangCard(card);
      Widget poolcard = majiangCard.poolcard();
      children.add(poolcard);
    }
    return Container(
        child: Row(
      children: children,
    ));
  }

  Widget _buildHandSide() {
    List<Widget> children = [];
    ParticipantCard participantCard = majiangRoom.participantCards[0];
    int i = 0;
    for (var card in participantCard.handCards) {
      MajiangCard majiangCard = MajiangCard(card);
      Widget handcard = majiangCard.handcard();
      children.add(handcard);
      children.add(SizedBox(
        width: i < 12 ? 1.0 : 10.0,
      ));
      i++;
    }
    return Container(
        child: Row(
      children: children,
    ));
  }

  Widget _buildCardPool() {
    double bodyWidth = appDataProvider.secondaryBodyWidth;
    double bodyHeight =
        appDataProvider.portraitSize.height - appDataProvider.toolbarHeight;
    return Stack(children: [
      AlignPositioned(
        child: Container(
          color: Colors.white,
          height: 200,
          width: 400,
        ),
        alignment: Alignment.topLeft,
        dx: (bodyWidth * 0.7 - 400) / 2,
        dy: 0.0,
        touch: Touch.inside,
      ),
      AlignPositioned(
        child: Container(
          color: Colors.white,
          height: 400,
          width: 200,
        ),
        alignment: Alignment.topLeft,
        dx: 0.0,
        dy: (bodyHeight * 0.65-400)/2,
        touch: Touch.inside,
      ),
      AlignPositioned(
        child: Container(
          color: Colors.white,
          height: 200,
          width: 400,
        ),
        alignment: Alignment.bottomLeft,
        dx: (bodyWidth * 0.7 - 400) / 2,
        dy: 0.0,
        touch: Touch.inside,
      ),
      AlignPositioned(
        child: Container(
          color: Colors.white,
          height: 400,
          width: 200,
        ),
        alignment: Alignment.topRight,
        dx: 0.0,
        dy: (bodyHeight * 0.65-400)/2,
        touch: Touch.inside,
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
                child: _buildLeftSide(),
              ),
              Container(
                width: bodyWidth * 0.7,
                // color: Colors.purple,
                child: _buildCardPool(),
              ),
              //     _buildLeftPool(),
              //     _buildOpponentPool(),
              //     _buildRightPool(),
              Expanded(
                  child: Container(
                color: Colors.cyan,
                child: _buildRightSide(),
              )),
            ],
          )),
      // _buildHandPool(),
      Expanded(
          child: Container(
              color: Colors.yellow,
              child: Row(children: [Spacer(), _buildHandSide(), Spacer()]))),
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
