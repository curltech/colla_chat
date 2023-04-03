import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:flutter/material.dart';

///常用的一些简单组件
class SimpleWidgetUtil {
  ///创建常用的大图标按钮
  static buildCircleButton({
    Key? key,
    String? label,
    String? tip,
    void Function()? onPressed,
    Color? backgroundColor,
    double elevation = 2.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(15.0),
    required Widget child,
  }) {
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
          AppLocalizations.t(tip),
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
          AppLocalizations.t(label),
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

  ///创建常用的图标文本按钮
  static buildIconTextButton({
    Key? key,
    required void Function()? onPressed,
    Color? iconColor,
    double? iconSize,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    String? label,
    String? tooltip,
    Color? labelColor,
    required Widget icon,
  }) {
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
          label,
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
        tooltip: tooltip != null ? AppLocalizations.t(tooltip) : null,
        icon: Column(
          children: children,
        ));
  }

  ///创建常用的InkWell按钮
  static buildInkWell({
    Key? key,
    required void Function()? onPressed,
    Color? iconColor,
    double? iconSize,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    String? label,
    Color? labelColor,
    Color? backgroundColor,
    required Widget icon,
  }) {
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
          label,
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

  ///创建常用的文按钮样式
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

  ///创建常用的文本输入字段
  static Widget buildTextFormField({
    TextEditingController? controller,
    TextInputType? textInputType,
    int? maxLines = 1,
    int? minLines,
    bool readOnly = false,
    Color? fillColor,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Widget? suffix,
    String? hintText,
  }) {
    var textFormField = TextFormField(
      controller: controller,
      keyboardType: textInputType,
      maxLines: maxLines,
      minLines: 1,
      readOnly: readOnly,
      decoration: InputDecoration(
          fillColor: fillColor ?? Colors.grey.withOpacity(AppOpacity.xlOpacity),
          filled: true,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          labelText: labelText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          suffix: suffix,
          hintText: hintText),
    );

    return textFormField;
  }
}
