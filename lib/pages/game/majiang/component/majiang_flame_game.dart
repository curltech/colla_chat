import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/component/next_hand_area_component.dart';
import 'package:colla_chat/pages/game/majiang/component/next_participant_area_component.dart';
import 'package:colla_chat/pages/game/majiang/component/next_waste_area_component.dart';
import 'package:colla_chat/pages/game/majiang/component/opponent_hand_area_component.dart';
import 'package:colla_chat/pages/game/majiang/component/opponent_participant_area_component.dart';
import 'package:colla_chat/pages/game/majiang/component/opponent_waste_area_component.dart';
import 'package:colla_chat/pages/game/majiang/component/previous_hand_area_component.dart';
import 'package:colla_chat/pages/game/majiang/component/previous_participant_area_component.dart';
import 'package:colla_chat/pages/game/majiang/component/previous_waste_area_component.dart';
import 'package:colla_chat/pages/game/majiang/component/self_hand_area_component.dart';
import 'package:colla_chat/pages/game/majiang/component/self_participant_area_component.dart';
import 'package:colla_chat/pages/game/majiang/component/self_waste_area_component.dart';
import 'package:colla_chat/pages/game/majiang/component/setting_area_component.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
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
  static const double width = 1110;
  static const double height = 655;

  static const double opponentHeightRadio = 0.16;
  static const double opponentWidthRadio = 0.16;
  static const double opponentHandWidthRadio = 0.68;
  static const double settingWidthRadio = 0.16;

  static const double selfHeightRadio = 0.2;
  static const double selfWidthRadio = 0.16;
  static const double selfHandWidthRadio = 0.84;

  static const double nextHeightRadio = 0.64;
  static const double opponentWasteHeightRadio = 0.3;
  static const double selfWasteHeightRadio = 0.3;

  static const double previousHeightRadio = 0.64;
  static const double previousWidthRadio = 0.08;
  static const double previousHandWidthRadio = 0.08;
  static const double previousWasteWidthRadio = 0.16;

  static const double nextWidthRadio = 0.08;
  static const double nextHandWidthRadio = 0.08;
  static const double nextWasteWidthRadio = 0.16;

  static const double opponentWasteWidthRadio = 0.36;
  static const double selfWasteWidthRadio = 0.36;

  static double x(double x) {
    return -MajiangFlameGame.width * 0.5 + x;
  }

  static double y(double y) {
    return -MajiangFlameGame.height * 0.5 + y;
  }

  MajiangFlameGame()
      : super(
            camera: CameraComponent.withFixedResolution(
                width: width, height: height));

  Room? room;

  late final SpriteComponent backgroundComponent;

  static const zoomPerScrollUnit = 0.02;

  late double startZoom;

  OpponentParticipantAreaComponent opponentParticipantAreaComponent =
      OpponentParticipantAreaComponent();
  OpponentHandAreaComponent opponentHandAreaComponent =
      OpponentHandAreaComponent();
  OpponentWasteAreaComponent opponentWasteAreaComponent =
      OpponentWasteAreaComponent();
  SettingAreaComponent settingAreaComponent = SettingAreaComponent();
  PreviousParticipantAreaComponent previousParticipantAreaComponent =
      PreviousParticipantAreaComponent();
  PreviousHandAreaComponent previousHandAreaComponent =
      PreviousHandAreaComponent();
  PreviousWasteAreaComponent previousWasteAreaComponent =
      PreviousWasteAreaComponent();
  SelfWasteAreaComponent selfWasteAreaComponent = SelfWasteAreaComponent();
  NextParticipantAreaComponent nextParticipantAreaComponent =
      NextParticipantAreaComponent();
  NextHandAreaComponent nextHandAreaComponent = NextHandAreaComponent();
  NextWasteAreaComponent nextWasteAreaComponent = NextWasteAreaComponent();
  SelfParticipantAreaComponent selfParticipantAreaComponent =
      SelfParticipantAreaComponent();
  SelfHandAreaComponent selfHandAreaComponent = SelfHandAreaComponent();

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
    // final backgroundImage = await images.load('majiang/background.webp');
    // backgroundComponent = SpriteComponent(
    //     autoResize: true,
    //     // position: Vector2(0, 0),
    //     anchor: Anchor.center,
    //     // size: Vector2(width, height),
    //     sprite: Sprite(backgroundImage));
    // world.add(backgroundComponent);

    world.add(opponentParticipantAreaComponent);
    world.add(opponentHandAreaComponent);
    world.add(settingAreaComponent);
    world.add(selfParticipantAreaComponent);
    world.add(selfHandAreaComponent);
    world.add(previousParticipantAreaComponent);
    world.add(previousHandAreaComponent);
    world.add(previousWasteAreaComponent);
    world.add(opponentWasteAreaComponent);
    world.add(selfWasteAreaComponent);
    world.add(nextWasteAreaComponent);
    world.add(nextHandAreaComponent);
    world.add(nextParticipantAreaComponent);

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
