import 'package:colla_chat/pages/game/model/flame/model_canvas_controller.dart';
import 'package:colla_chat/pages/game/model/meta_canvas_widget.dart';
import 'package:colla_chat/pages/game/model/model_project_controller.dart';
import 'package:colla_chat/pages/game/model/flame/node.dart';
import 'package:colla_chat/pages/game/model/meta_model_node.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const double elementWidth = 80;
const double elementHeight = 100;

/// 元模型节点的显示组件
class MetaModelNodeWidget extends StatelessWidget {
  final MetaModelNode elementDefinition;

  final BorderSide bordSide = BorderSide(
    color: Colors.amber.shade100,
    width: 1.0,
    style: BorderStyle.solid,
  );

  final BorderSide selectedBordSide = const BorderSide(
    color: Colors.redAccent,
    width: 1.0,
    style: BorderStyle.solid,
  );

  MetaModelNodeWidget({super.key, required this.elementDefinition});

  _buildHeadWidget(BuildContext context) {
    return Column(children: [
      // CommonAutoSizeText(elementDefinition.packageName),
      CommonAutoSizeText(elementDefinition.name),
    ]);
  }

  _buildAttributesWidget(BuildContext context) {
    List<Widget> children = [];
    for (var name in elementDefinition.attributes.keys.toList()) {
      children.add(CommonAutoSizeText(name));
    }
    return Column(
      children: children,
    );
  }

  _buildMethodWidget(BuildContext context) {
    List<Widget> children = [];
    for (var name in elementDefinition.methods) {
      children.add(CommonAutoSizeText(name));
    }
    return Column(
      children: children,
    );
  }

  _buildRuleWidget(BuildContext context) {
    List<Widget> children = [];
    for (var name in elementDefinition.rules) {
      children.add(CommonAutoSizeText(name));
    }
    return Column(
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return InkWell(
          onTap: () {
            if (modelProjectController.selected.value != null &&
                modelProjectController.addRelationshipStatus.value) {
              NodeRelationship nodeRelationship = NodeRelationship(
                  modelProjectController.selected.value!,
                  elementDefinition,
                  RelationshipType.direct);
              ModelCanvasController? modelCanvasController =
                  modelProjectController.getModelCanvasController();
              if (modelCanvasController != null) {
                modelCanvasController.nodeRelationships[nodeRelationship.src] =
                    [nodeRelationship];
              }
              modelProjectController.addRelationshipStatus.value = false;
            }
            modelProjectController.selected.value = elementDefinition;
          },
          child: Container(
              width: elementWidth,
              height: elementHeight,
              padding: const EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                border: Border.fromBorderSide(
                    elementDefinition == modelProjectController.selected.value
                        ? selectedBordSide
                        : bordSide),
                borderRadius: BorderRadius.circular(2),
                shape: BoxShape.rectangle,
                boxShadow: const [
                  BoxShadow(offset: Offset(1.0, 1.0), blurRadius: 1.0)
                ],
              ),
              child: Column(
                children: [
                  _buildHeadWidget(context),
                  const Divider(),
                  _buildAttributesWidget(context),
                  const Divider(),
                  _buildMethodWidget(context),
                  const Divider(),
                  _buildRuleWidget(context),
                ],
              )));
    });
  }
}
