import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart'
    as data_source;
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

final Rx<data_source.DataIndex?> rxDataIndex = Rx<data_source.DataIndex?>(null);

class DataIndexEditWidget extends StatelessWidget with TileDataMixin {
  @override
  bool get withLeading => true;

  @override
  String get routeName => 'data_index_edit';

  @override
  IconData get iconData => Icons.content_paste_search;

  @override
  String get title => 'DataIndexEdit';

  late final FormInputController formInputController;

  DataIndexEditWidget({super.key}) {
    formInputController = FormInputController(buildDataIndexDataFields());
  }

  List<PlatformDataField> buildDataIndexDataFields() {
    var dataIndexDataFields = [
      PlatformDataField(
          name: 'name',
          label: 'Name',
          prefixIcon: Icon(Icons.person, color: myself.primary)),
      PlatformDataField(
          name: 'comment',
          label: 'Comment',
          prefixIcon: Icon(Icons.comment, color: myself.primary)),
      PlatformDataField(
          name: 'isUnique',
          label: 'isUnique',
          inputType: InputType.switcher,
          dataType: DataType.bool,
          prefixIcon: Icon(Icons.one_k_outlined, color: myself.primary)),
    ];

    return dataIndexDataFields;
  }

  //DataIndex信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    return Obx(() {
      data_source.DataIndex dataIndex = rxDataIndex.value!;
      formInputController?.setValues(JsonUtil.toJson(dataIndex));
      var formInputWidget = FormInputWidget(
        spacing: 15.0,
        onOk: (Map<String, dynamic> values) {
          _onOk(values);
        },
        controller: formInputController!,
      );

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
        child: formInputWidget,
      );
    });
  }

  data_source.DataIndex? _onOk(Map<String, dynamic> values) {
    data_source.DataIndex current = data_source.DataIndex.fromJson(values);
    if (StringUtil.isEmpty(current.name)) {
      DialogUtil.error(content: AppLocalizations.t('Must has dataIndex name'));
      return null;
    }
    data_source.DataIndex dataIndex = rxDataIndex.value!;
    String? originalName = dataIndex.name;
    if (originalName == null) {}
    dataIndex.name = current.name;

    DialogUtil.info(content: 'Successfully update dataIndex:${dataIndex.name}');

    return current;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: title, withLeading: true, child: _buildFormInputWidget(context));
  }
}
