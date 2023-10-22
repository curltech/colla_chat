import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:flutter/material.dart';

///平台定制的通用AutoSizeText，规定了一些参数的缺省值外，还规定了文本的样式
///本类的目的是统一平台文本显示的样式，包括自动调整字体大小适应
class CommonAutoSizeText extends AutoSizeText {
  const CommonAutoSizeText(
    String data, {
    Key? key,
    Key? textKey,
    TextStyle? style,
    StrutStyle? strutStyle,
    double minFontSize = AppFontSize.minFontSize,
    double maxFontSize = AppFontSize.maxFontSize,
    double stepGranularity = 1,
    List<double>? presetFontSizes,
    AutoSizeGroup? group,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Locale? locale,
    bool? softWrap,
    bool wrapWords = true,
    TextOverflow? overflow,
    Widget? overflowReplacement,
    double? textScaleFactor,
    int? maxLines,
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
        CommonAutoSizeText(
          label ?? '',
          style: TextStyle(
            color: labelColor,
            fontSize: labelSize,
          ),
          overflow: TextOverflow.visible,
          softWrap: false,
        ),
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
          label ?? '',
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
