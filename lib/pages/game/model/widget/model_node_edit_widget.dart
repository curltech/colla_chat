import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

class ModelNodeEditWidget extends StatelessWidget with TileDataMixin {
  ModelNodeEditWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'node_edit';

  @override
  IconData get iconData => Icons.edit_calendar_outlined;

  @override
  String get title => 'NodeEdit';

  ModelNode? get modelNode {
    return modelProjectController.selectedModelNode.value;
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
    PlatformDataField(
        name: 'nodeType',
        label: 'NodeType',
        prefixIcon: Icon(Icons.person, color: myself.primary)),
    PlatformDataField(
        name: 'shapeType',
        label: 'ShapeType',
        prefixIcon: Icon(Icons.person, color: myself.primary)),
    PlatformDataField(
        name: 'content',
        label: 'Content',
        prefixIcon: Icon(Icons.person, color: myself.primary)),
  ];

  late final FormInputController formInputController =
      FormInputController(modelNodeDataFields);

  //ModelNode信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    formInputController.setValues(JsonUtil.toJson(modelNode));
    var formInputWidget = FormInputWidget(
      height: appDataProvider.portraitSize.height * 0.5,
      spacing: 15.0,
      onOk: (Map<String, dynamic> values) {
        ModelNode? modelNode = _onOk(values);

        Navigator.pop(context, modelNode);
      },
      controller: formInputController,
    );

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

    return current;
  }

  @override
  Widget build(BuildContext context) {
    return _buildFormInputWidget(context);
  }
}
