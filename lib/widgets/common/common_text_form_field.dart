import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/widgets/common/auto_size_text_form_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///平台定制的通用AutoSizeTextFormField，规定了一些参数的缺省值外，还规定了边框的样式
///本类的目的是统一平台输入框的样式，包括自动调整字体大小适应
class CommonTextFormField extends StatefulWidget {
  final Key? textFormFieldKey;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool readOnly;
  final Color? fillColor;
  final Color? focusColor;
  final bool autofocus;
  final TextAlign textAlign;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final String obscuringCharacter;
  final TextInputAction? textInputAction;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextDirection? textDirection;
  final TextAlignVertical? textAlignVertical;
  final bool? showCursor;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final bool enableSuggestions;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final bool expands;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final Brightness? keyboardAppearance;
  final EdgeInsets scrollPadding;
  final TextSelectionControls? selectionControls;
  final Widget? Function(BuildContext,
      {required int currentLength,
      required bool isFocused,
      required int? maxLength})? buildCounter;
  final ScrollPhysics? scrollPhysics;
  final Iterable<String>? autofillHints;
  final AutovalidateMode? autovalidateMode;
  final ScrollController? scrollController;
  final String? restorationId;
  final bool enableIMEPersonalizedLearning;
  final MouseCursor? mouseCursor;
  final InputDecoration? decoration;
  final bool enableInteractiveSelection;
  final Color? hoverColor;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? suffix;
  final String? hintText;
  final void Function(String)? onChanged;
  final void Function()? onEditingComplete;
  final Function(String)? onFieldSubmitted;
  final void Function(String?)? onSaved;
  final void Function()? onTap;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final bool obscureText;
  final String? initialValue;
  final Widget Function(BuildContext, EditableTextState)? contextMenuBuilder;

  const CommonTextFormField({
    super.key,
    this.textFormFieldKey,
    this.controller,
    this.keyboardType,
    this.minLines,
    this.textAlign = TextAlign.start,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.obscuringCharacter = '*',
    this.textInputAction,
    this.style,
    this.strutStyle,
    this.textDirection,
    this.textAlignVertical,
    this.showCursor,
    this.smartDashesType,
    this.smartQuotesType,
    this.enableSuggestions = true,
    this.maxLengthEnforcement,
    this.expands = false,
    this.maxLength,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.selectionControls,
    this.buildCounter,
    this.scrollPhysics,
    this.autofillHints,
    this.autovalidateMode,
    this.scrollController,
    this.restorationId,
    this.enableIMEPersonalizedLearning = true,
    this.mouseCursor,
    this.decoration,
    this.fillColor,
    this.focusColor,
    this.autofocus = false,
    this.enableInteractiveSelection = true,
    this.hoverColor,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.hintText,
    this.readOnly = false,
    this.maxLines,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.onSaved,
    this.onTap,
    this.validator,
    this.focusNode,
    this.obscureText = false,
    this.initialValue,
    this.contextMenuBuilder,
  });

  @override
  State<StatefulWidget> createState() {
    return _CommonTextFormFieldState();
  }
}

class _CommonTextFormFieldState extends State<CommonTextFormField> {
  @override
  build(BuildContext context) {
    var textFormField = TextFormField(
      key: widget.textFormFieldKey,
      controller: widget.controller,
      initialValue: widget.initialValue,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      readOnly: widget.readOnly,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      validator: widget.validator,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      textAlign: widget.textAlign,
      textCapitalization: widget.textCapitalization,
      autocorrect: widget.autocorrect,
      obscuringCharacter: widget.obscuringCharacter,
      textInputAction: widget.textInputAction,
      style: widget.style,
      strutStyle: widget.strutStyle,
      textDirection: widget.textDirection,
      textAlignVertical: widget.textAlignVertical,
      showCursor: widget.showCursor,
      smartDashesType: widget.smartDashesType,
      smartQuotesType: widget.smartQuotesType,
      enableSuggestions: widget.enableSuggestions,
      maxLengthEnforcement: widget.maxLengthEnforcement,
      expands: widget.expands,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      cursorWidth: widget.cursorWidth,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      cursorColor: widget.cursorColor,
      keyboardAppearance: widget.keyboardAppearance,
      scrollPadding: widget.scrollPadding,
      selectionControls: widget.selectionControls,
      buildCounter: widget.buildCounter,
      scrollPhysics: widget.scrollPhysics,
      autofillHints: widget.autofillHints,
      autovalidateMode: widget.autovalidateMode,
      scrollController: widget.scrollController,
      restorationId: widget.restorationId,
      enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
      mouseCursor: widget.mouseCursor,
      decoration: widget.decoration ??
          buildInputDecoration(
              fillColor: widget.fillColor,
              focusColor: widget.focusColor,
              hoverColor: widget.hoverColor,
              labelText: widget.labelText,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              suffix: widget.suffix,
              hintText: widget.hintText),
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onFieldSubmitted: widget.onFieldSubmitted,
      onSaved: widget.onSaved,
      onTap: widget.onTap,
      contextMenuBuilder: widget.contextMenuBuilder,
    );

    return textFormField;
  }
}

///平台定制的通用AutoSizeTextFormField，规定了一些参数的缺省值外，还规定了边框的样式
///本类的目的是统一平台输入框的样式，包括自动调整字体大小适应
class CommonAutoSizeTextFormField extends StatefulWidget {
  final Key? textFormFieldKey;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool readOnly;
  final Color? fillColor;
  final Color? focusColor;
  final bool autofocus;
  final TextAlign textAlign;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final String obscuringCharacter;
  final TextInputAction? textInputAction;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextDirection? textDirection;
  final TextAlignVertical? textAlignVertical;
  final bool? showCursor;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final bool enableSuggestions;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final bool expands;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final Brightness? keyboardAppearance;
  final EdgeInsets scrollPadding;
  final TextSelectionControls? selectionControls;
  final Widget? Function(BuildContext,
      {required int currentLength,
      required bool isFocused,
      required int? maxLength})? buildCounter;
  final ScrollPhysics? scrollPhysics;
  final Iterable<String>? autofillHints;
  final AutovalidateMode? autovalidateMode;
  final ScrollController? scrollController;
  final String? restorationId;
  final bool enableIMEPersonalizedLearning;
  final MouseCursor? mouseCursor;
  final InputDecoration? decoration;
  final bool enableInteractiveSelection;
  final Color? hoverColor;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? suffix;
  final String? hintText;
  final void Function(String)? onChanged;
  final void Function()? onEditingComplete;
  final Function(String)? onFieldSubmitted;
  final void Function(String?)? onSaved;
  final void Function()? onTap;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final bool obscureText;
  final String? initialValue;
  final Widget Function(BuildContext, EditableTextState)? contextMenuBuilder;

  const CommonAutoSizeTextFormField({
    super.key,
    this.textFormFieldKey,
    this.controller,
    this.keyboardType,
    this.minLines,
    this.textAlign = TextAlign.start,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.obscuringCharacter = '*',
    this.textInputAction,
    this.style,
    this.strutStyle,
    this.textDirection,
    this.textAlignVertical,
    this.showCursor,
    this.smartDashesType,
    this.smartQuotesType,
    this.enableSuggestions = true,
    this.maxLengthEnforcement,
    this.expands = false,
    this.maxLength,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.selectionControls,
    this.buildCounter,
    this.scrollPhysics,
    this.autofillHints,
    this.autovalidateMode,
    this.scrollController,
    this.restorationId,
    this.enableIMEPersonalizedLearning = true,
    this.mouseCursor,
    this.decoration,
    this.fillColor,
    this.focusColor,
    this.autofocus = false,
    this.enableInteractiveSelection = true,
    this.hoverColor,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.hintText,
    this.readOnly = false,
    this.maxLines,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.onSaved,
    this.onTap,
    this.validator,
    this.focusNode,
    this.obscureText = false,
    this.initialValue,
    this.contextMenuBuilder,
  });

  @override
  State<StatefulWidget> createState() {
    return _CommonAutoSizeTextFormFieldState();
  }
}

class _CommonAutoSizeTextFormFieldState
    extends State<CommonAutoSizeTextFormField> {
  @override
  build(BuildContext context) {
    var textFormField = AutoSizeTextFormField(
      key: widget.textFormFieldKey,
      controller: widget.controller,
      initialValue: widget.initialValue,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      readOnly: widget.readOnly,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      validator: widget.validator,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      textAlign: widget.textAlign,
      textCapitalization: widget.textCapitalization,
      autocorrect: widget.autocorrect,
      obscuringCharacter: widget.obscuringCharacter,
      textInputAction: widget.textInputAction,
      style: widget.style,
      strutStyle: widget.strutStyle,
      textDirection: widget.textDirection,
      textAlignVertical: widget.textAlignVertical,
      showCursor: widget.showCursor,
      smartDashesType: widget.smartDashesType,
      smartQuotesType: widget.smartQuotesType,
      enableSuggestions: widget.enableSuggestions,
      maxLengthEnforcement: widget.maxLengthEnforcement,
      expands: widget.expands,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      cursorWidth: widget.cursorWidth,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      cursorColor: widget.cursorColor,
      keyboardAppearance: widget.keyboardAppearance,
      scrollPadding: widget.scrollPadding,
      selectionControls: widget.selectionControls,
      buildCounter: widget.buildCounter,
      scrollPhysics: widget.scrollPhysics,
      autofillHints: widget.autofillHints,
      autovalidateMode: widget.autovalidateMode,
      scrollController: widget.scrollController,
      restorationId: widget.restorationId,
      enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
      mouseCursor: widget.mouseCursor,
      decoration: widget.decoration ??
          buildInputDecoration(
              fillColor: widget.fillColor,
              focusColor: widget.focusColor,
              hoverColor: widget.hoverColor,
              labelText: widget.labelText,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              suffix: widget.suffix,
              hintText: widget.hintText),
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onFieldSubmitted: widget.onFieldSubmitted,
      onSaved: widget.onSaved,
      onTap: widget.onTap,
      contextMenuBuilder: widget.contextMenuBuilder,
    );

    return textFormField;
  }
}
