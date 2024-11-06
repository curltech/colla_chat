import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
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

class NodeRelationshipEditWidget extends StatelessWidget with TileDataMixin {
  @override
  bool get withLeading => true;

  @override
  String get routeName => 'relationship_edit';

  @override
  IconData get iconData => Icons.link;

  @override
  String get title => 'RelationshipEdit';

  NodeRelationshipEditWidget({super.key});

  NodeRelationship? get nodeRelationship {
    return modelProjectController.selectedRelationship.value;
  }

  final List<PlatformDataField> relationshipDataFields = [
    PlatformDataField(
        name: 'srcId',
        label: 'SrcId',
        inputType: InputType.label,
        prefixIcon: Icon(Icons.numbers_outlined, color: myself.primary)),
    PlatformDataField(
        name: 'dstId',
        label: 'DstId',
        inputType: InputType.label,
        prefixIcon: Icon(Icons.numbers_outlined, color: myself.primary)),
    PlatformDataField(
        name: 'relationshipType',
        label: 'RelationshipType',
        prefixIcon: Icon(Icons.link, color: myself.primary)),
    PlatformDataField(
        name: 'srcCardinality',
        label: 'SrcCardinality',
        prefixIcon: Icon(Icons.numbers_outlined, color: myself.primary)),
    PlatformDataField(
        name: 'dstCardinality',
        label: 'DstCardinality',
        prefixIcon: Icon(Icons.numbers_outlined, color: myself.primary)),
  ];

  late final FormInputController formInputController =
      FormInputController(relationshipDataFields);

  //ModelNode信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    formInputController.setValues(JsonUtil.toJson(nodeRelationship));
    var formInputWidget = FormInputWidget(
      height: appDataProvider.portraitSize.height * 0.5,
      spacing: 15.0,
      onOk: (Map<String, dynamic> values) {
        NodeRelationship? nodeRelationship = _onOk(values);

        Navigator.pop(context, nodeRelationship);
      },
      controller: formInputController,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
      child: formInputWidget,
    );
  }

  NodeRelationship? _onOk(Map<String, dynamic> values) {
    NodeRelationship current = NodeRelationship.fromJson(values);
    if (StringUtil.isEmpty(current.relationshipType)) {
      DialogUtil.error(
          content:
              AppLocalizations.t('Must has nodeRelationship relationshipType'));
      return null;
    }
    if (current.srcCardinality == null) {
      DialogUtil.error(
          content:
              AppLocalizations.t('Must has nodeRelationship srcCardinality'));
      return null;
    }
    if (current.dstCardinality == null) {
      DialogUtil.error(
          content:
              AppLocalizations.t('Must has nodeRelationship dstCardinality'));
      return null;
    }
    nodeRelationship?.relationshipType = current.relationshipType;
    nodeRelationship?.srcCardinality = current.srcCardinality;
    nodeRelationship?.dstCardinality = current.dstCardinality;

    return current;
  }

  @override
  Widget build(BuildContext context) {
    return _buildFormInputWidget(context);
  }
}
