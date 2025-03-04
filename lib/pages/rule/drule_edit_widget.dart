import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/rule/drule.dart';
import 'package:colla_chat/pages/rule/drule_list_widget.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
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

class DruleEditWidget extends StatelessWidget with TileDataMixin {
  @override
  bool get withLeading => true;

  @override
  String get routeName => 'drule_edit';

  @override
  IconData get iconData => Icons.rule;

  @override
  String get title => 'DruleEdit';

  @override
  String? get information => null;

  DruleEditWidget({super.key});

  final List<PlatformDataField> druleDataFields = [
    PlatformDataField(
        name: 'id',
        label: 'Id',
        prefixIcon: Icon(Icons.numbers_outlined, color: myself.primary)),
    PlatformDataField(
        name: 'name',
        label: 'Name',
        prefixIcon: Icon(Icons.text_fields_outlined, color: myself.primary)),
    PlatformDataField(
        name: 'priority',
        label: 'Priority',
        prefixIcon: Icon(Icons.low_priority_outlined, color: myself.primary)),
    PlatformDataField(
        name: 'enabled',
        label: 'Enabled',
        prefixIcon:
            Icon(Icons.notifications_active_outlined, color: myself.primary)),
    PlatformDataField(
        name: 'operator',
        label: 'Operator',
        prefixIcon: Icon(Icons.filter_9_plus_outlined, color: myself.primary)),
    PlatformDataField(
        name: 'operands',
        label: 'Operands',
        prefixIcon: Icon(Icons.four_k_plus_outlined, color: myself.primary)),
    PlatformDataField(
        name: 'onSuccess',
        label: 'onSuccess',
        prefixIcon: Icon(Icons.check_circle_outline, color: myself.primary)),
    PlatformDataField(
        name: 'onFailure',
        label: 'onFailure',
        prefixIcon: Icon(Icons.sms_failed_outlined, color: myself.primary)),
  ];

  late final FormInputController formInputController =
      FormInputController(druleDataFields);

  //ModelNode信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    List<Option<dynamic>> options = [];
    for (var value in DataType.values) {
      options.add(Option(value.name, value.name));
    }
    return Obx(() {
      Drule? drule = drulesController.current;
      if (drule == null) {
        return nilBox;
      }
      formInputController.setValues(JsonUtil.toJson(drule));
      var formInputWidget = FormInputWidget(
        spacing: 15.0,
        onOk: (Map<String, dynamic> values) {
          _onOk(values);
        },
        controller: formInputController,
      );

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
        child: formInputWidget,
      );
    });
  }

  Drule? _onOk(Map<String, dynamic> values) {
    Drule current = Drule.fromJson(values);
    if (StringUtil.isEmpty(current.name)) {
      DialogUtil.error(content: AppLocalizations.t('Must has drule name'));
      return null;
    }
    if (current.conditions.isEmpty) {
      DialogUtil.error(content: AppLocalizations.t('Must has attribute scope'));
      return null;
    }
    if (current.actionInfo.onSuccess.isEmpty) {
      DialogUtil.error(
          content: AppLocalizations.t('Must has attribute dataType'));
      return null;
    }
    Drule? drule = drulesController.current;
    drule?.id = current.id;
    drule?.name = current.name;
    drule?.conditions = current.conditions;
    DialogUtil.info(content: 'Successfully update drule:${drule?.name}');

    return current;
  }

  Future<void> _onAdd() async {
    Drule drule = Drule('', [], ActionInfo('', []));
    drulesController.add(drule);
  }

  Future<void> _onDelete() async {
    Drule? drule = drulesController.current;
    if (drule == null) {
      return;
    }
    bool? success = await DialogUtil.confirm(
        content: 'Do you confirm to delete this drule:${drule.name}');
    if (success != null && success) {
      drulesController.delete();
    }
  }

  List<Widget> _buildRightButton(BuildContext context) {
    return [
      IconButton(
        tooltip: AppLocalizations.t('Add attribute'),
        icon: const Icon(Icons.add),
        onPressed: () {
          _onAdd();
        },
      ),
      IconButton(
        tooltip: AppLocalizations.t('Delete attribute'),
        icon: const Icon(Icons.delete_outline),
        onPressed: () {
          _onDelete();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: title,
        withLeading: true,
        rightWidgets: _buildRightButton(context),
        child: _buildFormInputWidget(context));
  }
}
