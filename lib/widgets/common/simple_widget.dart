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
          child: IconButton(
            onPressed: onPressed,
            padding: padding,
            color: iconColor,
            iconSize: iconSize,
            icon: icon,
          ),
        ),
        const SizedBox(height: 5.0),
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
          child: InkWell(
            onTap: onPressed,
            child: icon,
          ),
        ),
        const SizedBox(height: 5.0),
        Text(
          text,
          style: TextStyle(
            color: textColor,
          ),
        ),
      ],
    );
  }
}
