import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/base/subject.dart';
import 'package:get/get.dart';

class ModelProjectController {
  /// 元模型
  final Rx<Project?> metaProject = Rx<Project?>(null);

  /// 当前模型
  final Rx<Project?> project = Rx<Project?>(null);

  /// 当前模型的文件名
  final Rx<String?> filename = Rx<String?>(null);
  final Rx<String?> currentSubjectName = Rx<String?>(null);
  final Rx<ModelNode?> selected = Rx<ModelNode?>(null);

  final RxBool addSubjectStatus = false.obs;
  final Rx<NodeType?> addNodeStatus = Rx<NodeType?>(null);
  final RxBool addRelationshipStatus = false.obs;

  Subject? getCurrentSubject() {
    if (project.value != null && currentSubjectName.value != null) {
      return project.value!.subjects[currentSubjectName.value];
    }
    return null;
  }

  ModelNode? getModelNode(String id) {
    if (project.value != null) {
      for (Subject subject in project.value!.subjects.values) {
        return subject.modelNodes[id];
      }
    }

    return null;
  }
}

final ModelProjectController modelProjectController = ModelProjectController();
