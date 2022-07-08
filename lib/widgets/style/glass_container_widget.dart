import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

final defaultLinearGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      const Color(0xFFffffff).withOpacity(0.1),
      const Color(0xFFFFFFFF).withOpacity(0.05),
    ],
    stops: const [
      0.1,
      1,
    ]);
final defaultBorderGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    const Color(0xFFffffff).withOpacity(0.5),
    const Color((0xFFFFFFFF)).withOpacity(0.5),
  ],
);

///需要指定大小的Container
class GlassContainerWidget extends StatelessWidget {
  final Widget? child;
  final double width;
  final double height;
  final double border;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final BoxShape shape;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? margin;
  final Matrix4? transform;
  final double borderRadius;
  late final LinearGradient linearGradient;
  final double blur;
  late final LinearGradient borderGradient;

  GlassContainerWidget({
    Key? key,
    this.child,
    required this.width,
    required this.height,
    this.border = 0,
    this.alignment,
    this.padding,
    this.constraints,
    this.margin,
    this.transform,
    this.shape = BoxShape.rectangle,
    this.borderRadius = 20,
    this.blur = 20,
    LinearGradient? linearGradient,
    LinearGradient? borderGradient,
  }) : super(key: key) {
    if (linearGradient == null) {
      this.linearGradient = defaultLinearGradient;
    } else {
      this.linearGradient = linearGradient;
    }
    if (borderGradient == null) {
      this.borderGradient = defaultBorderGradient;
    } else {
      this.borderGradient = borderGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: width,
      height: height,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.bottomCenter,
      border: border,
      linearGradient: linearGradient,
      borderGradient: borderGradient,
      child: child,
    );
  }
}

///原生的是Expanded，必须被Row,Column,Flex包裹
///被Column包裹，可用于取代Card等
class GlassFlexContainerWidget extends StatelessWidget {
  final Widget? child;
  final double border;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final BoxShape shape;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? margin;
  final Matrix4? transform;
  final double borderRadius;
  final double blur;
  late final LinearGradient linearGradient;
  late final LinearGradient borderGradient;

  GlassFlexContainerWidget({
    Key? key,
    this.child,
    this.border = 0,
    this.alignment,
    this.padding,
    this.constraints,
    this.margin,
    this.transform,
    this.borderRadius = 20,
    this.blur = 20,
    this.shape = BoxShape.rectangle,
    LinearGradient? linearGradient,
    LinearGradient? borderGradient,
  }) : super(key: key) {
    if (linearGradient == null) {
      this.linearGradient = defaultLinearGradient;
    } else {
      this.linearGradient = linearGradient;
    }
    if (borderGradient == null) {
      this.borderGradient = defaultBorderGradient;
    } else {
      this.borderGradient = borderGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GlassmorphicFlexContainer(
        borderRadius: 20,
        blur: 20,
        padding: const EdgeInsets.all(40),
        alignment: Alignment.bottomCenter,
        border: border,
        linearGradient: linearGradient,
        borderGradient: borderGradient,
        child: child,
      )
    ]);
  }
}
