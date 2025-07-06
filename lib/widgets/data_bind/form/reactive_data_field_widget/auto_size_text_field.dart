import 'dart:ui';

import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_forms/reactive_forms.dart';

class ReactiveAutoSizeTextFormField<T> extends ReactiveFormField<T, String> {
  final TextEditingController? _textController;

  static Widget _defaultContextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    return AdaptiveTextSelectionToolbar.editableText(
      editableTextState: editableTextState,
    );
  }

  ReactiveAutoSizeTextFormField({
    super.key,
    super.formControlName,
    super.formControl,
    super.validationMessages,
    super.valueAccessor,
    super.showErrors,
    super.focusNode,
    TextEditingController? controller,
    bool fullwidth = true,
    Key? textFieldKey,
    TextStyle? style,
    StrutStyle? strutStyle,
    double minFontSize = 12,
    double maxFontSize = double.infinity,
    double stepGranularity = 1,
    List<double>? presetFontSizes,
    TextAlign textAlign = TextAlign.start,
    TextDirection? textDirection,
    Locale? locale,
    bool wrapWords = true,
    Widget? overflowReplacement,
    String? semanticsLabel,
    InputDecoration decoration = const InputDecoration(),
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextAlignVertical? textAlignVertical,
    Iterable<String>? autofillHints,
    bool autofocus = false,
    bool obscureText = false,
    bool autocorrect = true,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    bool enableSuggestions = true,
    int? maxLines = 1,
    bool expands = false,
    bool readOnly = false,
    Widget Function(BuildContext, EditableTextState)? contextMenuBuilder =
        _defaultContextMenuBuilder,
    bool? showCursor,
    int? maxLength,
    MaxLengthEnforcement? maxLengthEnforcement,
    void Function(FormControl<T>)? onChanged,
    void Function(FormControl<T>)? onEditingComplete,
    void Function(FormControl<T>)? onSubmitted,
    List<TextInputFormatter>? inputFormatters,
    bool? enabled,
    double? cursorHeight,
    double cursorWidth = 2.0,
    Radius? cursorRadius,
    Color? cursorColor,
    BoxHeightStyle selectionHeightStyle = BoxHeightStyle.tight,
    BoxWidthStyle selectionWidthStyle = BoxWidthStyle.tight,
    Brightness? keyboardAppearance,
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    bool enableInteractiveSelection = true,
    void Function(FormControl<T>)? onTap,
    void Function(PointerDownEvent)? onTapOutside,
    Widget? Function(BuildContext,
            {required int currentLength,
            required bool isFocused,
            required int? maxLength})?
        buildCounter,
    ScrollPhysics? scrollPhysics,
    ScrollController? scrollController,
    int? minLines,
    double? minWidth,
    TextSelectionControls? selectionControls,
  })  : _textController = controller,
        super(
          builder: (ReactiveFormFieldState<T, String> field) {
            final state = field as _ReactiveAutoSizeTextFormFieldState<T>;

            return AutoSizeTextField(
                controller: state._textController,
                focusNode: state.focusNode,
                decoration: decoration,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                style: style,
                strutStyle: strutStyle,
                textAlign: textAlign,
                textAlignVertical: textAlignVertical,
                textDirection: textDirection,
                textCapitalization: textCapitalization,
                autofocus: autofocus,
                readOnly: readOnly,
                showCursor: showCursor,
                obscureText: obscureText,
                autocorrect: autocorrect,
                smartDashesType: smartDashesType ??
                    (obscureText
                        ? SmartDashesType.disabled
                        : SmartDashesType.enabled),
                smartQuotesType: smartQuotesType ??
                    (obscureText
                        ? SmartQuotesType.disabled
                        : SmartQuotesType.enabled),
                enableSuggestions: enableSuggestions,
                maxLengthEnforcement: maxLengthEnforcement,
                maxLines: maxLines,
                minLines: minLines,
                expands: expands,
                maxLength: maxLength,
                inputFormatters: inputFormatters,
                enabled: field.control.enabled,
                cursorWidth: cursorWidth,
                cursorHeight: cursorHeight,
                cursorRadius: cursorRadius,
                cursorColor: cursorColor,
                scrollPadding: scrollPadding,
                scrollPhysics: scrollPhysics,
                keyboardAppearance: keyboardAppearance,
                enableInteractiveSelection: enableInteractiveSelection,
                buildCounter: buildCounter,
                autofillHints: autofillHints,
                scrollController: scrollController,
                selectionControls: selectionControls,
                onTap: onTap != null ? () => onTap(field.control) : null,
                onSubmitted: onSubmitted != null
                    ? (_) => onSubmitted(field.control)
                    : null,
                onEditingComplete: onEditingComplete != null
                    ? () => onEditingComplete.call(field.control)
                    : null,
                onChanged: (value) {
                  field.didChange(value);
                  onChanged?.call(field.control);
                },
                contextMenuBuilder: _defaultContextMenuBuilder);
          },
        );

  @override
  ReactiveFormFieldState<T, String> createState() =>
      _ReactiveAutoSizeTextFormFieldState<T>();
}

class _ReactiveAutoSizeTextFormFieldState<T>
    extends ReactiveFocusableFormFieldState<T, String> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _initializeTextController();
  }

  @override
  void onControlValueChanged(dynamic value) {
    final effectiveValue = (value == null) ? '' : value.toString();
    _textController.value = _textController.value.copyWith(
      text: effectiveValue,
      selection: TextSelection.collapsed(offset: effectiveValue.length),
      composing: TextRange.empty,
    );

    super.onControlValueChanged(value);
  }

  @override
  ControlValueAccessor<T, String> selectValueAccessor() {
    if (control is FormControl<int>) {
      return IntValueAccessor() as ControlValueAccessor<T, String>;
    } else if (control is FormControl<double>) {
      return DoubleValueAccessor() as ControlValueAccessor<T, String>;
    } else if (control is FormControl<DateTime>) {
      return DateTimeValueAccessor() as ControlValueAccessor<T, String>;
    } else if (control is FormControl<TimeOfDay>) {
      return TimeOfDayValueAccessor() as ControlValueAccessor<T, String>;
    }

    return super.selectValueAccessor();
  }

  void _initializeTextController() {
    final initialValue = value;
    final currentWidget = widget as ReactiveAutoSizeTextFormField<T>;
    _textController = (currentWidget._textController != null)
        ? currentWidget._textController!
        : TextEditingController();
    _textController.text = initialValue == null ? '' : initialValue.toString();
  }

  @override
  void dispose() {
    final currentWidget = widget as ReactiveAutoSizeTextFormField<T>;
    if (currentWidget._textController == null) {
      _textController.dispose();
    }
    super.dispose();
  }
}
