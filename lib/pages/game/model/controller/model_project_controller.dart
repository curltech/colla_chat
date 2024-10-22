import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/controller/model_world_controller.dart';
import 'package:get/get.dart';

class ModelProjectController {
  final Rx<String?> name = Rx<String?>(null);
  final Rx<String?> currentSubjectName = Rx<String?>(null);
  final RxMap<String, ModelWorldController> subjectModelWorldController =
      <String, ModelWorldController>{}.obs;
  final Rx<ModelNode?> selected = Rx<ModelNode?>(null);

  final RxBool addNodeStatus = false.obs;
  final RxBool addRelationshipStatus = false.obs;

  ModelWorldController? getModelWorldController() {
    if (currentSubjectName.value != null) {
      return subjectModelWorldController[currentSubjectName.value];
    }
    return null;
  }
}

final ModelProjectController modelProjectController = ModelProjectController();
