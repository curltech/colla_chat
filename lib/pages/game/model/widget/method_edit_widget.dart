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

class MethodEditWidget extends StatelessWidget {
  final Method method;

  MethodEditWidget({super.key, required this.method});

  final List<PlatformDataField> methodDataFields = [
    PlatformDataField(
        name: 'name',
        label: 'Name',
        prefixIcon: Icon(Icons.person, color: myself.primary)),
    PlatformDataField(
        name: 'scope',
        label: 'Scope',
        prefixIcon: Icon(Icons.shopping_bag_outlined, color: myself.primary)),
    PlatformDataField(
        name: 'returnType',
        label: 'ReturnType',
        prefixIcon: Icon(Icons.data_object_outlined, color: myself.primary)),
  ];

  late final FormInputController formInputController =
      FormInputController(methodDataFields);

  //ModelNode信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    formInputController.setValues(JsonUtil.toJson(method));
    var formInputWidget = FormInputWidget(
      height: appDataProvider.portraitSize.height * 0.5,
      spacing: 15.0,
      onOk: (Map<String, dynamic> values) {
        Method? method = _onOk(values);

        Navigator.pop(context, method);
      },
      controller: formInputController,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
      child: formInputWidget,
    );
  }

  Method? _onOk(Map<String, dynamic> values) {
    Method current = Method.fromJson(values);
    if (StringUtil.isEmpty(current.name)) {
      DialogUtil.error(content: AppLocalizations.t('Must has method name'));
      return null;
    }
    if (StringUtil.isEmpty(current.scope)) {
      DialogUtil.error(content: AppLocalizations.t('Must has method scope'));
      return null;
    }
    if (StringUtil.isEmpty(current.returnType)) {
      DialogUtil.error(
          content: AppLocalizations.t('Must has method returnType'));
      return null;
    }
    method.name = current.name;
    method.scope = current.scope;
    method.returnType = current.returnType;

    return current;
  }

  @override
  Widget build(BuildContext context) {
    return _buildFormInputWidget(context);
  }
}
