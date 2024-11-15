import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

/// [MajiangFlameGame] 使用flame engine渲染画布和所有的节点
/// FlameGame包含world对象，camera表示看world的方式
/// camera包含backdrop，viewport和viewfinder，Viewport也是组件，可以加入其他组件
/// Viewfinder控制viewport的缩放，角度，backdrop是背景组件
/// Camera.follow()，Camera.stop()，Camera.moveBy()，Camera.moveTo()，Camera.setBounds()
class MajiangFlameGame extends FlameGame
    with
        TapCallbacks,
        ScrollDetector,
        ScaleDetector,
        HasCollisionDetection,
        HasKeyboardHandlerComponents {
  MajiangFlameGame();

  late final SpriteComponent backgroundComponent;

  static const zoomPerScrollUnit = 0.02;

  late double startZoom;

  // @override
  // bool debugMode = true;

  @override
  Color backgroundColor() {
    return Colors.white.withOpacity(0.0);
  }

  double clampZoom(double zoom, {num lowerLimit = 0.05, num upperLimit = 3.0}) {
    if (zoom < 0.05) {
      zoom = 0.05;
    }
    if (zoom > 3.0) {
      zoom = 3.0;
    }
    return zoom;
  }

  @override
  void onScroll(PointerScrollInfo info) {
    double zoom = camera.viewfinder.zoom +
        info.scrollDelta.global.y.sign * zoomPerScrollUnit;

    camera.viewfinder.zoom = clampZoom(zoom);
  }

  @override
  void onScaleStart(_) {
    startZoom = camera.viewfinder.zoom;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    final currentScale = info.scale.global;
    if (!currentScale.isIdentity()) {
      var zoom = startZoom * currentScale.y;
      zoom = clampZoom(zoom);
      camera.viewfinder.zoom = zoom;
    } else {
      final delta = info.delta.global;
      camera.viewfinder.position.translate(-delta.x, -delta.y);
    }
  }

  @override
  Future<void> onLoad() async {
    final backgroundImage = await images.load('majiang/background.webp');
    backgroundComponent = SpriteComponent(sprite: Sprite(backgroundImage));
    world.add(backgroundComponent);

    return super.onLoad();
  }

  @override
  Future<void> onLongTapDown(TapDownEvent event) async {
    Vector2 globalPosition = event.devicePosition;
    Vector2 worldPosition = camera.globalToLocal(globalPosition);
    camera.moveTo(worldPosition);
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    Vector2 globalPosition = event.devicePosition;
    Vector2 widgetPosition = event.canvasPosition;
    Vector2 localPosition = event.localPosition;
    Vector2 worldPosition = camera.globalToLocal(widgetPosition);
    Vector2 cameraPosition = camera.viewfinder.position;
  }
}
