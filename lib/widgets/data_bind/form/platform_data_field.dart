import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_forms/reactive_forms.dart';

///指定路由样式，不指定则系统判断，系统判断的方法是如果是移动则走全局路由，否则走工作区路由
enum InputType {
  label,
  text,
  password,
  radio,
  checkbox,
  toggleButtons,
  toggleSwitch,
  select,
  switcher,
  toggle,
  textarea,
  date,
  time,
  datetime,
  datetimeRange,
  calendar,
  custom,
  pinput,
  color
}

enum DataType {
  int,
  double,
  num,
  string,
  bool,
  date,
  time,
  datetime,
  percentage,
  set,
  list,
  map
}

/// 表的列定义
class PlatformDataColumn {
  final String name;
  final String label;
  final InputType inputType;
  final DataType dataType;
  final Alignment align;
  final double? width;
  final Color? positiveColor;
  final Color? negativeColor;
  final String? hintText;
  final Widget Function(int, dynamic)? buildSuffix;
  final Function(int, bool)? onSort;

  PlatformDataColumn(
      {required this.name,
      required this.label,
      this.hintText,
      this.dataType = DataType.string,
      this.positiveColor,
      this.negativeColor,
      this.inputType = InputType.label,
      this.width,
      this.align = Alignment.centerLeft,
      this.buildSuffix,
      this.onSort});
}

/// 表单的字段定义
class PlatformDataField<T> {
  final String name;
  final String label;
  final InputType inputType;
  final DataType dataType;
  dynamic initValue;

  //图标
  final Widget? prefixIcon;

  final Widget? prefix;

  //头像
  final String? avatar;

  final String? hintText;

  final TextInputType? textInputType;

  final Widget? suffixIcon;

  final Widget? suffix;

  final bool cancel;

  final double? width;

  final int? length;

  final int? minLines;

  final int? maxLines;

  bool readOnly;

  bool autofocus;

  final List<Option<T>>? options;

  String? groupName; //分页功能

  final bool enableColumnFilter = false;

  final List<TextInputFormatter>? inputFormatters;

  final String? Function(T?)? validator;

  final List<Validator<T>>? validators;

  final Map<String, String Function(Object)>? validationMessages;

  final void Function(dynamic)? onChanged;

  final void Function()? onEditingComplete;

  final dynamic Function(dynamic)? onFieldSubmitted;

  final bool autoValidate;

  Function(int, bool)? onSort;

  final Widget? customWidget;

  PlatformDataField({
    required this.name,
    required this.label,
    this.inputType = InputType.text,
    this.dataType = DataType.string,
    this.initValue,
    this.prefixIcon,
    this.prefix,
    this.avatar,
    this.hintText,
    this.textInputType = TextInputType.text,
    this.suffixIcon,
    this.suffix,
    this.cancel = false,
    this.minLines = 1,
    this.maxLines = 4,
    this.length,
    this.width,
    this.readOnly = false,
    this.autofocus = false,
    this.options,
    this.groupName,
    this.inputFormatters,
    this.validator,
    this.validators,
    this.validationMessages,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.autoValidate = false,
    this.onSort,
    this.customWidget,
  });
}

class FormButton {
  final String label;
  ButtonStyle? buttonStyle;
  Widget? icon;
  String? tooltip;
  Function(Map<String, dynamic> values)? onTap;

  FormButton(
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

const InputBorder textFormFieldBorder = UnderlineInputBorder(
    borderSide: BorderSide.none,
    borderRadius: BorderRadius.all(Radius.circular(4.0)));

const InputBorder outlineTextFormFieldBorder = OutlineInputBorder(
    borderSide: BorderSide(
      color: Colors.white,
      width: 1.0,
    ),
    borderRadius: BorderRadius.all(Radius.circular(4.0)));

InputDecoration buildInputDecoration({
  Color? fillColor,
  Color? focusColor,
  Color? hoverColor,
  Widget? prefixIcon,
  Widget? prefix,
  Widget? suffixIcon,
  Widget? suffix,
  String? hintText,
  String? labelText,
}) {
  InputDecoration inputDecoration = InputDecoration(
      fillColor: fillColor ?? Colors.grey.withAlpha(AppOpacity.xlOpacity),
      focusColor: focusColor ?? Colors.grey.withAlpha(AppOpacity.xlOpacity),
      hoverColor: hoverColor ?? Colors.grey.withAlpha(AppOpacity.xlOpacity),
      filled: true,
      border: textFormFieldBorder,
      focusedBorder: outlineTextFormFieldBorder,
      enabledBorder: textFormFieldBorder,
      errorBorder: textFormFieldBorder,
      disabledBorder: textFormFieldBorder,
      focusedErrorBorder: textFormFieldBorder,
      labelText: labelText,
      prefixIcon: prefixIcon,
      prefix: prefix,
      suffixIcon: suffixIcon,
      suffix: suffix,
      hintText: hintText);

  return inputDecoration;
}
