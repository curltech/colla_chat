import 'package:colla_chat/pages/majiang/card.dart';
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

  @override
  Widget build(BuildContext context) {
    var majiangMain =
        AppBarView(title: title, child: backgroundImage.get('background')!);

    return majiangMain;
  }
}
