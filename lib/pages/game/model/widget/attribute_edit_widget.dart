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

class AttributeEditWidget extends StatelessWidget {
  final Attribute attribute;

  AttributeEditWidget({super.key, required this.attribute});

  final List<PlatformDataField> attributeDataFields = [
    PlatformDataField(
        name: 'name',
        label: 'Name',
        prefixIcon: Icon(Icons.person, color: myself.primary)),
    PlatformDataField(
        name: 'scope',
        label: 'Scope',
        prefixIcon: Icon(Icons.shopping_bag_outlined, color: myself.primary)),
    PlatformDataField(
        name: 'dataType',
        label: 'DataType',
        prefixIcon: Icon(Icons.data_object_outlined, color: myself.primary)),
  ];

  late final FormInputController formInputController =
      FormInputController(attributeDataFields);

  //ModelNode信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    formInputController.setValues(JsonUtil.toJson(attribute));
    var formInputWidget = FormInputWidget(
      height: appDataProvider.portraitSize.height * 0.5,
      spacing: 15.0,
      onOk: (Map<String, dynamic> values) {
        Attribute? attribute = _onOk(values);

        Navigator.pop(context, attribute);
      },
      controller: formInputController,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
      child: formInputWidget,
    );
  }

  Attribute? _onOk(Map<String, dynamic> values) {
    Attribute current = Attribute.fromJson(values);
    if (StringUtil.isEmpty(current.name)) {
      DialogUtil.error(content: AppLocalizations.t('Must has attribute name'));
      return null;
    }
    if (StringUtil.isEmpty(current.scope)) {
      DialogUtil.error(content: AppLocalizations.t('Must has attribute scope'));
      return null;
    }
    if (StringUtil.isEmpty(current.dataType)) {
      DialogUtil.error(
          content: AppLocalizations.t('Must has attribute dataType'));
      return null;
    }
    attribute.name = current.name;
    attribute.scope = current.scope;
    attribute.dataType = current.dataType;

    return current;
  }

  @override
  Widget build(BuildContext context) {
    return _buildFormInputWidget(context);
  }
}
