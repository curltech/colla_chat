import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:provider/provider.dart';

class FormInputController with ChangeNotifier {
  final List<ColumnFieldDef> columnFieldDefs;
  final Map<String, ColumnFieldController> controllers = {};
  EntityState? state;

  FormInputController(this.columnFieldDefs, {this.state});

  setController(String name, ColumnFieldController controller) {
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

  //获取真实值
  dynamic getValue(String name) {
    var controller = controllers[name];
    if (controller != null) {
      return controller.value;
    }
  }

  //获取所有真实值
  dynamic getValues() {
    Map<String, dynamic> values = {};
    for (var entry in controllers.entries) {
      String name = entry.key;
      values[name] = entry.value.value;
      if (state == null) {
        bool changed = entry.value.changed;
        if (changed) {
          state = EntityState.update;
        }
      }
    }
    if (state != null) {
      values['state'] = state;
    }
    _adjustValues(values);

    return values;
  }

  ///内部改变值
  changeValue(String name, dynamic value) {
    var controller = controllers[name];
    if (controller != null) {
      controller.value = value;
    }
  }

  ///外部设置值
  setValue(String name, dynamic value) {
    var controller = controllers[name];
    if (controller != null) {
      controller.value = value;
    }
  }

  setValues(Map<String, dynamic> values) {
    for (var entry in controllers.entries) {
      var name = entry.key;
      var value = values[name];
      var controller = entry.value;
      if (controller.value != value) {
        controller.value = value;
      }
    }
  }

  ///外部设置值
  setMode(String name, ColumnFieldMode mode) {
    var controller = controllers[name];
    if (controller != null) {
      controller.mode = mode;
    }
  }
}

class FormInputWidget extends StatefulWidget {
  final Map<String, dynamic>? initValues;
  late final FormInputController controller;

  final Function(Map<String, dynamic>)? onOk;
  final String okLabel;
  final String resetLabel;
  final double height; //高度
  final MainAxisAlignment mainAxisAlignment;
  final double spacing;
  final double buttonSpacing;
  final List<Widget>? heads;
  final List<Widget>? tails;

  FormInputWidget({
    Key? key,
    required List<ColumnFieldDef> columnFieldDefs,
    this.initValues,
    this.onOk,
    this.okLabel = 'Ok',
    this.resetLabel = 'Reset',
    required this.height,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.spacing = 0.0,
    this.buttonSpacing = 10.0,
    this.heads,
    this.tails,
  }) : super(key: key) {
    controller = FormInputController(columnFieldDefs);
    if (initValues != null) {
      var state = initValues!['state'];
      if (state != null) {
        controller.state = state;
      }
    }
  }

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
      ColumnFieldDef columnFieldDef = widget.controller.columnFieldDefs[i];
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
      ColumnFieldDef columnFieldDef = widget.controller.columnFieldDefs[i];
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
      dynamic initValue;
      if (widget.initValues == null) {
        initValue = columnFieldDef.initValue;
      } else {
        initValue = widget.initValues![name];
      }
      ColumnFieldController columnFieldController = ColumnFieldController(
          columnFieldDef,
          value: initValue,
          mode: ColumnFieldMode.edit);
      widget.controller
          .setController(columnFieldDef.name, columnFieldController);
      Widget columnFieldWidget = ColumnFieldWidget(
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
    if (widget.onOk != null) {
      return ButtonBar(children: [
        TextButton(
          style: style,
          child: CommonAutoSizeText(AppLocalizations.t(widget.resetLabel)),
          onPressed: () {
            widget.controller.clear();
          },
        ),
        TextButton(
          style: mainStyle,
          child: CommonAutoSizeText(AppLocalizations.t(widget.okLabel)),
          onPressed: () {
            var values = widget.controller.getValues();
            widget.onOk!(values);
          },
        ),
      ]);
    }
    return Container();
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
