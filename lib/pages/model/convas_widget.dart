import 'package:colla_chat/pages/model/element_definition_widget.dart';
import 'package:colla_chat/pages/model/element_deifinition.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ElementDefinitionController {
  final RxBool addElementStatus = false.obs;

  Map<ElementDefinition, Offset> elementDefinitions = {};

  Map<RelationshipDefinition, Offset> relationshipDefinition = {};
}

class ElementDefinitionControllers {
  final Map<String, ElementDefinitionController> packageDefinitionController =
      {};
  final Rx<ElementDefinition?> selected = Rx<ElementDefinition?>(null);
}

final ElementDefinitionControllers elementDefinitionControllers =
    ElementDefinitionControllers();

/// 画布
class CanvasWidget extends StatelessWidget {
  final Rx<String?> packageName = Rx<String?>(null);

  CanvasWidget({super.key});

  Widget _buildDragTargetWidget() {
    DragTarget dragTarget = DragTarget<ElementDefinition>(
      builder: (context, candidateItems, rejectedItems) {
        return this;
      },
      onAcceptWithDetails: (details) {
        ElementDefinition elementDefinition = details.data;
        ElementDefinitionController? elementDefinitionController =
        elementDefinitionControllers.packageDefinitionController[packageName.value];
        if (elementDefinitionController != null) {
          elementDefinitionController.elementDefinitions[elementDefinition] =
              details.offset;
        }
      },
    );

    return dragTarget;
  }

  Widget _buildDraggableElementWidget(
      BuildContext context, ElementDefinition elementDefinition) {
    LongPressDraggable<ElementDefinition> draggable =
        LongPressDraggable<ElementDefinition>(
      ///将会被传递到DragTarget
      dragAnchorStrategy: pointerDragAnchorStrategy,

      ///拖动过程中的显示组件
      feedback: ElementDefinitionWidget(elementDefinition: elementDefinition),
      child: ElementDefinitionWidget(elementDefinition: elementDefinition),
    );

    return draggable;
  }

  Widget _buildElementDefinitionWidget(BuildContext context) {
    ElementDefinitionController? elementDefinitionController =
    elementDefinitionControllers.packageDefinitionController[packageName.value];
    if (elementDefinitionController != null) {
      return nilBox;
    }
    List<Widget> children = [];
    for (var entry in elementDefinitionController!.elementDefinitions.entries) {
      ElementDefinition elementDefinition = entry.key;
      Offset offset = entry.value;

      Widget ele = Positioned(
          top: offset.dy,
          left: offset.dx,
          child: _buildDraggableElementWidget(context, elementDefinition));
      children.add(ele);
    }

    return GestureDetector(
        onTapDown: (TapDownDetails details) {
          details.localPosition;
        },
        child: Stack(
          children: children,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return _buildElementDefinitionWidget(context);
  }
}
