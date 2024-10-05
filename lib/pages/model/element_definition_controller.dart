import 'dart:ui';

import 'package:colla_chat/pages/model/element_deifinition.dart';
import 'package:get/get.dart';

class ElementDefinitionController {
  final RxMap<ElementDefinition, Offset> elementDefinitions =
      <ElementDefinition, Offset>{}.obs;

  final RxList<RelationshipDefinition> relationshipDefinitions =
      <RelationshipDefinition>[].obs;
}

class ModelProjectController {
  final Rx<String?> name = Rx<String?>(null);
  final Rx<String?> title = Rx<String?>(null);
  final Rx<String?> currentPackageName = Rx<String?>(null);
  final RxMap<String, ElementDefinitionController> packageDefinitionController =
      <String, ElementDefinitionController>{}.obs;
  final Rx<ElementDefinition?> selected = Rx<ElementDefinition?>(null);

  final RxBool addElementStatus = false.obs;
  final RxBool addRelationshipStatus = false.obs;

  ElementDefinitionController? getElementDefinitionController() {
    if (currentPackageName.value != null) {
      return packageDefinitionController[currentPackageName.value];
    }
    return null;
  }
}

final ModelProjectController modelProjectController = ModelProjectController();
