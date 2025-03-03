import 'package:colla_chat/pages/game/mahjong/base/room_event.dart';
import 'package:colla_chat/pages/game/mahjong/base/round_participant.dart';
import 'package:colla_chat/pages/game/mahjong/component/action_area_component.dart';
import 'package:colla_chat/pages/game/mahjong/component/hand_area_component.dart';
import 'package:colla_chat/pages/game/mahjong/component/participant_area_component.dart';
import 'package:colla_chat/pages/game/mahjong/component/setting_area_component.dart';
import 'package:colla_chat/pages/game/mahjong/component/stock_area_component.dart';
import 'package:colla_chat/pages/game/mahjong/component/waste_area_component.dart';
import 'package:colla_chat/pages/game/mahjong/room_controller.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

/// [MahjongFlameGame] 使用flame engine渲染画布和所有的节点
/// FlameGame包含world对象，camera表示看world的方式
/// camera包含backdrop，viewport和viewfinder，Viewport也是组件，可以加入其他组件
/// Viewfinder控制viewport的缩放，角度，backdrop是背景组件
/// Camera.follow()，Camera.stop()，Camera.moveBy()，Camera.moveTo()，Camera.setBounds()
class MahjongFlameGame extends FlameGame
    with
        ScrollDetector,
        ScaleDetector,
        HasCollisionDetection,
        HasKeyboardHandlerComponents {
  static const double opponentHeightRadio = 0.16;
  static const double opponentWasteHeightRadio = 0.26;
  static const double selfWasteHeightRadio = 0.26;
  static const double selfHeightRadio = 0.2;

  static const double stockHeightRadio = 0.12;
  static const double stockWidthRadio = 0.38;

  static const double previousWidthRadio = 0.08;
  static const double previousHandWidthRadio = 0.08;
  static const double previousWasteWidthRadio = 0.15;
  static const double opponentWasteWidthRadio = 0.38;
  static const double selfWasteWidthRadio = 0.38;
  static const double nextWasteWidthRadio = 0.15;
  static const double nextHandWidthRadio = 0.08;
  static const double nextWidthRadio = 0.08;

  static const double previousHeightRadio = 0.64;

  static const double opponentWidthRadio = 0.16;
  static const double opponentHandWidthRadio = 0.68;
  static const double settingWidthRadio = 0.16;

  static const double nextHeightRadio = 0.64;

  static const double selfWidthRadio = 0.16;
  static const double selfHandWidthRadio = 0.84;

  MahjongFlameGame() {
    _init();
  }

  late final SpriteComponent backgroundComponent;

  static const zoomPerScrollUnit = 0.02;

  late double startZoom;

  ParticipantAreaComponent opponentParticipantAreaComponent =
      ParticipantAreaComponent(AreaDirection.opponent);
  HandAreaComponent opponentHandAreaComponent =
      HandAreaComponent(AreaDirection.opponent);
  WasteAreaComponent opponentWasteAreaComponent =
      WasteAreaComponent(AreaDirection.opponent);
  SettingAreaComponent settingAreaComponent = SettingAreaComponent();
  ParticipantAreaComponent previousParticipantAreaComponent =
      ParticipantAreaComponent(AreaDirection.previous);
  HandAreaComponent previousHandAreaComponent =
      HandAreaComponent(AreaDirection.previous);
  WasteAreaComponent previousWasteAreaComponent =
      WasteAreaComponent(AreaDirection.previous);
  WasteAreaComponent selfWasteAreaComponent =
      WasteAreaComponent(AreaDirection.self);
  ParticipantAreaComponent nextParticipantAreaComponent =
      ParticipantAreaComponent(AreaDirection.next);
  HandAreaComponent nextHandAreaComponent =
      HandAreaComponent(AreaDirection.next);
  WasteAreaComponent nextWasteAreaComponent =
      WasteAreaComponent(AreaDirection.next);
  ParticipantAreaComponent selfParticipantAreaComponent =
      ParticipantAreaComponent(AreaDirection.self);
  HandAreaComponent selfHandAreaComponent =
      HandAreaComponent(AreaDirection.self);
  StockAreaComponent stockAreaComponent = StockAreaComponent();
  ActionAreaComponent? actionAreaComponent;

  // @override
  // bool debugMode = true;

  _init() {
    camera = CameraComponent.withFixedResolution(
        width: roomController.width, height: roomController.height);
    allOutstandingActions.roomEventActions.length;
  }

  @override
  Color backgroundColor() {
    return Colors.white.withAlpha(0);
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
    // final backgroundImage = await images.load('mahjong/background.webp');
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
    world.add(stockAreaComponent);
  }

  reloadSelf() {
    selfParticipantAreaComponent.loadRoundParticipant();
    selfWasteAreaComponent.loadWastePile();
    selfHandAreaComponent.loadHandPile();

    loadActionArea();
  }

  reloadOpponent() {
    opponentParticipantAreaComponent.loadRoundParticipant();
    opponentWasteAreaComponent.loadWastePile();
    opponentHandAreaComponent.loadHandPile();
  }

  reloadNext() {
    nextParticipantAreaComponent.loadRoundParticipant();
    nextHandAreaComponent.loadHandPile();
    nextWasteAreaComponent.loadWastePile();
  }

  reloadPrevious() {
    previousHandAreaComponent.loadHandPile();
    previousWasteAreaComponent.loadWastePile();
    previousParticipantAreaComponent.loadRoundParticipant();
  }

  reloadStock() {
    stockAreaComponent.loadStockPile();
  }

  reload() {
    reloadSelf();
    reloadOpponent();
    reloadNext();
    reloadPrevious();
    reloadStock();
  }

  loadActionArea() {
    if (actionAreaComponent != null) {
      world.remove(actionAreaComponent!);
      actionAreaComponent = null;
    }
    RoundParticipant? roundParticipant = roomController
        .getRoundParticipant(roomController.selfParticipantDirection.value);
    Map<RoomEventAction, Set<int>>? outstandingActions =
        roundParticipant?.outstandingActions.value;
    if (outstandingActions == null || outstandingActions.isEmpty) {
    } else {
      actionAreaComponent = ActionAreaComponent();
      actionAreaComponent!.loadSpriteButton();
      world.add(actionAreaComponent!);
    }
  }
}

final MahjongFlameGame mahjongFlameGame = MahjongFlameGame();
