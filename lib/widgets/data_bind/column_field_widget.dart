import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/material.dart';

///指定路由样式，不指定则系统判断，系统判断的方法是如果是移动则走全局路由，否则走工作区路由
enum InputType {
  label,
  text,
  password,
  radio,
  checkbox,
  select,
  textarea,
  date,
  time,
  custom
}

enum DataType { int, double, string, bool, date, time, set, list, map }

/// 通用列表项的数据模型
class ColumnFieldDef {
  final String name;
  final String label;
  final InputType inputType;
  final DataType dataType;
  dynamic initValue;

  //图标
  final Widget? prefixIcon;

  //头像
  final String? avatar;

  final String? hintText;

  final TextInputType? textInputType;

  final Widget? suffixIcon;

  final bool cancel;

  final int? maxLines;

  bool readOnly;

  final List<Option>? options;

  final bool enableColumnFilter = false;

  final Function(dynamic value)? formatter;

  final Function(String value)? validator;

  final bool autoValidate;

  Function(int, bool)? onSort;

  final Widget? customWidget;

  ColumnFieldDef(
      {required this.name,
      required this.label,
      this.inputType = InputType.text,
      this.dataType = DataType.string,
      this.initValue = '',
      this.prefixIcon,
      this.avatar,
      this.hintText,
      this.textInputType = TextInputType.text,
      this.suffixIcon,
      this.cancel = false,
      this.maxLines = 4,
      this.readOnly = false,
      this.options,
      this.formatter,
      this.validator,
      this.autoValidate = false,
      this.onSort,
      this.customWidget});
}

enum ColumnFieldMode { edit, label, custom }

class ColumnFieldController with ChangeNotifier {
  final ColumnFieldDef columnFieldDef;

  //非文本框的值
  dynamic _value;
  dynamic _flag;
  bool _changed = false;

  //文本框的值
  TextEditingController? _controller;
  late ColumnFieldMode _mode;

  ColumnFieldController(this.columnFieldDef,
      {dynamic value,
      dynamic flag,
      TextEditingController? controller,
      ColumnFieldMode mode = ColumnFieldMode.label}) {
    _value = value;
    _flag = flag;
    _controller = controller;
    _mode = mode;
  }

  dynamic get value {
    var controller = _controller;
    if (controller != null) {
      return controller.text;
    } else {
      return _value;
    }
  }

  set value(dynamic value) {
    var controller = _controller;
    if (controller != null) {
      if (controller.text != value) {
        controller.text = value;
        _changed = true;
      }
    }
    if (_value != value) {
      _value = value;
      _changed = true;
      notifyListeners();
    }
  }

  dynamic get flag {
    return _flag;
  }

  set flag(dynamic flag) {
    if (_flag != flag) {
      _flag = flag;
      notifyListeners();
    }
  }

  bool get changed {
    return _changed;
  }

  set changed(bool changed) {
    if (_changed != changed) {
      _changed = changed;
    }
  }

  ColumnFieldMode get mode {
    return _mode;
  }

  set mode(ColumnFieldMode mode) {
    if (_mode != mode) {
      _mode = mode;
      notifyListeners();
    }
  }

  set controller(TextEditingController? controller) {
    _controller = controller;
  }

  clear() {
    var controller = _controller;
    if (controller != null) {
      controller.clear();
    } else {
      if (mode == ColumnFieldMode.label ||
          columnFieldDef.inputType == InputType.label) {
      } else {
        if (_value != null) {
          _value = null;
          notifyListeners();
        }
      }
    }
  }
}

/// 通用列表项，用构造函数传入数据，根据数据构造列表项
class ColumnFieldWidget extends StatefulWidget {
  final ColumnFieldController controller;

  const ColumnFieldWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ColumnFieldWidgetState();
  }
}

class _ColumnFieldWidgetState extends State<ColumnFieldWidget> {
  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  //获取初始化值，传入的初始值或者定义的初始值
  dynamic _getInitValue(BuildContext context) {
    var dataType = widget.controller.columnFieldDef.dataType;
    dynamic v =
        widget.controller.value ?? widget.controller.columnFieldDef.initValue;
    if (dataType == DataType.set ||
        dataType == DataType.list ||
        dataType == DataType.map) {
      return v;
    }
    if (v == null) {
      return '';
    }
    if (dataType == DataType.date) {
      var d = v as DateTime;
      return d.toUtc().toIso8601String();
    }
    return v.toString();
  }

  Widget? _buildIcon() {
    Widget? icon = widget.controller.columnFieldDef.prefixIcon;
    if (icon == null) {
      final avatar = widget.controller.columnFieldDef.avatar;
      if (avatar != null) {
        icon = ImageUtil.buildImageWidget(image: avatar);
      }
    }

    return icon;
  }

  Widget _buildLabel(BuildContext context) {
    widget.controller.controller = null;
    String label = widget.controller.columnFieldDef.label;
    label = '${AppLocalizations.t(label)}:';
    final value = widget.controller.value ?? '';
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildIcon()!,
          const SizedBox(
            width: 10.0,
          ),
          Text(label),
          const SizedBox(
            width: 10.0,
          ),
          Expanded(child: Text(value.toString(), textAlign: TextAlign.start))
        ]));
  }

  Widget _buildTextFormField(BuildContext context) {
    final value = widget.controller.value == null
        ? ''
        : widget.controller.value.toString();
    var controller = TextEditingController();
    controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.fromPosition(TextPosition(
            offset: value.length, affinity: TextAffinity.downstream)));
    widget.controller.controller = controller;
    var columnFieldDef = widget.controller.columnFieldDef;
    var suffixIcon = columnFieldDef.suffixIcon;
    Widget? suffix;
    if (columnFieldDef.cancel) {
      suffix = controller.text.isNotEmpty
          ? IconButton(
              //如果文本长度不为空则显示清除按钮
              onPressed: () {
                controller.clear();
              },
              icon: Icon(
                Icons.cancel,
                color: myself.primary,
              ))
          : null;

      if (suffixIcon == null) {
        suffixIcon = suffix;
        suffix = null;
      }
    }
    String label = AppLocalizations.t(columnFieldDef.label);
    var textFormField = TextFormField(
      controller: controller,
      keyboardType: columnFieldDef.textInputType,
      maxLines: columnFieldDef.maxLines,
      minLines: 1,
      readOnly: columnFieldDef.readOnly,
      decoration: InputDecoration(
          fillColor: Colors.grey.withOpacity(AppOpacity.xlOpacity),
          filled: true,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          labelText: label,
          prefixIcon: _buildIcon(),
          suffixIcon: suffixIcon,
          suffix: suffix,
          hintText: columnFieldDef.hintText),
    );

    return textFormField;
  }

  Widget _buildPasswordField(BuildContext context) {
    bool pwdShow = widget.controller.flag ?? false;
    final value = widget.controller.value ?? '';
    var controller = TextEditingController();
    controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.fromPosition(TextPosition(
            offset: value.length, affinity: TextAffinity.downstream)));
    widget.controller.controller = controller;
    var columnFieldDef = widget.controller.columnFieldDef;
    Widget? suffix;
    if (columnFieldDef.cancel) {
      suffix = controller.text.isNotEmpty
          ? IconButton(
              //如果文本长度不为空则显示清除按钮
              onPressed: () {
                controller.clear();
              },
              icon: Icon(
                Icons.cancel,
                color: myself.primary,
              ))
          : null;
    }
    var textFormField = TextFormField(
      controller: controller,
      keyboardType: columnFieldDef.textInputType,
      obscureText: !pwdShow,
      decoration: InputDecoration(
          fillColor: Colors.grey.withOpacity(AppOpacity.xlOpacity),
          filled: true,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          labelText: AppLocalizations.t(columnFieldDef.label),
          prefixIcon: _buildIcon(),
          suffixIcon: IconButton(
            icon: Icon(
              pwdShow ? Icons.visibility_off : Icons.visibility,
              color: myself.primary,
            ),
            onPressed: () {
              setState(() {
                widget.controller.value = controller.value.text;
                widget.controller.flag = !pwdShow;
              });
            },
          ),
          suffix: suffix,
          hintText: columnFieldDef.hintText),
    );
    return textFormField;
  }

  Widget _buildRadioField(BuildContext context) {
    widget.controller.controller = null;
    var columnFieldDef = widget.controller.columnFieldDef;
    var options = columnFieldDef.options;
    List<Widget> children = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        var radio = Radio<String>(
          onChanged: (String? value) {
            widget.controller.value = value;
          },
          value: option.value,
          groupValue: _getInitValue(context),
        );
        var row = Row(
          children: [radio, Text(option.label)],
        );
        children.add(row);
      }
    }

    return Column(children: children);
  }

  Widget _buildCheckboxField(BuildContext context) {
    widget.controller.controller = null;
    var columnFieldDef = widget.controller.columnFieldDef;
    var options = columnFieldDef.options;
    List<Widget> children = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        Set<String>? value = _getInitValue(context);
        value ??= <String>{};
        var checkbox = Checkbox(
          onChanged: (bool? selected) {
            if (value != null) {
              if (selected == null || !selected) {
                value.remove(option.value);
              } else if (selected) {
                value.add(option.value);
              }
            }
            widget.controller.value = value;
          },
          value: value.contains(option.value),
        );
        var row = Row(
          children: [checkbox, Text(option.label)],
        );
        children.add(row);
      }
    }

    return Column(children: children);
  }

  Widget _buildSwitchField(BuildContext context) {
    widget.controller.controller = null;
    var columnFieldDef = widget.controller.columnFieldDef;
    var options = columnFieldDef.options;
    List<Widget> children = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        Set<String>? value = _getInitValue(context);
        value ??= <String>{};
        var checkbox = Switch(
          onChanged: (bool? selected) {
            if (value != null) {
              if (selected == null || !selected) {
                value.remove(option.value);
              } else if (selected) {
                value.add(option.value);
              }
            }
            widget.controller.value = value;
          },
          value: value.contains(option.value),
        );
        var row = Row(
          children: [checkbox, Text(option.label)],
        );
        children.add(row);
      }
    }

    return Column(children: children);
  }

  Widget _buildDropdownButton(BuildContext context) {
    widget.controller.controller = null;
    var columnFieldDef = widget.controller.columnFieldDef;
    var options = columnFieldDef.options;
    List<DropdownMenuItem<String>> children = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        var item = DropdownMenuItem<String>(
          value: option.value,
          child: Text(option.label),
        );
        children.add(item);
      }
    }
    var dropdownButton = Row(children: [
      Text(AppLocalizations.t(columnFieldDef.label)),
      const Spacer(),
      DropdownButton<String>(
        dropdownColor: Colors.grey.withOpacity(0.7),
        underline: Container(),
        hint: Text(AppLocalizations.t(columnFieldDef.hintText ?? '')),
        elevation: 0,
        value: widget.controller.value,
        items: children,
        onChanged: (String? value) {
          widget.controller.value = value;
          setState(() {});
        },
      )
    ]);

    return dropdownButton;
  }

  Widget _buildInputDate(BuildContext context) {
    var controller = TextEditingController();
    var value = widget.controller.value ?? '';
    controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.fromPosition(TextPosition(
            offset: value.length, affinity: TextAffinity.downstream)));
    widget.controller.controller = controller;
    var columnFieldDef = widget.controller.columnFieldDef;
    Widget? suffix;
    if (columnFieldDef.cancel) {
      suffix = controller.text.isNotEmpty
          ? IconButton(
              //如果文本长度不为空则显示清除按钮
              onPressed: () {
                controller.clear();
              },
              icon: const Icon(Icons.cancel, color: Colors.grey))
          : null;
    }
    var textFormField = TextFormField(
      controller: controller,
      keyboardType: columnFieldDef.textInputType,
      readOnly: true,
      decoration: InputDecoration(
          labelText: AppLocalizations.t(columnFieldDef.label),
          prefixIcon: _buildIcon(),
          suffixIcon:
              IconButton(icon: const Icon(Icons.date_range), onPressed: () {}),
          suffix: suffix,
          hintText: columnFieldDef.hintText),
    );

    return textFormField;
  }

  _showDatePicker(BuildContext context, TextEditingController controller) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      // 初始化选中日期
      firstDate: DateTime(2018, 6),
      // 开始日期
      lastDate: DateTime(2025, 6),
      // 结束日期
      currentDate: DateTime(2020, 10, 20),
      // 当前日期
      helpText: "helpText",
      // 左上方提示
      cancelText: "cancelText",
      // 取消按钮文案
      confirmText: "confirmText", // 确认按钮文案
    ).then((value) {
      if (value != null) {
        controller.text = value.toUtc().toIso8601String();
      }
    });
  }

  _showDatePickerInput(BuildContext context) {
    showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        // 初始化选中日期
        firstDate: DateTime(2020, 6),
        // 开始日期
        lastDate: DateTime(2021, 6),
        // 结束日期
        initialEntryMode: DatePickerEntryMode.input,
        // 日历弹框样式

        textDirection: TextDirection.ltr,
        // 文字方向

        currentDate: DateTime(2020, 10, 20),
        // 当前日期
        helpText: "helpText",
        // 左上方提示
        cancelText: "cancelText",
        // 取消按钮文案
        confirmText: "confirmText",
        // 确认按钮文案

        errorFormatText: "errorFormatText",
        // 格式错误提示
        errorInvalidText: "errorInvalidText",
        // 输入不在 first 与 last 之间日期提示

        fieldLabelText: "fieldLabelText",
        // 输入框上方提示
        fieldHintText: "fieldHintText",
        // 输入框为空时内部提示

        initialDatePickerMode: DatePickerMode.day,
        // 日期选择模式，默认为天数选择
        useRootNavigator: true,
        // 是否为根导航器
        // 设置不可选日期，这里将 2020-10-15，2020-10-16，2020-10-17 三天设置不可选
        selectableDayPredicate: (dayTime) {
          if (dayTime == DateTime(2020, 10, 15) ||
              dayTime == DateTime(2020, 10, 16) ||
              dayTime == DateTime(2020, 10, 17)) {
            return false;
          }
          return true;
        });
  }

  CalendarDatePicker _calendarDatePicker(DatePickerMode mode) {
    return CalendarDatePicker(
        initialDate: DateTime.now(),
        // 初始化选中日期
        currentDate: DateTime(2020, 10, 18),
        firstDate: DateTime(2020, 9, 10),
        // 开始日期
        lastDate: DateTime(2022, 9, 10),
        // 结束日期
        initialCalendarMode: mode,
        // 日期选择样式
        // 选中日期改变回调函数
        onDateChanged: (dateTime) {
          logger.i("onDateChanged $dateTime");
        },
        // 月份改变回调函数
        onDisplayedMonthChanged: (dateTime) {
          logger.i("onDisplayedMonthChanged $dateTime");
        },
        // 筛选日期可不可点回调函数
        selectableDayPredicate: (dayTime) {
          if (dayTime == DateTime(2020, 10, 15) ||
              dayTime == DateTime(2020, 10, 16) ||
              dayTime == DateTime(2020, 10, 17)) {
            return false;
          }
          return true;
        });
  }

  @override
  Widget build(BuildContext context) {
    Widget columnFieldWidget;
    var mode = widget.controller.mode;
    if (mode == ColumnFieldMode.custom) {
      var customWidget = widget.controller.columnFieldDef.customWidget;
      if (customWidget != null) {
        columnFieldWidget = customWidget;
        return columnFieldWidget;
      }
    }
    if (mode == ColumnFieldMode.label) {
      columnFieldWidget = _buildLabel(context);
    } else if (mode == ColumnFieldMode.edit) {
      var inputType = widget.controller.columnFieldDef.inputType;
      switch (inputType) {
        case InputType.label:
          columnFieldWidget = _buildLabel(context);
          break;
        case InputType.text:
          columnFieldWidget = _buildTextFormField(context);
          break;
        case InputType.password:
          columnFieldWidget = _buildPasswordField(context);
          break;
        default:
          columnFieldWidget = _buildTextFormField(context);
      }
    } else {
      columnFieldWidget = _buildTextFormField(context);
    }
    return columnFieldWidget;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
