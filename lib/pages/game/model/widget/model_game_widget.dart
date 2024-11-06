import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/widget/model_node_edit_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// [ModelGameWidget] flutter的画布组件，内含ModelCanvasFlame的实现组件
class ModelGameWidget<T extends Node> extends StatefulWidget {
  final ModelNodeEditWidget modelNodeEditWidget = ModelNodeEditWidget();

  ModelGameWidget({
    super.key,
  }) {
    indexWidgetProvider.define(modelNodeEditWidget);
  }

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
