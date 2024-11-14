import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/pages/game/model/widget/attribute_edit_widget.dart';
import 'package:colla_chat/pages/game/model/widget/method_edit_widget.dart';
import 'package:colla_chat/pages/game/model/widget/node_relationship_edit_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ModelNodeEditWidget extends StatelessWidget with TileDataMixin {
  final AttributeEditWidget attributeEditWidget = AttributeEditWidget();
  final MethodEditWidget methodEditWidget = MethodEditWidget();
  final NodeRelationshipEditWidget nodeRelationshipEditWidget =
      NodeRelationshipEditWidget();

  ModelNodeEditWidget({super.key}) {
    indexWidgetProvider.define(attributeEditWidget);
    indexWidgetProvider.define(methodEditWidget);
    indexWidgetProvider.define(nodeRelationshipEditWidget);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'node_edit';

  @override
  IconData get iconData => Icons.edit_calendar_outlined;

  @override
  String get title => 'NodeEdit';

  ModelNode? get modelNode {
    return modelProjectController.selectedSrcModelNode.value;
  }

  final List<PlatformDataField> modelNodeDataFields = [
    PlatformDataField(
        name: 'id',
        label: 'Id',
        inputType: InputType.label,
        prefixIcon: Icon(Icons.numbers_outlined, color: myself.primary)),
    PlatformDataField(
        name: 'name',
        label: 'Name',
        prefixIcon: Icon(Icons.person, color: myself.primary)),
  ];

  FormInputController? formInputController;

  final Rx<String?> content = Rx<String?>(null);

  Future<void> _pickAvatar(BuildContext context) async {
    Uint8List? avatar = await ImageUtil.pickAvatar(context: context);
    if (avatar == null) {
      bool? confirm =
          await DialogUtil.confirm(content: 'Do you want delete image?');
      if (confirm == null || !confirm) {
        return;
      }
    }
    if (avatar != null) {
      String data = CryptoUtil.encodeBase64(avatar);
      data = ImageUtil.base64Img(data);
      content.value = data;
    }
  }

  //ModelNode信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    if (modelNode == null) {
      return nilBox;
    }
    Project? project = modelProjectController.project.value;
    if (project == null) {
      return nilBox;
    }
    List<Widget> tails = [];
    if (project.meta &&
        (modelNode!.nodeType == NodeType.image.name ||
            modelNode!.nodeType == NodeType.shape.name)) {
      tails.add(Obx(() {
        return ListTile(
          title: Text(AppLocalizations.t('Image')),
          trailing: content.value != null
              ? ImageUtil.buildImageWidget(
                  width: 24, height: 24, imageContent: content.value)
              : null,
          onTap: () {
            _pickAvatar(context);
          },
        );
      }));
    }
    formInputController = FormInputController(_buildModelNodeDataFields());
    formInputController!.setValues(JsonUtil.toJson(modelNode));
    Widget formInputWidget = FormInputWidget(
        spacing: 15.0,
        onOk: (Map<String, dynamic> values) {
          _onOk(values);
        },
        controller: formInputController!,
        tails: tails);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
      child: formInputWidget,
    );
  }

  ModelNode? _onOk(Map<String, dynamic> values) {
    ModelNode current = ModelNode.fromJson(values);
    if (StringUtil.isEmpty(current.name)) {
      DialogUtil.error(content: AppLocalizations.t('Must has modelNode name'));
      return null;
    }
    modelNode?.name = current.name;
    modelNode?.content = current.content;
    modelNode?.nodeType = current.nodeType;
    modelNode?.shapeType = current.shapeType;
    modelNode?.fillColor = current.fillColor;
    modelNode?.strokeColor = current.strokeColor;
    if (modelNode!.nodeType == NodeType.image.name) {
      modelNode?.content = content.value;
    }
    dynamic child = modelNode?.nodeFrameComponent?.child;
    child?.onUpdate();
    DialogUtil.info(
        content: 'Successfully update modelNode:${modelNode!.name}');

    return current;
  }

  List<PlatformDataField> _buildModelNodeDataFields() {
    ModelNode? modelNode = this.modelNode;
    if (modelNode == null) {
      return [];
    }

    List<PlatformDataField> modelNodeDataFields = [...this.modelNodeDataFields];
    List<Option<dynamic>> options = [];
    for (var value in NodeType.values) {
      options.add(Option(value.name, value.name));
    }
    modelNodeDataFields.add(
      PlatformDataField(
          name: 'nodeType',
          label: 'NodeType',
          readOnly: true,
          prefixIcon: Icon(Icons.type_specimen_outlined, color: myself.primary),
          inputType: InputType.togglebuttons,
          options: options),
    );
    if (modelNode.nodeType == NodeType.shape.name) {
      options = [];
      for (var value in ShapeType.values) {
        options.add(Option(value.name, value.name));
      }
      modelNodeDataFields.add(PlatformDataField(
          name: 'shapeType',
          label: 'ShapeType',
          prefixIcon: Icon(Icons.share_sharp, color: myself.primary),
          inputType: InputType.radio,
          options: options));
      modelNodeDataFields.add(PlatformDataField(
          name: 'fillColor',
          label: 'FillColor',
          prefixIcon: Icon(Icons.format_color_fill, color: myself.primary),
          inputType: InputType.color));
      modelNodeDataFields.add(PlatformDataField(
        name: 'strokeColor',
        label: 'StrokeColor',
        prefixIcon: Icon(Icons.border_color, color: myself.primary),
        inputType: InputType.color,
      ));
    }
    if (modelNode.nodeType == NodeType.remark.name) {
      modelNodeDataFields.add(PlatformDataField(
        name: 'content',
        label: 'Content',
        minLines: 4,
        inputType: InputType.textarea,
        prefixIcon: Icon(Icons.content_copy, color: myself.primary),
      ));
    }

    return modelNodeDataFields;
  }

  @override
  Widget build(BuildContext context) {
    content.value = modelNode!.content;
    return AppBarView(
        title: title,
        withLeading: true,
        rightWidgets: [
          IconButton(
              tooltip: AppLocalizations.t(attributeEditWidget.title),
              onPressed: () {
                indexWidgetProvider.push(attributeEditWidget.routeName);
              },
              icon: Icon(attributeEditWidget.iconData)),
          IconButton(
              tooltip: AppLocalizations.t(methodEditWidget.title),
              onPressed: () {
                indexWidgetProvider.push(methodEditWidget.routeName);
              },
              icon: Icon(methodEditWidget.iconData))
        ],
        child: _buildFormInputWidget(context));
  }
}
