import 'package:colla_chat/l10n/localization.dart';
import 'package:flutter/material.dart';

class WidgetUtil {
  static buildCircleButton({
    Key? key,
    required void Function()? onPressed,
    Color? backgroundColor,
    double elevation = 2.0,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    required Widget child,
  }) {
    return TextButton(
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
  }

  static buildIconTextButton({
    Key? key,
    required void Function()? onPressed,
    Color? iconColor,
    double? iconSize,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    required String text,
    String? tooltip,
    Color? textColor,
    required Widget icon,
  }) {
    return Column(
      children: <Widget>[
        Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(5.0),
            ),
          ),
          child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: IconButton(
                  onPressed: onPressed,
                  padding: padding,
                  color: iconColor,
                  iconSize: iconSize,
                  icon: icon,
                  tooltip: tooltip != null ? AppLocalizations.t(tooltip) : '')),
        ),
        const SizedBox(height: 3.0),
        Text(
          text,
          style: TextStyle(
            color: textColor,
          ),
        ),
      ],
    );
  }

  static buildInkWell({
    Key? key,
    required void Function()? onPressed,
    Color? iconColor,
    double? iconSize,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    required String text,
    Color? textColor,
    Color? backgroundColor,
    required Widget icon,
  }) {
    return Column(
      children: <Widget>[
        Container(
          padding: padding,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(5.0),
            ),
          ),
          child: Ink(
              color: backgroundColor,
              child: InkWell(
                onTap: onPressed,
                child: icon,
              )),
        ),
        const SizedBox(height: 3.0),
        Text(
          text,
          style: TextStyle(
            color: textColor,
          ),
        ),
      ],
    );
  }

  static ButtonStyle buildButtonStyle(
      {Color backgroundColor = Colors.grey,
      double borderRadius = 8.0,
      EdgeInsets padding =
          const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
      Size minimumSize = const Size(50, 46.0),
      Size maximumSize = const Size(120.0, 56.0)}) {
    ButtonStyle style = ButtonStyle(
      backgroundColor: MaterialStateProperty.all(backgroundColor),
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
