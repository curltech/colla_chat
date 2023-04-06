import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:flutter/material.dart';

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
        Text(
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
        Text(
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
            child: Text(
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
            child: Text(
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

const InputBorder textFormFieldBorder = UnderlineInputBorder(
    borderSide: BorderSide.none,
    borderRadius: BorderRadius.all(Radius.circular(4.0)));

///创建常用的文本输入字段
class AutoSizeTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final TextInputType? textInputType;
  final int? maxLines;

  final int? minLines;
  final bool readOnly;
  final Color? fillColor;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? suffix;
  final String? hintText;

  const AutoSizeTextFormField(
      {super.key,
      this.controller,
      this.textInputType,
      this.minLines,
      this.fillColor,
      this.labelText,
      this.prefixIcon,
      this.suffixIcon,
      this.suffix,
      this.hintText,
      this.readOnly = false,
      this.maxLines = 1});

  @override
  build(BuildContext context) {
    var textFormField = TextFormField(
      controller: controller,
      keyboardType: textInputType,
      maxLines: maxLines,
      minLines: 1,
      readOnly: readOnly,
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
    );

    return textFormField;
  }
}
