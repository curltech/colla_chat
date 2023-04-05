import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/material.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:toggle_switch/toggle_switch.dart';

///指定路由样式，不指定则系统判断，系统判断的方法是如果是移动则走全局路由，否则走工作区路由
enum InputType {
  label,
  text,
  password,
  radio,
  checkbox,
  togglebuttons,
  select,
  switcher,
  toggle,
  textarea,
  date,
  time,
  datetime,
  datetimerange,
  calendar,
  custom
}

enum DataType {
  int,
  double,
  string,
  bool,
  date,
  time,
  datetime,
  set,
  list,
  map
}

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

  String? groupName; //分页功能

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
      this.groupName,
      this.formatter,
      this.validator,
      this.autoValidate = false,
      this.onSort,
      this.customWidget});
}

enum ColumnFieldMode { edit, label, custom }

///存储字段的真实值和文本显示值
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

  ///获取真实值
  dynamic get value {
    var controller = _controller;
    if (controller != null) {
      if (columnFieldDef.inputType == InputType.text ||
          columnFieldDef.inputType == InputType.password) {
        String valueStr = controller.text;
        if (valueStr.isNotEmpty) {
          if (columnFieldDef.dataType == DataType.int) {
            _value = int.parse(valueStr);
          } else if (columnFieldDef.dataType == DataType.double) {
            _value = double.parse(valueStr);
          } else if (columnFieldDef.dataType == DataType.string) {
            _value = controller.text;
          }
        } else {
          _value = null;
        }
      }
    }
    return _value;
  }

  ///设置真实值
  set value(dynamic value) {
    var realValue = value;
    String valueStr = '';
    var controller = _controller;
    if (controller != null) {
      if (value != null) {
        if (value is DateTime &&
            (columnFieldDef.inputType == InputType.datetime ||
                columnFieldDef.inputType == InputType.date)) {
          valueStr = value.toLocal().toIso8601String();
          realValue = value.toUtc().toIso8601String();
        } else if (value is TimeOfDay &&
            columnFieldDef.inputType == InputType.time) {
          valueStr = value.toString();
          realValue = value.toString();
        }
      } else {
        valueStr = '';
        realValue = null;
      }
    }
    if (_value != realValue) {
      _value = realValue;
      if (controller != null) {
        controller.text = valueStr;
      }
      _changed = true;
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

const InputBorder textFormFieldBorder =  InputBorder.none;

// const InputBorder textFormFieldBorder = OutlineInputBorder(
//     borderSide: BorderSide.none,
//     borderRadius: BorderRadius.all(Radius.circular(8.0)));

/// 通用列表项，用构造函数传入数据，根据数据构造列表项
class ColumnFieldWidget extends StatefulWidget {
  final ColumnFieldController controller;
  final FocusNode? focusNode;

  const ColumnFieldWidget({
    Key? key,
    required this.controller,
    this.focusNode,
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
      return JsonUtil.toJsonString(v);
    }
    return v;
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
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 14.0),
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
    final value = widget.controller.value;
    var controller = TextEditingController();
    widget.controller.controller = controller;
    final valueStr = value == null ? '' : value.toString();
    controller.value = TextEditingValue(
        text: valueStr,
        selection: TextSelection.fromPosition(TextPosition(
            offset: valueStr.length, affinity: TextAffinity.downstream)));

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
      focusNode: widget.focusNode,
      keyboardType: columnFieldDef.textInputType,
      maxLines: columnFieldDef.maxLines,
      minLines: 1,
      readOnly: columnFieldDef.readOnly,
      decoration: InputDecoration(
          fillColor: Colors.white.withOpacity(AppOpacity.lgOpacity),
          filled: true,
          border: textFormFieldBorder,
          focusedBorder: textFormFieldBorder,
          enabledBorder: textFormFieldBorder,
          errorBorder: textFormFieldBorder,
          disabledBorder: textFormFieldBorder,
          focusedErrorBorder: textFormFieldBorder,
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
    final value = widget.controller.value;
    var controller = TextEditingController();
    widget.controller.controller = controller;
    final valueStr = value == null ? '' : value.toString();
    controller.value = TextEditingValue(
        text: valueStr,
        selection: TextSelection.fromPosition(TextPosition(
            offset: valueStr.length, affinity: TextAffinity.downstream)));

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
      focusNode: widget.focusNode,
      keyboardType: columnFieldDef.textInputType,
      obscureText: !pwdShow,
      decoration: InputDecoration(
          fillColor: Colors.white.withOpacity(AppOpacity.lgOpacity),
          filled: true,
          border: textFormFieldBorder,
          focusedBorder: textFormFieldBorder,
          enabledBorder: textFormFieldBorder,
          errorBorder: textFormFieldBorder,
          disabledBorder: textFormFieldBorder,
          focusedErrorBorder: textFormFieldBorder,
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

  ///多个字符串选择一个，对应的字段是字符串
  Widget _buildRadioField(BuildContext context) {
    widget.controller.controller = null;
    var columnFieldDef = widget.controller.columnFieldDef;
    var label = columnFieldDef.label;
    var options = columnFieldDef.options;
    List<Widget> children = [Text(label)];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        var radio = Radio<String>(
          onChanged: (String? value) {
            widget.controller.value = value;
            setState(() {});
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

  ///多个字符串选择一个，对应的字段是字符串
  Widget _buildToggleField(BuildContext context) {
    widget.controller.controller = null;
    var columnFieldDef = widget.controller.columnFieldDef;
    var label = columnFieldDef.label;
    var options = columnFieldDef.options;
    List<String> labels = [];
    List<IconData?> icons = [];
    String? value = _getInitValue(context);
    int? index;
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        labels.add(AppLocalizations.t(option.label));
        icons.add(option.icon);
        if (value == option.value) {
          index = i;
        }
      }
    }

    var toggleSwitch = ToggleSwitch(
      initialLabelIndex: index,
      activeBgColor: [myself.primary],
      activeFgColor: Colors.white,
      inactiveBgColor: myself.secondary,
      inactiveFgColor: Colors.white,
      totalSwitches: labels.length,
      labels: labels,
      icons: icons,
      onToggle: (index) {
        if (index != null) {
          widget.controller.value = options![index].value;
        } else {
          widget.controller.value = null;
        }
      },
    );

    return Row(children: [Text(label), toggleSwitch]);
  }

  ///多个字符串选择多个，对应的字段是字符串的Set
  Widget _buildCheckboxField(BuildContext context) {
    widget.controller.controller = null;
    var columnFieldDef = widget.controller.columnFieldDef;
    var label = columnFieldDef.label;
    var options = columnFieldDef.options;
    List<Widget> children = [Text(label)];
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
            setState(() {});
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

  ///多个字符串选择多个，对应的字段是字符串的Set
  Widget _buildToggleButtonsField(BuildContext context) {
    widget.controller.controller = null;
    var columnFieldDef = widget.controller.columnFieldDef;
    var label = columnFieldDef.label;
    var options = columnFieldDef.options;
    List<Widget> children = [];
    List<bool> isSelected = [];
    Set<String>? value = _getInitValue(context);
    if (options != null && options.isNotEmpty) {
      value ??= <String>{};
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        children.add(option.leading!);
        if (value.contains(option.value)) {
          isSelected.add(true);
        } else {
          isSelected.add(false);
        }
      }
    }
    var toggleButtons = ToggleButtons(
      onPressed: (int newIndex) {
        isSelected[newIndex] = true;
        Set<String>? value = widget.controller.value;
        var option = options![newIndex];
        if (value!.contains(option.value)) {
          value.remove(option.value);
        } else {
          value.add(option.value);
        }
        widget.controller.value = value;
      },
      isSelected: isSelected,
      children: children,
    );
    var row = Row(
      children: [
        Text(label),
        toggleButtons,
      ],
    );

    return Column(children: children);
  }

  ///适合数据类型为bool
  Widget _buildSwitchField(BuildContext context) {
    widget.controller.controller = null;
    var columnFieldDef = widget.controller.columnFieldDef;
    List<Widget> children = [];
    var prefixIcon = columnFieldDef.prefixIcon;
    if (prefixIcon != null) {
      children.add(prefixIcon);
      children.add(const SizedBox(
        width: 15.0,
      ));
    }
    var label = columnFieldDef.label;
    if (prefixIcon != null) {
      children.add(Text(AppLocalizations.t(label)));
      children.add(const SizedBox(
        width: 20.0,
      ));
    }
    var switcher = Switch(
      activeColor: myself.primary,
      activeTrackColor: Colors.white,
      inactiveThumbColor: myself.secondary,
      inactiveTrackColor: Colors.grey,
      onChanged: (bool? value) {
        widget.controller.value = value;
        setState(() {});
      },
      value: widget.controller.value,
    );
    children.add(switcher);

    return Container(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10.0),
        child: Row(children: children));
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
    String? initialValue = widget.controller.value;
    var valueText = '';
    if (initialValue != null) {
      valueText = DateUtil.toLocal(initialValue);
    }
    var controller = TextEditingController();
    widget.controller.controller = controller;
    controller.value = TextEditingValue(
        text: valueText,
        selection: TextSelection.fromPosition(TextPosition(
            offset: valueText.length, affinity: TextAffinity.downstream)));

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
      focusNode: widget.focusNode,
      keyboardType: columnFieldDef.textInputType,
      readOnly: true,
      decoration: InputDecoration(
          labelText: AppLocalizations.t(columnFieldDef.label),
          prefixIcon: _buildIcon(),
          suffixIcon: IconButton(
              icon: Icon(Icons.date_range, color: myself.primary),
              onPressed: () async {
                DateTime? initialDate;
                if (initialValue != null) {
                  initialDate = DateUtil.toDateTime(initialValue);
                }
                var value =
                    await _showDatePicker(context, initialDate: initialDate);
                widget.controller.value = value;
              }),
          suffix: suffix,
          hintText: columnFieldDef.hintText),
    );

    return textFormField;
  }

  Future<DateTime?> _showDatePicker(BuildContext context,
      {DateTime? initialDate}) {
    initialDate = initialDate ?? DateTime.now();
    return showDatePicker(
      context: context,
      // 初始化选中日期
      initialDate: initialDate,
      // 开始日期
      firstDate: initialDate.subtract(const Duration(days: 365)),
      // 结束日期
      lastDate: initialDate.add(const Duration(days: 365)),
      // 当前日期
      //currentDate: initialDate,
      // 日历弹框样式
      initialEntryMode: DatePickerEntryMode.calendar,
      // 文字方向
      textDirection: TextDirection.ltr,
      // 左上方提示
      helpText: AppLocalizations.t("Current date"),
      // 取消按钮文案
      cancelText: AppLocalizations.t("Cancel"),
      // 确认按钮文案
      confirmText: AppLocalizations.t("Confirm"),
      // 格式错误提示
      errorFormatText: AppLocalizations.t("Date format error"),
      // 输入不在 first 与 last 之间日期提示
      errorInvalidText: AppLocalizations.t("Date range invalid error"),
      // 输入框上方提示
      fieldLabelText: AppLocalizations.t("Date"),
      // 输入框为空时内部提示
      fieldHintText: AppLocalizations.t("Must be not empty"),
      // 日期选择模式，默认为天数选择
      initialDatePickerMode: DatePickerMode.day,
      // 是否为根导航器
      useRootNavigator: true,
      // 设置不可选日期，这里将 2020-10-15，2020-10-16，2020-10-17 三天设置不可选
      // selectableDayPredicate: (dayTime) {
      //   if (dayTime == DateTime(2020, 10, 15) ||
      //       dayTime == DateTime(2020, 10, 16) ||
      //       dayTime == DateTime(2020, 10, 17)) {
      //     return false;
      //   }
      //   return true;
      // }
    );
  }

  Widget _buildInputTime(BuildContext context) {
    String? initialValue = widget.controller.value;
    var valueText = '';
    if (initialValue != null) {
      valueText = initialValue;
    }
    var controller = TextEditingController();
    widget.controller.controller = controller;
    controller.value = TextEditingValue(
        text: valueText,
        selection: TextSelection.fromPosition(TextPosition(
            offset: valueText.length, affinity: TextAffinity.downstream)));

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
      focusNode: widget.focusNode,
      keyboardType: columnFieldDef.textInputType,
      readOnly: true,
      decoration: InputDecoration(
          labelText: AppLocalizations.t(columnFieldDef.label),
          prefixIcon: _buildIcon(),
          suffixIcon: IconButton(
              icon: Icon(Icons.access_time_filled, color: myself.primary),
              onPressed: () async {
                TimeOfDay? initialTime;
                if (initialValue != null) {
                  initialTime = DateUtil.toTime(initialValue);
                }
                var value =
                    await _showTimePicker(context, initialTime: initialTime);
                widget.controller.value = value;
              }),
          suffix: suffix,
          hintText: columnFieldDef.hintText),
    );

    return textFormField;
  }

  Future<TimeOfDay?> _showTimePicker(BuildContext context,
      {TimeOfDay? initialTime}) {
    var now = DateTime.now();
    initialTime = initialTime ?? TimeOfDay(hour: now.hour, minute: now.minute);
    return showTimePicker(
      context: context,
      // 初始化选中日期
      initialTime: initialTime,
      // 日历弹框样式
      initialEntryMode: TimePickerEntryMode.dial,
      // 取消按钮文案
      cancelText: AppLocalizations.t("Cancel"),
      // 确认按钮文案
      confirmText: AppLocalizations.t("Confirm"),
      hourLabelText: AppLocalizations.t("Hour"),
      minuteLabelText: AppLocalizations.t("Minute"),
      // 输入不在 first 与 last 之间日期提示
      errorInvalidText: AppLocalizations.t("Invalid error"),
      useRootNavigator: true,
    );
  }

  Widget _buildInputDateTime(BuildContext context) {
    String? initialValue = widget.controller.value;
    var valueText = '';
    if (initialValue != null) {
      valueText = DateUtil.toLocal(initialValue);
    }
    var controller = TextEditingController();
    widget.controller.controller = controller;
    controller.value = TextEditingValue(
        text: valueText,
        selection: TextSelection.fromPosition(TextPosition(
            offset: valueText.length, affinity: TextAffinity.downstream)));
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
      focusNode: widget.focusNode,
      keyboardType: columnFieldDef.textInputType,
      readOnly: true,
      decoration: InputDecoration(
          labelText: AppLocalizations.t(columnFieldDef.label),
          prefixIcon: _buildIcon(),
          suffixIcon: IconButton(
              icon: Icon(Icons.date_range, color: myself.primary),
              onPressed: () async {
                DateTime? initialDate;
                if (initialValue != null) {
                  initialDate = DateUtil.toDateTime(initialValue);
                }
                var value = await _showDateTimePicker(context,
                    initialDate: initialDate);
                widget.controller.value = value;
              }),
          suffix: suffix,
          hintText: columnFieldDef.hintText),
    );

    return textFormField;
  }

  Future<DateTime?> _showDateTimePicker(BuildContext context,
      {DateTime? initialDate}) {
    initialDate = initialDate ?? DateTime.now();
    return showOmniDateTimePicker(
      context: context,
      initialDate: initialDate,
      // 开始日期
      firstDate: initialDate.subtract(const Duration(days: 365)),
      // 结束日期
      lastDate: initialDate.add(const Duration(days: 365)),
      is24HourMode: true,
      isShowSeconds: false,
      minutesInterval: 1,
      secondsInterval: 1,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      constraints: const BoxConstraints(
        maxWidth: 350,
        maxHeight: 650,
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1.drive(
            Tween(
              begin: 0,
              end: 1,
            ),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: true,
      selectableDayPredicate: (dateTime) {
        // Disable 25th Feb 2023
        if (dateTime == DateTime(2023, 2, 25)) {
          return false;
        } else {
          return true;
        }
      },
    );
  }

  _showDateTimeRangePicker(BuildContext context,
      {DateTime? startInitialDate, DateTime? endInitialDate}) {
    startInitialDate = startInitialDate ?? DateTime.now();
    endInitialDate = endInitialDate ?? DateTime.now();
    return showOmniDateTimeRangePicker(
      context: context,
      startInitialDate: startInitialDate,
      startFirstDate: startInitialDate.subtract(const Duration(days: 365)),
      startLastDate: startInitialDate.add(const Duration(days: 365)),
      endInitialDate: endInitialDate,
      endFirstDate: endInitialDate.subtract(const Duration(days: 365)),
      endLastDate: endInitialDate.add(const Duration(days: 365)),
      is24HourMode: true,
      isShowSeconds: false,
      minutesInterval: 1,
      secondsInterval: 1,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      constraints: const BoxConstraints(
        maxWidth: 350,
        maxHeight: 650,
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1.drive(
            Tween(
              begin: 0,
              end: 1,
            ),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: true,
      // selectableDayPredicate: (dateTime) {
      //   // Disable 25th Feb 2023
      //   if (dateTime == DateTime(2023, 2, 25)) {
      //     return false;
      //   } else {
      //     return true;
      //   }
      // },
    );
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
        case InputType.togglebuttons:
          columnFieldWidget = _buildToggleButtonsField(context);
          break;
        case InputType.checkbox:
          columnFieldWidget = _buildCheckboxField(context);
          break;
        case InputType.radio:
          columnFieldWidget = _buildRadioField(context);
          break;
        case InputType.select:
          columnFieldWidget = _buildDropdownButton(context);
          break;
        case InputType.toggle:
          columnFieldWidget = _buildToggleField(context);
          break;
        case InputType.switcher:
          columnFieldWidget = _buildSwitchField(context);
          break;
        case InputType.date:
          columnFieldWidget = _buildInputDate(context);
          break;
        case InputType.time:
          columnFieldWidget = _buildInputTime(context);
          break;
        case InputType.datetime:
          columnFieldWidget = _buildInputDateTime(context);
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
