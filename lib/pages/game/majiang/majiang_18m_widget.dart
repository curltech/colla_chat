import 'dart:convert';
import 'dart:ui' as ui;

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/base/json_editor.dart';
import 'package:colla_chat/pages/base/json_viewer.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/component/node_relationship_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/pages/game/model/widget/model_node_edit_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 18m麻将游戏
class Majiang18mWidget extends StatelessWidget with TileDataMixin {
  ModelFlameGame? modelFlameGame;

  Majiang18mWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'majiang_18m';

  @override
  IconData get iconData => Icons.model_training_outlined;

  @override
  String get title => 'Majiang 18m';

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return AppBarView(
          title: title,
          withLeading: true,
          child: GameWidget(game: MajiangFlameGame()));
    });
  }
}
