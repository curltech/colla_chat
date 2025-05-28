import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:flutter/material.dart';

///平台定制的通用AutoSizeText，规定了一些参数的缺省值外，还规定了文本的样式
///本类的目的是统一平台文本显示的样式，包括自动调整字体大小适应
class CommonAutoSizeText extends AutoSizeText {
  const CommonAutoSizeText(
    super.data, {
    super.key,
    super.textKey,
    super.style,
    super.strutStyle,
    super.minFontSize = AppFontSize.minFontSize,
    super.maxFontSize = AppFontSize.maxFontSize,
    super.stepGranularity,
    super.presetFontSizes,
    super.group,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap,
    super.wrapWords,
    super.overflow,
    super.overflowReplacement,
    super.textScaleFactor,
    super.maxLines,
    super.semanticsLabel,
  });
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
        backgroundColor: WidgetStateProperty.all(backgroundColor),
        padding: WidgetStateProperty.all(padding),
        elevation: WidgetStateProperty.all(elevation),
        shape: WidgetStateProperty.all(
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
          softWrap: false,
          overflow: TextOverflow.visible,
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
  final Color? labelColor;
  final double? labelSize;
  final Widget icon;
  final String? tooltip;

  const IconTextButton({
    super.key,
    this.onPressed,
    this.iconColor,
    this.iconSize,
    this.label,
    this.labelColor,
    this.labelSize,
    this.tooltip,
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
        const SizedBox(height: 2.0),
      );
      children.add(
        Expanded(
            child: CommonAutoSizeText(
          AppLocalizations.t(label ?? ''),
          style: TextStyle(
            color: labelColor,
            fontSize: labelSize,
          ),
          overflow: TextOverflow.visible,
          softWrap: true,
          wrapWords: false,
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
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
  final double? labelSize;
  final Color? backgroundColor;
  final Widget icon;

  const InkWellTextButton({
    super.key,
    this.onPressed,
    this.iconColor,
    this.iconSize,
    this.label,
    this.labelColor,
    this.labelSize,
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
        const SizedBox(height: 2.0),
      );
      children.add(
        CommonAutoSizeText(
          AppLocalizations.t(label ?? ''),
          style: TextStyle(
            color: labelColor,
            fontSize: labelSize,
          ),
          overflow: TextOverflow.visible,
          softWrap: false,
        ),
      );
    }
    return Ink(
        color: backgroundColor,
        child: InkWell(
            onTap: onPressed,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
      backgroundColor: WidgetStateProperty.all(backgroundColor),
      foregroundColor: WidgetStateProperty.all(foregroundColor),
      textStyle: WidgetStateProperty.all(textStyle),
      elevation: WidgetStateProperty.all(elevation),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      padding: WidgetStateProperty.all(padding),
      minimumSize: WidgetStateProperty.all(minimumSize),
      maximumSize: WidgetStateProperty.all(maximumSize),
    );

    return style;
  }
}
