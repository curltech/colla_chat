import 'dart:math';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// [ModelGameWidget] flutter的画布组件，内含ModelCanvasFlame的实现组件
class ModelGameWidget<T extends Node> extends StatefulWidget {
  const ModelGameWidget({
    super.key,
  });

  @override
  State<ModelGameWidget> createState() => _ModelGameWidgetState();
}

class _ModelGameWidgetState extends State<ModelGameWidget> {
  late int length;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ModelFlameGame modelFlameGame = ModelFlameGame();
    return GameWidget(
      game: modelFlameGame,
    );
  }
}
