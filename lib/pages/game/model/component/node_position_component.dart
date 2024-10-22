import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:flame/components.dart';

/// [NodePositionComponent] 保存节点的位置和大小，是flame引擎的位置组件，可以在画布上拖拽
class NodePositionComponent extends RectangleComponent
    with HasGameRef<ModelFlameGame> {
  final double padding;
  final double imageSize;
  final Node node;

  NodePositionComponent({
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority,
    super.paint,
    super.paintLayers,
    super.key,
    required this.padding,
    required this.node,
    required this.imageSize,
  });

  @override
  Future<void> onLoad() async {
    if (node.image != null) {
      SpriteComponent spriteComponent =
          SpriteComponent(sprite: Sprite(node.image!));
      add(spriteComponent);
    } else {
      if (node is ModelNode) {
        ModelNode metaModelNode = node as ModelNode;
        String text = '';
        for (var entry in metaModelNode.attributes.entries) {
          String name = entry.key;
          Type typ = entry.value;
          text += '${typ.toString()} $name\n';
        }
        add(TextBoxComponent(
          text: text,
          position: Vector2(0, 100),
        ));
        text = '';
        for (var method in metaModelNode.methods) {
          text += '$method\n';
        }
        add(TextBoxComponent(
          text: text,
          position: Vector2(0, 200),
        ));
      }
    }
  }
}
