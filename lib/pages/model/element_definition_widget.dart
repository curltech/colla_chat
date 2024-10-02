import 'package:colla_chat/pages/model/convas_widget.dart';
import 'package:colla_chat/pages/model/element_deifinition.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';

/// 元素定义的显示组件
class ElementDefinitionWidget extends StatelessWidget {
  final ElementDefinition elementDefinition;

  final BorderSide bordSide = const BorderSide(
    color: Colors.black,
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
    return CommonAutoSizeText(elementDefinition.name);
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
        decoration: BoxDecoration(
          border: Border.fromBorderSide(
              elementDefinition == elementDefinitionControllers.selected.value
                  ? selectedBordSide
                  : bordSide),
          borderRadius: BorderRadius.circular(4),
          shape: BoxShape.rectangle,
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
