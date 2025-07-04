import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:toggle_switch/toggle_switch.dart';

class ReactiveRadioGroup<T> extends ReactiveFormField<T, T> {
  ReactiveRadioGroup({
    super.key,
    super.formControlName,
    super.formControl,
    super.validationMessages,
    super.valueAccessor,
    super.showErrors,
    required List<Option<T>> options,
    ReactiveFormFieldCallback<T>? onChanged,
    double width = 120,
    MouseCursor? mouseCursor,
    bool toggleable = false,
    Color? activeColor,
    WidgetStateProperty<Color?>? fillColor,
    Color? focusColor,
    Color? hoverColor,
    WidgetStateProperty<Color?>? overlayColor,
    double? splashRadius,
    MaterialTapTargetSize? materialTapTargetSize,
    VisualDensity? visualDensity,
    FocusNode? focusNode,
    bool autofocus = false,
    T? initValue,
  }) : super(
          builder: (field) {
            List<Widget> radioChildren = [];
            if (options.isNotEmpty) {
              T? groupValue = field.value;
              groupValue ??= initValue;
              for (var i = 0; i < options.length; ++i) {
                var option = options[i];
                var radio = Radio<T>(
                  onChanged: (T? value) {
                    field.didChange(value);
                    onChanged?.call(field.control);
                  },
                  value: option.value,
                  groupValue: groupValue,
                  mouseCursor: mouseCursor,
                  toggleable: toggleable,
                  activeColor: activeColor,
                  fillColor: fillColor,
                  focusColor: focusColor,
                  hoverColor: hoverColor,
                  overlayColor: overlayColor,
                  splashRadius: splashRadius,
                  materialTapTargetSize: materialTapTargetSize,
                  visualDensity: visualDensity,
                  focusNode: focusNode,
                  autofocus: autofocus,
                );
                var row = SizedBox(
                    width: width,
                    child: Row(
                      children: [
                        radio,
                        Expanded(
                            child: CommonAutoSizeText(
                                AppLocalizations.t(option.label)))
                      ],
                    ));
                radioChildren.add(row);
              }
            }

            return Wrap(
              children: radioChildren,
            );
          },
        );
}

class ReactiveCheckboxGroup<T> extends ReactiveFormField<T, Set<T>> {
  ReactiveCheckboxGroup({
    super.key,
    super.formControlName,
    super.formControl,
    super.validationMessages,
    super.valueAccessor,
    super.showErrors,
    required List<Option<T>> options,
    ReactiveFormFieldCallback<T>? onChanged,
    double width = 120,
    bool tristate = false,
    MouseCursor? mouseCursor,
    Color? activeColor,
    WidgetStateProperty<Color?>? fillColor,
    Color? checkColor,
    Color? focusColor,
    Color? hoverColor,
    WidgetStateProperty<Color?>? overlayColor,
    double? splashRadius,
    MaterialTapTargetSize? materialTapTargetSize,
    VisualDensity? visualDensity,
    FocusNode? focusNode,
    bool autofocus = false,
    OutlinedBorder? shape,
    BorderSide? side,
    bool isError = false,
    String? semanticLabel,
    Widget? prefixIcon,
    String? label,
    Set<T>? initValue,
  }) : super(builder: (field) {
          Set<T>? value = field.value;
          List<Widget> checkChildren = [];
          value ??= initValue;
          if (options.isNotEmpty) {
            Set<T>? value = initValue ?? {};
            for (var i = 0; i < options.length; ++i) {
              var option = options[i];
              var checkbox = Checkbox(
                onChanged: (bool? selected) {
                  if (selected == null || !selected) {
                    value.remove(option.value);
                  } else if (selected) {
                    value.add(option.value);
                  }

                  field.didChange(value);
                  onChanged?.call(field.control);
                },
                value: value.contains(option.value),
                tristate: tristate,
                mouseCursor: mouseCursor,
                activeColor: activeColor,
                fillColor: fillColor,
                checkColor: checkColor,
                focusColor: focusColor,
                hoverColor: hoverColor,
                overlayColor: overlayColor,
                splashRadius: splashRadius,
                materialTapTargetSize: materialTapTargetSize,
                visualDensity: visualDensity,
                focusNode: focusNode,
                autofocus: autofocus,
                shape: shape,
                side: side,
                isError: isError,
                semanticLabel: semanticLabel,
              );
              var row = SizedBox(
                  width: width,
                  child: Row(
                    children: [
                      checkbox,
                      Expanded(
                          child: CommonAutoSizeText(
                              AppLocalizations.t(option.label)))
                    ],
                  ));
              checkChildren.add(row);
            }
          }
          return Wrap(
            children: checkChildren,
          );
        });
}

class ReactiveToggleSwitch<T> extends ReactiveFormField<T, T> {
  ReactiveToggleSwitch({
    super.key,
    super.formControlName,
    super.formControl,
    super.validationMessages,
    super.valueAccessor,
    super.showErrors,
    required List<Option<T>> options,
    List<Color>? borderColor,
    Color dividerColor = Colors.white30,
    List<Color>? activeBgColor,
    Color? activeFgColor,
    Color? inactiveBgColor,
    Color? inactiveFgColor,
    int? totalSwitches,
    List<List<Color>?>? activeBgColors,
    List<TextStyle?>? customTextStyles,
    List<Icon?>? customIcons,
    List<double>? customWidths,
    List<double>? customHeights,
    double minWidth = 72,
    double minHeight = 40,
    double cornerRadius = 8.0,
    double fontSize = 13,
    double iconSize = 17,
    double dividerMargin = 8.0,
    double? borderWidth,
    bool changeOnTap = true,
    bool animate = false,
    int animationDuration = 800,
    bool radiusStyle = false,
    bool textDirectionRTL = false,
    Curve curve = Curves.easeIn,
    bool doubleTapDisable = false,
    bool isVertical = false,
    List<Border?>? activeBorders,
    bool centerText = false,
    bool multiLineText = false,
    ReactiveFormFieldCallback<T>? onToggle,
    Future<bool> Function(T?)? cancelToggle,
    List<bool>? states,
    List<Widget>? customWidgets,
    T? initValue,
  }) : super(
          builder: (field) {
            T? value = field.value;
            value ??= initValue;
            List<String> labels = [];
            List<IconData> icons = [];
            int? initialLabelIndex;
            for (var i = 0; i < options.length; ++i) {
              var option = options[i];
              if (option.icon != null) {
                icons.add(option.icon!);
              } else {
                labels.add(option.label);
              }
              if (value == option.value) {
                initialLabelIndex = i;
              }
            }
            return ToggleSwitch(
              borderColor: borderColor,
              dividerColor: dividerColor,
              activeBgColor: activeBgColor,
              activeFgColor: activeFgColor,
              inactiveBgColor: inactiveBgColor,
              inactiveFgColor: inactiveFgColor,
              labels: labels,
              totalSwitches: totalSwitches,
              icons: icons,
              activeBgColors: activeBgColors,
              customTextStyles: customTextStyles,
              customIcons: customIcons,
              customWidths: customWidths,
              customHeights: customHeights,
              minWidth: minWidth,
              minHeight: minHeight,
              cornerRadius: cornerRadius,
              fontSize: fontSize,
              iconSize: iconSize,
              dividerMargin: dividerMargin,
              borderWidth: borderWidth,
              onToggle: (int? index) {
                if (index != null) {
                  var option = options[index];
                  field.didChange.call(option.value);
                  onToggle?.call(field.control);
                }
              },
              changeOnTap: changeOnTap,
              animate: animate,
              animationDuration: animationDuration,
              radiusStyle: radiusStyle,
              textDirectionRTL: textDirectionRTL,
              curve: curve,
              initialLabelIndex: initialLabelIndex,
              doubleTapDisable: doubleTapDisable,
              isVertical: isVertical,
              activeBorders: activeBorders,
              states: states,
              cancelToggle: (int? index) {
                if (index != null) {
                  var option = options[index];
                  cancelToggle?.call(option.value);

                  return Future.value(true);
                }
                return Future.value(false);
              },
              centerText: centerText,
              multiLineText: multiLineText,
              customWidgets: customWidgets,
            );
          },
        );
}

class ReactiveToggleButtons<T> extends ReactiveFormField<T, T> {
  ReactiveToggleButtons({
    super.key,
    super.formControlName,
    super.formControl,
    super.validationMessages,
    super.valueAccessor,
    super.showErrors,
    required List<Option<T>> options,
    MouseCursor? mouseCursor,
    MaterialTapTargetSize? tapTargetSize,
    TextStyle? textStyle,
    BoxConstraints? constraints,
    Color? color,
    Color? selectedColor,
    Color? disabledColor,
    Color? fillColor,
    Color? focusColor,
    Color? highlightColor,
    Color? hoverColor,
    Color? splashColor,
    List<FocusNode>? focusNodes,
    bool renderBorder = true,
    Color? borderColor,
    Color? selectedBorderColor,
    Color? disabledBorderColor,
    BorderRadius? borderRadius,
    double? borderWidth,
    ReactiveFormFieldCallback<T>? onToggle,
    Axis direction = Axis.horizontal,
    VerticalDirection verticalDirection = VerticalDirection.down,
    T? initValue,
  }) : super(
          builder: (field) {
            T? value = field.value;
            value ??= initValue;
            List<bool> isSelected = [];
            List<Widget> children = [];
            for (var i = 0; i < options.length; ++i) {
              var option = options[i];
              if (value == option.value) {
                isSelected.add(true);
              } else {
                isSelected.add(false);
              }
              if (option.icon != null) {
                children.add(Icon(option.icon!));
              } else {
                children.add(Text(option.label));
              }
            }
            return ToggleButtons(
              isSelected: isSelected,
              onPressed: (int index) {
                var option = options[index];
                field.didChange.call(option.value);
                onToggle?.call(field.control);
              },
              mouseCursor: mouseCursor,
              tapTargetSize: tapTargetSize,
              textStyle: textStyle,
              constraints: constraints,
              color: color,
              selectedColor: selectedColor,
              disabledColor: disabledColor,
              fillColor: fillColor,
              focusColor: focusColor,
              highlightColor: highlightColor,
              hoverColor: hoverColor,
              splashColor: splashColor,
              focusNodes: focusNodes,
              renderBorder: renderBorder,
              borderColor: borderColor,
              selectedBorderColor: selectedBorderColor,
              disabledBorderColor: disabledBorderColor,
              borderRadius: borderRadius,
              borderWidth: borderWidth,
              direction: direction,
              verticalDirection: verticalDirection,
              children: children,
            );
          },
        );
}

class ReactiveCommonTextFormField<T> extends ReactiveFormField<T, String> {
  final TextEditingController? _textController;

  static Widget _defaultContextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    return AdaptiveTextSelectionToolbar.editableText(
      editableTextState: editableTextState,
    );
  }

  ReactiveCommonTextFormField({
    super.key,
    super.formControlName,
    super.formControl,
    super.validationMessages,
    super.valueAccessor,
    super.showErrors,
    super.focusNode,
    TextEditingController? controller,
    TextInputType? keyboardType,
    int? minLines,
    TextAlign textAlign = TextAlign.start,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool autocorrect = true,
    String obscuringCharacter = '*',
    TextInputAction? textInputAction,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextDirection? textDirection,
    TextAlignVertical? textAlignVertical,
    bool? showCursor,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    bool enableSuggestions = true,
    MaxLengthEnforcement? maxLengthEnforcement,
    bool expands = false,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    bool? enabled,
    double cursorWidth = 2.0,
    double? cursorHeight,
    Radius? cursorRadius,
    Color? cursorColor,
    Brightness? keyboardAppearance,
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
    TextSelectionControls? selectionControls,
    Widget? Function(BuildContext,
            {required int currentLength,
            required bool isFocused,
            required int? maxLength})?
        buildCounter,
    ScrollPhysics? scrollPhysics,
    Iterable<String>? autofillHints,
    AutovalidateMode? autovalidateMode,
    ScrollController? scrollController,
    String? restorationId,
    bool enableIMEPersonalizedLearning = true,
    MouseCursor? mouseCursor,
    InputDecoration? decoration,
    Color? fillColor,
    Color? focusColor,
    bool autofocus = false,
    bool enableInteractiveSelection = true,
    Color? hoverColor,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Widget? suffix,
    String? hintText,
    bool readOnly = false,
    int? maxLines,
    void Function(FormControl<T>)? onChanged,
    void Function(FormControl<T>)? onEditingComplete,
    dynamic Function(FormControl<T>)? onFieldSubmitted,
    void Function(FormControl<T>?)? onSaved,
    void Function(FormControl<T>)? onTap,
    String? Function(FormControl<T>?)? validator,
    bool obscureText = false,
    String? initialValue,
  })  : _textController = controller,
        super(
          builder: (ReactiveFormFieldState<T, String> field) {
            final state = field as _ReactiveCommonTextFormFieldState<T>;
            final effectiveDecoration = decoration?.applyDefaults(
              Theme.of(state.context).inputDecorationTheme,
            );

            return CommonTextFormField(
                controller: state._textController,
                focusNode: state.focusNode,
                decoration: effectiveDecoration?.copyWith(
                  errorText: state.errorText,
                ),
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
                mouseCursor: mouseCursor,
                obscuringCharacter: obscuringCharacter,
                restorationId: restorationId,
                scrollController: scrollController,
                selectionControls: selectionControls,
                enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
                onTap: onTap != null ? () => onTap(field.control) : null,
                onFieldSubmitted: onFieldSubmitted != null
                    ? (_) => onFieldSubmitted(field.control)
                    : null,
                onEditingComplete: onEditingComplete != null
                    ? () => onEditingComplete.call(field.control)
                    : null,
                onSaved: onSaved != null
                    ? (value) => onSaved.call(field.control)
                    : null,
                onChanged: (value) {
                  field.didChange(value);
                  onChanged?.call(field.control);
                },
                initialValue: initialValue,
                autovalidateMode: autovalidateMode,
                contextMenuBuilder: _defaultContextMenuBuilder);
          },
        );

  @override
  ReactiveFormFieldState<T, String> createState() =>
      _ReactiveCommonTextFormFieldState<T>();
}

class _ReactiveCommonTextFormFieldState<T>
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
    final currentWidget = widget as ReactiveCommonTextFormField<T>;
    _textController = (currentWidget._textController != null)
        ? currentWidget._textController!
        : TextEditingController();
    _textController.text = initialValue == null ? '' : initialValue.toString();
  }

  @override
  void dispose() {
    final currentWidget = widget as ReactiveCommonTextFormField<T>;
    if (currentWidget._textController == null) {
      _textController.dispose();
    }
    super.dispose();
  }
}
