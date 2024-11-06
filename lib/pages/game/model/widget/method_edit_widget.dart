import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/component/method_text_component.dart';
import 'package:colla_chat/pages/game/model/component/type_node_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MethodEditWidget extends StatelessWidget with TileDataMixin {
  @override
  bool get withLeading => true;

  @override
  String get routeName => 'method_edit';

  @override
  IconData get iconData => Icons.call_to_action_outlined;

  @override
  String get title => 'MethodEdit';

  late RxList<Method> methods;

  Rx<Method?> method = Rx<Method?>(null);

  MethodEditWidget({super.key});

  ModelNode get modelNode {
    return modelProjectController.selectedModelNode.value!;
  }

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

  Widget _buildMethodsWidget(BuildContext context) {
    return Column(children: [
      _buildToolPanel(context),
      Expanded(child: Obx(() {
        if (methods.isNotEmpty) {
          List<TileData> tiles = [];
          for (var method in methods) {
            TileData tile =
                TileData(title: method.name, subtitle: method.returnType);
            tiles.add(tile);
          }

          return DataListView(
            itemCount: tiles.length,
            itemBuilder: (BuildContext context, int index) {
              return tiles[index];
            },
            onTap: (int index, String title,
                {TileData? group, String? subtitle}) {
              method.value = methods[index];
            },
          );
        }

        return nilBox;
      }))
    ]);
  }

  //ModelNode信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    return Obx(() {
      if (method.value == null) {
        return nilBox;
      }
      formInputController.setValues(JsonUtil.toJson(method.value));
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
    });
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
    method.value?.name = current.name;
    method.value?.scope = current.scope;
    method.value?.returnType = current.returnType;
    _onUpdate();

    return current;
  }

  Future<void> _onAdd() async {
    PositionComponent? child = modelNode.nodeFrameComponent?.child;
    if (child != null) {
      method.value = Method('unknownMethod');
      methods.add(method.value!);
      if (child is TypeNodeComponent) {
        child.methodAreaComponent.onAdd(method.value!);
      }
    }
  }

  Future<void> _onDelete() async {
    bool? success = await DialogUtil.confirm(
        content: 'Do you confirm to delete this method:${method.value?.name}');
    if (success != null && success) {
      List<Method> methods = modelNode.methods;
      if (methods.isNotEmpty) {
        methods.remove(method.value);
        MethodTextComponent? methodTextComponent =
            method.value?.methodTextComponent;

        if (methodTextComponent != null) {
          methodTextComponent.onDelete();
        }
        method.value = null;
      }
    }
  }

  Future<void> _onUpdate() async {
    if (method.value != null) {
      MethodTextComponent? methodTextComponent =
          method.value?.methodTextComponent;

      if (methodTextComponent != null) {
        methodTextComponent.onUpdate();
      }
    }
  }

  Widget _buildToolPanel(BuildContext context) {
    return OverflowBar(
      children: [
        IconButton(
          tooltip: AppLocalizations.t('Add method'),
          icon: const Icon(Icons.add),
          onPressed: () {
            _onAdd();
          },
        ),
        IconButton(
          tooltip: AppLocalizations.t('Delete method'),
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            _onDelete();
          },
        ),
        IconButton(
          tooltip: AppLocalizations.t('Update method'),
          icon: const Icon(Icons.update),
          onPressed: () {
            _onUpdate();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (appDataProvider.landscape) {
      child = Row(children: [
        _buildMethodsWidget(context),
        _buildFormInputWidget(context)
      ]);
    } else {
      child = Column(children: [
        _buildMethodsWidget(context),
        _buildFormInputWidget(context)
      ]);
    }

    return AppBarView(title: title, withLeading: true, child: child);
  }
}
