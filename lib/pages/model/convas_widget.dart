import 'package:colla_chat/pages/model/element_definition_widget.dart';
import 'package:colla_chat/pages/model/element_deifinition.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/context_util.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ElementDefinitionController {
  final RxMap<ElementDefinition, Offset> elementDefinitions =
      <ElementDefinition, Offset>{}.obs;

  final RxMap<RelationshipDefinition, Offset> relationshipDefinition =
      <RelationshipDefinition, Offset>{}.obs;
}

class ElementDefinitionControllers {
  final Rx<String?> packageName = Rx<String?>(null);
  final RxMap<String, ElementDefinitionController> packageDefinitionController =
      <String, ElementDefinitionController>{}.obs;
  final Rx<ElementDefinition?> selected = Rx<ElementDefinition?>(null);

  final RxBool addElementStatus = false.obs;

  ElementDefinitionController? getElementDefinitionController() {
    if (packageName.value != null) {
      return packageDefinitionController[packageName.value];
    }
    return null;
  }
}

final ElementDefinitionControllers elementDefinitionControllers =
    ElementDefinitionControllers();

/// 画布
class CanvasWidget extends StatelessWidget {
  final TransformationController transformationController =
      TransformationController();
  final GlobalKey _key = GlobalKey();

  CanvasWidget({super.key});

  Widget _buildDragTargetWidget(BuildContext context, Offset offset) {
    DragTarget dragTarget = DragTarget<ElementDefinition>(
      builder: (context, candidateItems, rejectedItems) {
        return this;
      },
      onAcceptWithDetails: (details) {
        ElementDefinition elementDefinition = details.data;
        ElementDefinitionController? elementDefinitionController =
            elementDefinitionControllers.getElementDefinitionController();
        if (elementDefinitionController != null) {
          elementDefinitionController.elementDefinitions[elementDefinition] =
              offset;
        }
      },
    );

    return dragTarget;
  }

  Widget _buildDraggableElementWidget(
      BuildContext context, ElementDefinition elementDefinition) {
    Widget child =
        ElementDefinitionWidget(elementDefinition: elementDefinition);
    Draggable<ElementDefinition> draggable = Draggable<ElementDefinition>(
      // dragAnchorStrategy: pointerDragAnchorStrategy,
      ignoringFeedbackSemantics: false,
      feedback: child,
      onDragStarted: () {},
      onDragEnd: (DraggableDetails detail) {
        ElementDefinitionController? elementDefinitionController =
            elementDefinitionControllers.getElementDefinitionController();
        if (elementDefinitionController != null) {
          Offset? offset = ContextUtil.getOffset(_key);
          if (offset != null) {
            elementDefinitionController.elementDefinitions[elementDefinition] =
                Offset(
                    detail.offset.dx - offset.dx, detail.offset.dy - offset.dy);
          }
        }

        // _buildDragTargetWidget(context, detail.offset);
      },
      child: child,
    );

    return draggable;
  }

  Widget _buildElementDefinitionWidget(BuildContext context) {
    return Obx(() {
      ElementDefinitionController? elementDefinitionController =
          elementDefinitionControllers.getElementDefinitionController();
      if (elementDefinitionController == null) {
        return nilBox;
      }
      List<Widget> children = [];
      for (var entry
          in elementDefinitionController.elementDefinitions.entries) {
        ElementDefinition elementDefinition = entry.key;
        Offset offset = entry.value;

        Widget ele = Positioned(
            top: offset.dy,
            left: offset.dx,
            child: _buildDraggableElementWidget(context, elementDefinition));
        children.add(ele);
      }

      return Stack(
        children: children,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTapDown: (TapDownDetails details) {
          if (elementDefinitionControllers.addElementStatus.value) {
            ElementDefinition elementDefinition = ElementDefinition('unknown',
                false, elementDefinitionControllers.packageName.value!);
            ElementDefinitionController? elementDefinitionController =
                elementDefinitionControllers.getElementDefinitionController();
            if (elementDefinitionController != null) {
              elementDefinitionController
                      .elementDefinitions[elementDefinition] =
                  details.localPosition;
            }

            elementDefinitionControllers.addElementStatus.value = false;
          }
        },
        child: Container(
            key: _key,
            height: appDataProvider.portraitSize.height -
                appDataProvider.toolbarHeight -
                40,
            width: appDataProvider.secondaryBodyWidth,
            color: Colors.blueGrey.shade100,
            child: InteractiveViewer(
                transformationController: transformationController,
                child: _buildElementDefinitionWidget(context))));
  }
}
