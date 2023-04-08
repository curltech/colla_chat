import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/auto_size_text_form_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///平台定制的通用AutoSizeText，规定了一些参数的缺省值外，还规定了文本的样式
///本类的目的是统一平台文本显示的样式，包括自动调整字体大小适应
class CommonAutoSizeText extends AutoSizeText {
  const CommonAutoSizeText(
    String data, {
    Key? key,
    Key? textKey,
    TextStyle? style,
    StrutStyle? strutStyle,
    double minFontSize = 12,
    double maxFontSize = double.infinity,
    double stepGranularity = 1,
    List<double>? presetFontSizes,
    AutoSizeGroup? group,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Locale? locale,
    bool? softWrap = true,
    bool wrapWords = true,
    TextOverflow? overflow = TextOverflow.visible,
    Widget? overflowReplacement,
    double? textScaleFactor = 1.0,
    int? maxLines = 1,
    String? semanticsLabel,
  }) : super(
          data,
          key: key,
          textKey: textKey,
          style: style,
          strutStyle: strutStyle,
          minFontSize: minFontSize,
          maxFontSize: maxFontSize,
          stepGranularity: stepGranularity,
          presetFontSizes: presetFontSizes,
          group: group,
          textAlign: textAlign,
          textDirection: textDirection,
          locale: locale,
          softWrap: softWrap,
          wrapWords: wrapWords,
          overflow: overflow,
          overflowReplacement: overflowReplacement,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
          semanticsLabel: semanticsLabel,
        );
}

const InputBorder textFormFieldBorder = UnderlineInputBorder(
    borderSide: BorderSide.none,
    borderRadius: BorderRadius.all(Radius.circular(4.0)));

///平台定制的AutoSizeTextFormField，规定了一些参数的缺省值
class CustomAutoSizeTextFormField extends AutoSizeTextFormField {
  const CustomAutoSizeTextFormField({
    Key? key,
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
    TextEditingController? controller,
    String? initialValue,
    FocusNode? focusNode,
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
    EditableTextContextMenuBuilder? contextMenuBuilder,
    bool? showCursor,
    int? maxLength,
    MaxLengthEnforcement? maxLengthEnforcement,
    void Function(String)? onChanged,
    void Function()? onEditingComplete,
    Function(String)? onFieldSubmitted,
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
    void Function()? onTap,
    Widget? Function(BuildContext,
            {required int currentLength,
            required bool isFocused,
            required int? maxLength})?
        buildCounter,
    ScrollPhysics? scrollPhysics,
    ScrollController? scrollController,
    int minLines = 1,
    double? minWidth,
    String obscuringCharacter = '*',
    void Function(String?)? onSaved,
    String? Function(String?)? validator,
    TextSelectionControls? selectionControls,
    AutovalidateMode? autovalidateMode,
    bool enableIMEPersonalizedLearning = true,
    MouseCursor? mouseCursor,
    String? restorationId,
  }) : super(
          key: key,
          fullwidth: fullwidth,
          textFieldKey: textFieldKey,
          style: style,
          strutStyle: strutStyle,
          minFontSize: minFontSize,
          maxFontSize: maxFontSize,
          stepGranularity: stepGranularity,
          presetFontSizes: presetFontSizes,
          textAlign: textAlign,
          textDirection: textDirection,
          locale: locale,
          wrapWords: wrapWords,
          overflowReplacement: overflowReplacement,
          semanticsLabel: semanticsLabel,
          controller: controller,
          initialValue: initialValue,
          focusNode: focusNode,
          decoration: decoration,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          textAlignVertical: textAlignVertical,
          autofillHints: autofillHints,
          autofocus: autofocus,
          obscureText: obscureText,
          autocorrect: autocorrect,
          smartDashesType: smartDashesType,
          smartQuotesType: smartQuotesType,
          enableSuggestions: enableSuggestions,
          maxLines: maxLines,
          expands: expands,
          readOnly: readOnly,
          contextMenuBuilder: contextMenuBuilder,
          showCursor: showCursor,
          maxLength: maxLength,
          maxLengthEnforcement: maxLengthEnforcement,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          onFieldSubmitted: onFieldSubmitted,
          inputFormatters: inputFormatters,
          enabled: enabled,
          cursorHeight: cursorHeight,
          cursorWidth: cursorWidth,
          cursorRadius: cursorRadius,
          cursorColor: cursorColor,
          keyboardAppearance: keyboardAppearance,
          scrollPadding: scrollPadding,
          enableInteractiveSelection: enableInteractiveSelection,
          onTap: onTap,
          buildCounter: buildCounter,
          scrollPhysics: scrollPhysics,
          scrollController: scrollController,
          minLines: minLines,
          minWidth: minWidth,
          obscuringCharacter: obscuringCharacter,
          onSaved: onSaved,
          validator: validator,
          selectionControls: selectionControls,
          autovalidateMode: autovalidateMode,
          enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
          mouseCursor: mouseCursor,
          restorationId: restorationId,
        );
}

///平台定制的通用AutoSizeTextFormField，规定了一些参数的缺省值外，还规定了边框的样式
///本类的目的是统一平台输入框的样式，包括自动调整字体大小适应
class CommonAutoSizeTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool readOnly;
  final Color? fillColor;
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

  const CommonAutoSizeTextFormField({
    super.key,
    this.controller,
    this.keyboardType,
    this.minLines,
    this.fillColor,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.hintText,
    this.readOnly = false,
    this.maxLines = 1,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.onSaved,
    this.onTap,
    this.validator,
    this.focusNode,
    this.obscureText = false,
    this.initialValue,
  });

  @override
  build(BuildContext context) {
    var textFormField = CustomAutoSizeTextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: 1,
      readOnly: readOnly,
      focusNode: focusNode,
      obscureText: obscureText,
      initialValue: initialValue,
      validator: validator,
      decoration: InputDecoration(
          fillColor: fillColor ?? Colors.grey.withOpacity(AppOpacity.xlOpacity),
          filled: true,
          border: textFormFieldBorder,
          focusedBorder: textFormFieldBorder,
          enabledBorder: textFormFieldBorder,
          errorBorder: textFormFieldBorder,
          disabledBorder: textFormFieldBorder,
          focusedErrorBorder: textFormFieldBorder,
          labelText: labelText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          suffix: suffix,
          hintText: hintText),
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onFieldSubmitted,
      onSaved: onSaved,
      onTap: onTap,
    );

    return textFormField;
  }
}

///创建常用的大图标按钮
class CircleTextButton extends StatelessWidget {
  final String? label;
  final String? tip;
  final void Function()? onPressed;
  final Color? backgroundColor;
  final double elevation;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const CircleTextButton({
    super.key,
    this.label,
    this.tip,
    this.onPressed,
    this.backgroundColor,
    this.elevation = 2.0,
    this.padding = const EdgeInsets.all(15.0),
    required this.child,
  });

  @override
  build(BuildContext context) {
    Widget button = TextButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(backgroundColor),
        padding: MaterialStateProperty.all(padding),
        elevation: MaterialStateProperty.all(elevation),
        shape: MaterialStateProperty.all(
          const CircleBorder(),
        ),
      ),
      onPressed: onPressed,
      child: child,
    );
    List<Widget> children = [];
    if (tip != null) {
      children.add(
        CommonAutoSizeText(
          AppLocalizations.t(tip!),
          style: const TextStyle(
              color: Colors.white, fontSize: AppFontSize.xsFontSize),
        ),
      );
      children.add(
        const SizedBox(
          height: 10.0,
        ),
      );
    }
    children.add(button);
    if (label != null) {
      children.add(
        const SizedBox(
          height: 10.0,
        ),
      );
      children.add(
        CommonAutoSizeText(
          AppLocalizations.t(label!),
          style: const TextStyle(
              color: Colors.white, fontSize: AppFontSize.mdFontSize),
        ),
      );
    }

    button = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
    return button;
  }
}

///创建常用的图标文本按钮
class IconTextButton extends StatelessWidget {
  final void Function()? onPressed;
  final Color? iconColor;
  final double? iconSize;
  final EdgeInsetsGeometry padding;
  final String? label;
  final String? tooltip;
  final Color? labelColor;
  final Widget icon;

  const IconTextButton({
    super.key,
    this.onPressed,
    this.iconColor,
    this.iconSize,
    this.label,
    this.tooltip,
    this.labelColor,
    required this.icon,
    this.padding = EdgeInsets.zero,
  });

  @override
  build(BuildContext context) {
    List<Widget> children = [
      icon,
    ];
    if (label != null) {
      children.add(
        const SizedBox(height: 3.0),
      );
      children.add(
        Expanded(
            child: CommonAutoSizeText(
          label ?? '',
          style: TextStyle(
            color: labelColor,
          ),
          overflow: TextOverflow.visible,
        )),
      );
    }
    return IconButton(
        onPressed: onPressed,
        padding: padding,
        color: iconColor,
        iconSize: iconSize,
        tooltip: tooltip != null ? AppLocalizations.t(tooltip ?? '') : null,
        icon: Column(
          children: children,
        ));
  }
}

///创建常用的InkWell按钮
class InkWellTextButton extends StatelessWidget {
  final void Function()? onPressed;
  final Color? iconColor;
  final double? iconSize;
  final EdgeInsetsGeometry padding;
  final String? label;
  final Color? labelColor;
  final Color? backgroundColor;
  final Widget icon;

  const InkWellTextButton({
    super.key,
    this.onPressed,
    this.iconColor,
    this.iconSize,
    this.label,
    this.labelColor,
    this.backgroundColor,
    required this.icon,
    this.padding = EdgeInsets.zero,
  });

  @override
  build(BuildContext context) {
    List<Widget> children = [
      icon,
    ];
    if (label != null) {
      children.add(
        const SizedBox(height: 3.0),
      );
      children.add(
        Expanded(
            child: CommonAutoSizeText(
          label ?? '',
          style: TextStyle(
            color: labelColor,
          ),
          overflow: TextOverflow.visible,
        )),
      );
    }
    return Ink(
        color: backgroundColor,
        child: InkWell(
            onTap: onPressed,
            child: Column(
              children: children,
            )));
  }
}

///创建常用的组件样式，包括按钮，输入框
class StyleUtil {
  ///创建常用的按钮样式
  static ButtonStyle buildButtonStyle(
      {TextStyle? textStyle,
      Color? backgroundColor,
      Color? foregroundColor,
      double? elevation = 0.0,
      double borderRadius = 8.0,
      EdgeInsets padding =
          const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      Size minimumSize = const Size(60, 40.0),
      Size maximumSize = const Size(120.0, 48.0)}) {
    backgroundColor =
        backgroundColor ?? Colors.grey.withOpacity(AppOpacity.smOpacity);
    foregroundColor = foregroundColor ?? Colors.white;
    textStyle = textStyle ?? const TextStyle(color: Colors.white);
    elevation = elevation ?? 0.0;
    ButtonStyle style = ButtonStyle(
      backgroundColor: MaterialStateProperty.all(backgroundColor),
      foregroundColor: MaterialStateProperty.all(foregroundColor),
      textStyle: MaterialStateProperty.all(textStyle),
      elevation: MaterialStateProperty.all(elevation),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      padding: MaterialStateProperty.all(padding),
      minimumSize: MaterialStateProperty.all(minimumSize),
      maximumSize: MaterialStateProperty.all(maximumSize),
    );

    return style;
  }
}
