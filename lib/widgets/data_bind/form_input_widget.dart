import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:provider/provider.dart';

class FormInputController with ChangeNotifier {
  final List<PlatformDataField> columnFieldDefs;
  final Map<String, dynamic> _values = {};

  final Map<String, DataFieldController> controllers = {};
  EntityState? state;

  FormInputController(this.columnFieldDefs,
      {Map<String, dynamic> initValues = const {}, this.state}) {
    for (var columnFieldDef in columnFieldDefs) {
      String name = columnFieldDef.name;
      var initValue = initValues[name];
      initValue ??= columnFieldDef.initValue;
      setValue(name, initValue);
    }
    var state = _values['state'];
    if (state != null) {
      state = state;
    }
  }

  setController(String name, DataFieldController controller) {
    controllers[name] = controller;
  }

  clear() {
    for (var controller in controllers.values) {
      controller.clear();
    }
  }

  ///加入数据类型与值不匹配，将字符串转换成合适类型
  _adjustValues(Map<String, dynamic> values) {
    for (var columnFieldDef in columnFieldDefs) {
      String name = columnFieldDef.name;
      if (values.containsKey(name)) {
        DataType dataType = columnFieldDef.dataType;
        dynamic value = values[name];
        if (value == null) {
          continue;
        }
        if (value is String && dataType == DataType.string) {
          continue;
        }
        if (value is String && dataType != DataType.string) {
          var v = StringUtil.toObject(value, dataType);
          if (v == null) {
            values.remove(name);
          } else {
            values[name] = v;
          }
        }
      }
    }
  }

  ///获取真实值，控制器的值优先
  dynamic getValue(String name) {
    var controller = controllers[name];
    if (controller != null) {
      return controller.value;
    }
    return _values[name];
  }

  ///获取所有真实值
  dynamic getValues() {
    Map<String, dynamic> values = {};
    for (var columnFieldDefs in columnFieldDefs) {
      String name = columnFieldDefs.name;
      values[name] = getValue(name);
      if (state == null) {
        if (controllers.containsKey(name)) {
          DataFieldController controller = controllers[name]!;
          bool changed = controller.changed;
          if (changed) {
            state = EntityState.update;
          }
        }
      }
    }
    if (state != null) {
      values['state'] = state;
    }
    _adjustValues(values);

    return values;
  }

  ///外部设置值
  setValue(String name, dynamic value) {
    _values[name] = value;
    if (controllers.containsKey(name)) {
      var controller = controllers[name];
      if (controller != null) {
        controller.value = value;
      }
    }
  }

  setValues(Map<String, dynamic> values) {
    for (var columnFieldDef in columnFieldDefs) {
      var name = columnFieldDef.name;
      if (values.containsKey(name)) {
        var value = values[name];
        setValue(name, value);
      } else {
        setValue(name, null);
      }
    }
  }
}

class FormButtonDef {
  final String label;
  ButtonStyle? buttonStyle;
  Widget? icon;
  String? tooltip;
  Function(Map<String, dynamic> values)? onTap;

  FormButtonDef(
      {required this.label,
      this.buttonStyle,
      this.icon,
      this.tooltip,
      this.onTap}) {
    buttonStyle = buttonStyle ??
        StyleUtil.buildButtonStyle(
            backgroundColor: myself.primary, elevation: 10.0);
  }
}

class FormInputWidget extends StatefulWidget {
  final FormInputController controller;
  final List<FormButtonDef>? formButtonDefs;
  final Function(Map<String, dynamic> values)? onOk;
  final String okLabel;
  final double height; //高度
  final MainAxisAlignment mainAxisAlignment;
  final double spacing;
  final double buttonSpacing;
  final List<Widget>? heads;
  final List<Widget>? tails;

  const FormInputWidget({
    Key? key,
    required this.controller,
    this.formButtonDefs,
    this.onOk,
    this.okLabel = 'Ok',
    required this.height,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.spacing = 0.0,
    this.buttonSpacing = 10.0,
    this.heads,
    this.tails,
  }) : super(key: key);

  @override
  State createState() => _FormInputWidgetState();
}

class _FormInputWidgetState extends State<FormInputWidget> {
  final Map<String, FocusNode> focusNodes = {};

  @override
  initState() {
    super.initState();
  }

  ///创建KeyboardActionsConfig钩住所有的字段
  KeyboardActionsConfig _buildKeyboardActionsConfig(BuildContext context) {
    List<KeyboardActionsItem> actions = [];
    for (var i = 0; i < widget.controller.columnFieldDefs.length; i++) {
      PlatformDataField columnFieldDef = widget.controller.columnFieldDefs[i];
      var name = columnFieldDef.name;
      var inputType = columnFieldDef.inputType;
      if (inputType == InputType.text ||
          inputType == InputType.password ||
          inputType == InputType.textarea) {
        var focusNode = FocusNode();
        focusNodes[name] = focusNode;
        KeyboardActionsItem action = KeyboardActionsItem(
          focusNode: focusNode,
          displayActionBar: false,
          displayArrows: false,
          displayDoneButton: false,
        );
        actions.add(action);
      }
    }
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: myself.primary,
      nextFocus: false,
      actions: actions,
    );
  }

  List<Widget> _buildFormViews(BuildContext context) {
    Map<String, List<Widget>> viewMap = {};
    for (var i = 0; i < widget.controller.columnFieldDefs.length; i++) {
      PlatformDataField columnFieldDef = widget.controller.columnFieldDefs[i];
      String? groupName = columnFieldDef.groupName;
      groupName = groupName ?? '';
      List<Widget>? children = viewMap[groupName];
      if (children == null) {
        children = <Widget>[];
        viewMap[groupName] = children;
      }
      if (i == 0 && widget.heads != null) {
        children.addAll(widget.heads!);
      }
      children.add(SizedBox(
        height: widget.spacing,
      ));
      String name = columnFieldDef.name;
      DataFieldController? columnFieldController =
          widget.controller.controllers[name];
      dynamic value = widget.controller.getValue(name);
      if (columnFieldController == null) {
        columnFieldController = DataFieldController(
          columnFieldDef,
          value: value,
        );
        widget.controller
            .setController(columnFieldDef.name, columnFieldController);
      } else {
        columnFieldController.value = value;
      }
      Widget columnFieldWidget = DataFieldWidget(
        controller: columnFieldController,
        focusNode: focusNodes[name],
      );
      children.add(columnFieldWidget);
      if (i == widget.controller.columnFieldDefs.length - 1) {
        if (widget.tails != null) {
          children.addAll(widget.tails!);
        }
      }
    }
    List<Widget> views = <Widget>[];
    for (var groupName in viewMap.keys) {
      List<Widget>? children = viewMap[groupName];
      var view = KeyboardActions(
          config: _buildKeyboardActionsConfig(context),
          child: Column(
              mainAxisAlignment: widget.mainAxisAlignment,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children!));
      views.add(view);
    }
    return views;
  }

  Widget _buildButtonBar(BuildContext context) {
    ButtonStyle style = StyleUtil.buildButtonStyle();
    ButtonStyle mainStyle = StyleUtil.buildButtonStyle(
        backgroundColor: myself.primary, elevation: 10.0);
    List<Widget> btns = [
      TextButton(
        style: style,
        child: CommonAutoSizeText(AppLocalizations.t('Reset')),
        onPressed: () {
          widget.controller.clear();
        },
      )
    ];
    if (widget.formButtonDefs == null) {
      btns.add(TextButton(
        style: mainStyle,
        child: CommonAutoSizeText(AppLocalizations.t(widget.okLabel)),
        onPressed: () {
          if (widget.onOk != null) {
            var values = widget.controller.getValues();
            widget.onOk!(values);
          }
        },
      ));
    } else {
      for (FormButtonDef formButtonDef in widget.formButtonDefs!) {
        btns.add(TextButton(
          style: formButtonDef.buttonStyle,
          child: CommonAutoSizeText(AppLocalizations.t(formButtonDef.label)),
          onPressed: () {
            if (formButtonDef.onTap != null) {
              var values = widget.controller.getValues();
              formButtonDef.onTap!(values);
            }
          },
        ));
      }
    }

    return ButtonBar(children: btns);
  }

  Widget _buildFormSwiper(BuildContext context) {
    List<Widget> views = _buildFormViews(context);
    if (views.length > 1) {
      return SizedBox(
          height: widget.height, //最大高度
          child: Swiper(
            controller: SwiperController(),
            itemCount: views.length,
            index: 0,
            itemBuilder: (BuildContext context, int index) {
              return views[index];
            },
            onIndexChanged: (int index) {
              logger.i('changed to index $index');
            },
            // pagination: SwiperPagination(
            //     builder: DotSwiperPaginationBuilder(
            //   activeColor: myself.primary,
            //   color: Colors.white,
            //   activeSize: 15,
            // )),
          ));
    } else if (views.length == 1) {
      return SizedBox(height: widget.height, child: views[0]);
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        builder: (BuildContext context, Widget? child) {
      return Column(children: [
        _buildFormSwiper(context),
        SizedBox(
          height: widget.buttonSpacing,
        ),
        _buildButtonBar(context),
      ]);
    }, create: (BuildContext context) {
      return widget.controller;
    });
  }
}
