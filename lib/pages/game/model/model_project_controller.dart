import 'dart:ui';

import 'package:colla_chat/pages/game/model/flame/model_canvas_controller.dart';
import 'package:colla_chat/pages/game/model/flame/node.dart';
import 'package:colla_chat/pages/game/model/meta_model_node.dart';
import 'package:get/get.dart';

class ModelProjectController {
  final Rx<String?> name = Rx<String?>(null);
  final Rx<String?> title = Rx<String?>(null);
  final Rx<String?> currentPackageName = Rx<String?>(null);
  final RxMap<String, ModelCanvasController> packageModelCanvasController =
      <String, ModelCanvasController>{}.obs;
  final Rx<MetaModelNode?> selected = Rx<MetaModelNode?>(null);

  final RxBool addElementStatus = false.obs;
  final RxBool addRelationshipStatus = false.obs;

  ModelCanvasController? getModelCanvasController() {
    if (currentPackageName.value != null) {
      return packageModelCanvasController[currentPackageName.value];
    }
    return null;
  }
}

final ModelProjectController modelProjectController = ModelProjectController();
