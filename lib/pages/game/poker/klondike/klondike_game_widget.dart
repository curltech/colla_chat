import 'package:colla_chat/pages/game/poker/klondike/klondike_game.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class KlondikeGameWidget extends StatelessWidget with TileDataMixin {
  const KlondikeGameWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'klondike_game';

  @override
  IconData get iconData => Icons.catching_pokemon_outlined;

  @override
  String get title => 'Klondike';

  

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: title,
      helpPath: routeName,
      withLeading: true,
      child: GameWidget(game: KlondikeGame()),
    );
  }
}
