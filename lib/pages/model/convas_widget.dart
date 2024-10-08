import 'package:colla_chat/pages/model/element_definition_controller.dart';
import 'package:colla_chat/pages/model/element_definition_widget.dart';
import 'package:colla_chat/pages/model/element_deifinition.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/context_util.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
            modelProjectController.getElementDefinitionController();
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
      onDragStarted: () {
        // ElementDefinitionController? elementDefinitionController =
        //     modelProjectController.getElementDefinitionController();
        // if (elementDefinitionController != null) {
        //   elementDefinitionController.elementDefinitions
        //       .remove(elementDefinition);
        // }
      },
      onDragEnd: (DraggableDetails detail) {
        ElementDefinitionController? elementDefinitionController =
            modelProjectController.getElementDefinitionController();
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
          modelProjectController.getElementDefinitionController();
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
          if (modelProjectController.addElementStatus.value) {
            ElementDefinition elementDefinition = ElementDefinition('unknown',
                false, modelProjectController.currentPackageName.value!);
            ElementDefinitionController? elementDefinitionController =
                modelProjectController.getElementDefinitionController();
            if (elementDefinitionController != null) {
              elementDefinitionController
                      .elementDefinitions[elementDefinition] =
                  details.localPosition;
            }

            modelProjectController.addElementStatus.value = false;
          }
        },
        child: InteractiveViewer(
            transformationController: transformationController,
            child: CustomPaint(
              painter: RelationshipLinePainter(),
              child: RepaintBoundary(
                  child: SizedBox(
                      key: _key,
                      height: appDataProvider.portraitSize.height -
                          appDataProvider.toolbarHeight -
                          40,
                      width: appDataProvider.secondaryBodyWidth,
                      child: _buildElementDefinitionWidget(context))),
            )));
  }
}

/// 画关系线的画笔
/// CustomPaint的child指定绘制区域，而且RepaintBoundary(child:...)
class RelationshipLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    ElementDefinitionController? elementDefinitionController =
        modelProjectController.getElementDefinitionController();
    if (elementDefinitionController == null) {
      return;
    }
    Path path = Path();
    for (var relationshipDefinition
        in elementDefinitionController.relationshipDefinitions) {
      Offset? srcOffset = elementDefinitionController
          .elementDefinitions[relationshipDefinition.src];
      Offset? dstOffset = elementDefinitionController
          .elementDefinitions[relationshipDefinition.dst];
      if (srcOffset != null && dstOffset != null) {
        double sdx = srcOffset.dx + elementWidth / 2;
        double sdy = srcOffset.dy;
        double ddx = dstOffset.dx + elementWidth / 2;
        double ddy = dstOffset.dy + elementHeight;
        path.moveTo(sdx, sdy);
        path.lineTo(sdx, (sdy - ddy) / 2 + ddy);
        path.lineTo((ddx - sdx) + sdx, (sdy - ddy) / 2 + ddy);
        path.lineTo((ddx - sdx) + sdx, ddy);
      }
    }
    var paint = Paint()..color = Colors.blueAccent; //2080E5
    paint.strokeWidth = 1.0;
    paint.style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  // 返回false, 后面介绍
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
