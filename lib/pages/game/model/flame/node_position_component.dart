import 'dart:math';

import 'package:colla_chat/pages/game/model/flame/model_canvas_flame.dart';
import 'package:colla_chat/pages/game/model/flame/node.dart';
import 'package:colla_chat/pages/game/model/flame/node_renderer_widget.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';

/// [NodePositionComponent] 保存节点的位置和大小，是flame引擎的位置组件，可以在画布上拖拽
class NodePositionComponent extends PositionComponent
    with HasGameRef<ModelCanvasFlame> {
  final Vector2 nodeSize;
  final Vector2 nodePosition;
  final double nodePadding;
  final double nodeImageSize;
  final Node node;
  late final NodeSpriteComponent spriteComponent;

  NodePositionComponent({
    required this.nodeSize,
    required this.nodePosition,
    required this.nodePadding,
    required this.node,
    required this.nodeImageSize,
  });

  /// [isUpdated] 检查ui是否被更新
  bool isUpdated = false;

  @override
  Future<void> onLoad() async {
    size = nodeSize;
    position = nodePosition;

    /// add to the world
    spriteComponent = NodeSpriteComponent(
        nodeSize: nodeSize,
        nodePosition: nodePosition,
        nodePadding: nodePadding,
        node: node,
        nodeImageSize: nodeImageSize);
    game.world.add(spriteComponent);
    return super.onLoad();
  }
}

/// [NodeSpriteComponent] 节点在画布上利用flame引擎被渲染
class NodeSpriteComponent extends SpriteComponent
    with HasGameRef<ModelCanvasFlame>, DragCallbacks, TapCallbacks {
  final Vector2 nodeSize;
  final Vector2 nodePosition;
  final double nodePadding;
  final double nodeImageSize;
  final Node node;

  NodeSpriteComponent({
    required this.nodeSize,
    required this.nodePosition,
    required this.nodePadding,
    required this.node,
    required this.nodeImageSize,
  });

  bool isUpdated = false;

  @override
  Future<void> onLoad() async {
    priority = 2;
    size = Vector2.all(nodeImageSize);
    var rng = Random();
    if (node.cachedPosition == null) {
      position = nodePosition +
          Vector2(rng.nextInt((nodePadding * 2).toInt()).toDouble(),
              rng.nextInt((nodePadding * 2).toInt()).toDouble());
    } else {
      position = node.cachedPosition!.toVector2();
    }

    node.cachedPosition = position.toOffset();
    sprite = Sprite(
      transparentImage,
    );

    return super.onLoad();
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    if (game.onNodeTap != null) {
      game.onNodeTap!(node);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isUpdated && node.image != null) {
      isUpdated = true;
      sprite = Sprite(node.image!);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
    node.cachedPosition = position.toOffset();
  }
}
