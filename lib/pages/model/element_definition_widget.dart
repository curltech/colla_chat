import 'package:colla_chat/pages/model/convas_widget.dart';
import 'package:colla_chat/pages/model/element_deifinition.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';

/// 元素定义的显示组件
class ElementDefinitionWidget extends StatelessWidget {
  final ElementDefinition elementDefinition;

  final BorderSide bordSide = BorderSide(
    color: Colors.amber.shade100,
    width: 1.0,
    style: BorderStyle.solid,
  );

  final BorderSide selectedBordSide = BorderSide(
    color: myself.primary,
    width: 2.0,
    style: BorderStyle.solid,
  );

  ElementDefinitionWidget({super.key, required this.elementDefinition});

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
    return Container(
        padding: const EdgeInsets.all(5.0),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          border: Border.fromBorderSide(
              elementDefinition == elementDefinitionControllers.selected.value
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
        ));
  }
}
