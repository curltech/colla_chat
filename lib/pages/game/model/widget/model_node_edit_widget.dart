import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

class ModelNodeEditWidget extends StatelessWidget {
  final ModelNode modelNode;

  ModelNodeEditWidget({super.key, required this.modelNode});

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
        name: 'packageName',
        label: 'PackageName',
        prefixIcon: Icon(Icons.shopping_bag_outlined, color: myself.primary)),
    PlatformDataField(
        name: 'isAbstract',
        label: 'IsAbstract',
        inputType: InputType.switcher,
        dataType: DataType.bool,
        prefixIcon: Icon(Icons.ac_unit_outlined, color: myself.primary)),
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
        _onOk(values).then((modelNode) {
          if (modelNode != null) {
            DialogUtil.info(content: 'ModelNode ${modelNode.name} is built');
          }
        });
      },
      controller: formInputController,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
      child: formInputWidget,
    );
  }

  Future<ModelNode?> _onOk(Map<String, dynamic> values) async {
    ModelNode current = ModelNode.fromJson(values);
    if (StringUtil.isEmpty(current.name)) {
      DialogUtil.error(content: AppLocalizations.t('Must has modelNode name'));
      return null;
    }
    if (StringUtil.isEmpty(current.packageName)) {
      DialogUtil.error(
          content: AppLocalizations.t('Must has modelNode packageName'));
      return null;
    }
    modelNode.name = current.name;
    modelNode.packageName = current.packageName;
    modelNode.isAbstract = current.isAbstract;

    return current;
  }

  @override
  Widget build(BuildContext context) {
    return _buildFormInputWidget(context);
  }
}
