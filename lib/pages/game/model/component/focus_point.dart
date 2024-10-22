import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart' as mat;

/// [FocusPoint] 画布中心聚焦组件，支持画布的移动，放大
class FocusPoint extends PositionComponent
    with HasGameReference<ModelFlameGame>, CollisionCallbacks {
  FocusPoint({super.position, Vector2? size, super.key})
      : super(
            size: size ?? Vector2.all(50), anchor: Anchor.center, priority: 2);

  /// 中心移动的速度
  static const double speed = 300;

  /// this is to position the test in the center
  static final TextPaint textRenderer = TextPaint(
    style: const mat.TextStyle(color: mat.Colors.white70, fontSize: 12),
  );

  final Vector2 velocity = Vector2.zero();
  late final TextComponent positionText;
  late final Vector2 textPosition;
  late final maxPosition = Vector2.all(game.width + 25);
  late final minPosition = Vector2.zero() + Vector2.all(25);
  int consumed = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    positionText = TextComponent(
      textRenderer: textRenderer,
      position: (size / 2)..y = size.y / 2 + 30,
      anchor: Anchor.center,
    );
    //add(positionText);
    position = Vector2(game.width / 2, game.width / 2);
    add(
      CircleHitbox()
        ..paint = hitboxPaint
        ..renderShape = true,
    );
  }

  final mat.Paint hitboxPaint = BasicPalette.transparent.paint()
    ..style = mat.PaintingStyle.stroke;
  final mat.Paint dotPaint = BasicPalette.red.paint()
    ..style = mat.PaintingStyle.stroke;

  @override
  void update(double dt) {
    super.update(dt);
    final deltaPosition = velocity * (speed * dt);
    position.add(deltaPosition);
    position.clamp(minPosition, maxPosition);
    size = Vector2(50, 50);
    positionText.text = '(${x.toInt()}, ${y.toInt()})';
    position = (game.modelWorldController.scrollX != null &&
            game.modelWorldController.scrollY != null)
        ? Vector2(game.modelWorldController.scrollX!,
            game.modelWorldController!.scrollY!)
        : position;
    // print(game.camera.);
  }
}
