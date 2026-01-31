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
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_reactive_form.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MethodEditWidget extends StatelessWidget with DataTileMixin {
  @override
  bool get withLeading => true;

  @override
  String get routeName => 'method_edit';

  @override
  IconData get iconData => Icons.call_to_action_outlined;

  @override
  String get title => 'MethodEdit';

  final Rx<List<Method>?> methods = Rx<List<Method>?>(null);

  final Rx<Method?> method = Rx<Method?>(null);

  MethodEditWidget({super.key});

  ModelNode? get modelNode {
    return modelProjectController.selectedSrcModelNode.value;
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
  ];

  PlatformReactiveFormController? platformReactiveFormController;

  Widget _buildMethodsWidget(BuildContext context) {
    return Obx(() {
      if (methods.value != null && methods.value!.isNotEmpty) {
        List<DataTile> tiles = [];
        for (var method in methods.value!) {
          DataTile tile =
              DataTile(title: method.name, subtitle: method.returnType);
          tiles.add(tile);
        }

        return DataListView(
          itemCount: tiles.length,
          itemBuilder: (BuildContext context, int index) {
            return tiles[index];
          },
          onTap: (int index, String title,
              {DataTile? group, String? subtitle}) async {
            method.value = methods.value![index];
            return null;
          },
        );
      }

      return nilBox;
    });
  }

  //ModelNode信息编辑界面
  Widget _buildPlatformReactiveForm(BuildContext context) {
    List<Option<dynamic>> options = [];
    for (var value in DataType.values) {
      options.add(Option(value.name, value.name));
    }
    List<PlatformDataField> methodDataFields = [...this.methodDataFields];
    methodDataFields.add(PlatformDataField(
        name: 'returnType',
        label: 'ReturnType',
        prefixIcon: Icon(Icons.data_object_outlined, color: myself.primary),
        inputType: InputType.dropdownField,
        options: options));
    platformReactiveFormController =
        PlatformReactiveFormController(methodDataFields);
    return Obx(() {
      if (method.value == null) {
        return nilBox;
      }
      platformReactiveFormController!.values = JsonUtil.toJson(method.value);
      var formInputWidget = PlatformReactiveForm(
        height: appDataProvider.portraitSize.height * 0.5,
        spacing: 15.0,
        onSubmit: (Map<String, dynamic> values) {
          _onOk(values);
        },
        platformReactiveFormController: platformReactiveFormController!,
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
    DialogUtil.info(
        content: 'Successfully update method:${method.value!.name}');

    return current;
  }

  Future<void> _onAdd() async {
    PositionComponent? child = modelNode?.nodeFrameComponent?.child;
    if (child != null) {
      method.value = Method('unknownMethod');
      if (methods.value != null) {
        methods.value!.add(method.value!);
        if (child is TypeNodeComponent) {
          child.methodAreaComponent.onAdd(method.value!);
        }
      }
    }
  }

  Future<void> _onDelete() async {
    bool? success = await DialogUtil.confirm(
        content: 'Do you confirm to delete this method:${method.value?.name}');
    if (success != null && success) {
      List<Method>? methods = modelNode?.methods;
      if (methods != null && methods.isNotEmpty) {
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

  List<Widget> _buildRightButton(BuildContext context) {
    return [
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
    ];
  }

  @override
  Widget build(BuildContext context) {
    methods.value = modelNode?.methods;
    Widget listenable = ListenableBuilder(
        listenable: appDataProvider,
        builder: (BuildContext context, Widget? _) {
          Widget child;
          if (appDataProvider.secondaryBodyLandscape) {
            child =
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                  width: appDataProvider.secondaryBodyWidth * 0.4,
                  child: _buildMethodsWidget(context)),
              const VerticalDivider(),
              Expanded(child: _buildPlatformReactiveForm(context))
            ]);
          } else {
            child = Column(children: [
              SizedBox(
                  height: appDataProvider.portraitSize.height * 0.4,
                  child: _buildMethodsWidget(context)),
              const Divider(),
              Expanded(child: _buildPlatformReactiveForm(context))
            ]);
          }
          return child;
        });

    return AppBarView(
        title: title,
        helpPath: routeName,
        withLeading: true,
        rightWidgets: _buildRightButton(context),
        child: listenable);
  }
}
