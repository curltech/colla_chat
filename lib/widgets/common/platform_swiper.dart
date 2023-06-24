import 'dart:async';
import 'package:another_transformer_page_view/another_transformer_page_view.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'dart:math' as Math;

import 'package:vector_math/vector_math_64.dart';

enum PlatformSwiperDirection { none, left, right, top, bottom }

class PlatformSwiper extends StatefulWidget {
  final double? itemHeight;
  final double? itemWidth;
  final double? containerHeight;
  final double? containerWidth;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int itemCount;
  final FutureOr<bool> Function(
          int currentIndex, int? oldIndex, PlatformSwiperDirection direction)?
      onSwipe;
  final bool autoplay;
  final int autoplayDelay;
  final bool autoplayDisableOnInteraction;
  final int duration;
  final Axis scrollDirection;
  final AxisDirection axisDirection;
  final Curve curve;
  final bool loop;
  final int? index;
  final void Function(int index)? onTap;
  final SwiperController? controller;
  final ScrollPhysics? physics;
  final double viewportFraction;
  final SwiperLayout layout;
  final double? scale;
  final double? fade;
  final PageIndicatorLayout indicatorLayout;
  final bool allowImplicitScrolling;
  final EdgeInsetsGeometry padding;
  final double maxAngle;

  final int threshold;

  const PlatformSwiper(
      {super.key,
      this.itemHeight,
      this.itemWidth,
      this.containerHeight,
      this.containerWidth,
      required this.controller,
      required this.itemBuilder,
      required this.itemCount,
      this.onSwipe,
      this.autoplay = true,
      this.autoplayDelay = 200,
      this.autoplayDisableOnInteraction = true,
      this.duration = kDefaultAutoplayTransactionDuration,
      this.scrollDirection = Axis.horizontal,
      this.axisDirection = AxisDirection.left,
      this.curve = Curves.ease,
      this.loop = true,
      this.index,
      this.onTap,
      this.physics = const NeverScrollableScrollPhysics(),
      this.viewportFraction = 1.0,
      this.layout = SwiperLayout.DEFAULT,
      this.scale,
      this.fade,
      this.indicatorLayout = PageIndicatorLayout.NONE,
      this.allowImplicitScrolling = false,
      this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      this.maxAngle = 30,
      this.threshold = 50});

  @override
  State<StatefulWidget> createState() {
    return _PlatformSwiperState();
  }
}

class _PlatformSwiperState extends State<PlatformSwiper> {
  @override
  initState() {
    super.initState();
  }

  void onIndexChanged(int index) {
    if (widget.onSwipe != null) {
      widget.onSwipe!(index, null, PlatformSwiperDirection.right);
    }
  }

  Widget _buildSwiper() {
    return Container(
        padding: widget.padding,
        child: Swiper(
          itemBuilder: widget.itemBuilder,
          indicatorLayout: widget.indicatorLayout,
          //transformer: transformer,
          itemCount: widget.itemCount,
          autoplay: widget.autoplay,
          layout: widget.layout,
          autoplayDelay: widget.autoplayDelay,
          autoplayDisableOnInteraction: widget.autoplayDisableOnInteraction,
          duration: widget.duration,
          onIndexChanged: onIndexChanged,
          index: widget.index,
          onTap: widget.onTap,
          control: const SwiperPagination(),
          loop: widget.loop,
          curve: widget.curve,
          scrollDirection: widget.scrollDirection,
          axisDirection: widget.axisDirection,
          pagination: const SwiperPagination(),
          physics: widget.physics,
          key: widget.key,
          controller: widget.controller,
          containerHeight: widget.containerHeight,
          containerWidth: widget.containerWidth,
          viewportFraction: widget.viewportFraction,
          itemHeight: widget.itemHeight,
          itemWidth: widget.itemWidth,
          scale: widget.scale,
          fade: widget.fade,
          allowImplicitScrolling: widget.allowImplicitScrolling,
        ));
  }

  Widget _buildTransformerPageView() {
    return TransformerPageView(
        key: widget.key,
        index: widget.index,
        duration: Duration(milliseconds: widget.duration),
        loop: widget.loop,
        curve: widget.curve,
        viewportFraction: widget.viewportFraction,
        scrollDirection: widget.scrollDirection,
        physics: widget.physics,
        // pageSnapping: widget.pageSnapping,
        // onPageChanged: widget.onPageChanged,
        // controller: widget.controller,
        pageController: TransformerPageController(),
        transformer: ThreeDTransformer(),
        itemBuilder: widget.itemBuilder,
        itemCount: widget.itemCount);
  }

  FutureOr<bool> onCardSwipe(
      int currentIndex, int? oldIndex, CardSwiperDirection direction) {
    if (widget.onSwipe != null) {
      PlatformSwiperDirection? platformSwiperDirection =
          StringUtil.enumFromString(
              PlatformSwiperDirection.values, direction.name);
      widget.onSwipe!(currentIndex, oldIndex, platformSwiperDirection!);
    }
    return true;
  }

  CardSwiper _buildCardSwiper() {
    return CardSwiper(
      key: widget.key,
      cardBuilder: widget.itemBuilder,
      cardsCount: widget.itemCount,
      controller: CardSwiperController(),
      initialIndex: widget.index ?? 0,
      padding: widget.padding,
      duration: Duration(milliseconds: widget.duration),
      maxAngle: widget.maxAngle,
      threshold: widget.threshold,
      scale: widget.scale!,
      isDisabled: widget.physics is NeverScrollableScrollPhysics,
      //onTapDisabled: onTapDisabled,
      onSwipe: onCardSwipe,
      //onEnd: onEnd,
      direction: widget.scrollDirection == Axis.horizontal
          ? CardSwiperDirection.right
          : CardSwiperDirection.bottom,
      allowedSwipeDirection: const AllowedSwipeDirection.all(),
      isLoop: widget.loop,
      numberOfCardsDisplayed: 2,
      //onUndo: onUndo,
      //backCardOffset: backCardOffset,
    );
  }

  FutureOr<bool> onAppinioSwiper(int index, AppinioSwiperDirection direction) {
    if (widget.onSwipe != null) {
      PlatformSwiperDirection? platformSwiperDirection =
          StringUtil.enumFromString(
              PlatformSwiperDirection.values, direction.name);
      widget.onSwipe!(index, null, platformSwiperDirection!);
    }
    return true;
  }

  AppinioSwiper _buildAppinioSwiper() {
    return AppinioSwiper(
      key: widget.key,
      cardsBuilder: widget.itemBuilder,
      cardsCount: widget.itemCount,
      controller: AppinioSwiperController(),
      padding: widget.padding,
      duration: Duration(milliseconds: widget.duration),
      maxAngle: widget.maxAngle,
      threshold: widget.threshold,
      isDisabled: widget.physics is NeverScrollableScrollPhysics,
      //onTapDisabled: onTapDisabled,
      onSwipe: onAppinioSwiper,
      //onEnd: onEnd,
      direction: widget.scrollDirection == Axis.horizontal
          ? AppinioSwiperDirection.right
          : AppinioSwiperDirection.bottom,
      swipeOptions: const AppinioSwipeOptions.all(),
      loop: widget.loop,
      backgroundCardsCount: 1,
      // allowUnswipe: allowUnswipe,
      // unlimitedUnswipe: unlimitedUnswipe,
      // onTapDisabled: onTapDisabled,
      // onSwiping: onSwiping,
      // onEnd: onEnd,
      // unswipe: unswipe,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildSwiper();
  }
}

class AccordionTransformer extends PageTransformer {
  @override
  Widget transform(Widget child, TransformInfo info) {
    double? position = info.position;
    if (position! < 0.0) {
      return Transform.scale(
        scale: 1 + position,
        alignment: Alignment.topRight,
        child: child,
      );
    } else {
      return Transform.scale(
        scale: 1 - position,
        alignment: Alignment.bottomLeft,
        child: child,
      );
    }
  }
}

class ThreeDTransformer extends PageTransformer {
  @override
  Widget transform(Widget child, TransformInfo info) {
    double? position = info.position;
    double? height = info.height;
    double? width = info.width;
    double pivotX = 0.0;
    if (position! < 0 && position! >= -1) {
      // left scrolling
      pivotX = width!;
    }
    return Transform(
      transform: Matrix4.identity()
        ..rotate(Vector3(0.0, 2.0, 0.0), position * 1.5),
      origin: Offset(pivotX, height! / 2),
      child: child,
    );
  }
}

class ZoomInPageTransformer extends PageTransformer {
  static const double ZOOM_MAX = 0.5;

  @override
  Widget transform(Widget child, TransformInfo info) {
    double? position = info.position;
    double? width = info.width;
    if (position! > 0 && position! <= 1) {
      return Transform.translate(
        offset: Offset(-width! * position, 0.0),
        child: Transform.scale(
          scale: 1 - position,
          child: child,
        ),
      );
    }
    return child;
  }
}

class ZoomOutPageTransformer extends PageTransformer {
  static const double MIN_SCALE = 0.85;
  static const double MIN_ALPHA = 0.5;

  @override
  Widget transform(Widget child, TransformInfo info) {
    double? position = info.position;
    double? pageWidth = info.width;
    double? pageHeight = info.height;

    if (position! < -1) {
      // [-Infinity,-1)
      // This page is way off-screen to the left.
      //view.setAlpha(0);
    } else if (position <= 1) {
      // [-1,1]
      // Modify the default slide transition to
      // shrink the page as well
      double scaleFactor = Math.max(MIN_SCALE, 1 - position.abs());
      double vertMargin = pageHeight! * (1 - scaleFactor) / 2;
      double horzMargin = pageWidth! * (1 - scaleFactor) / 2;
      double dx;
      if (position < 0) {
        dx = (horzMargin - vertMargin / 2);
      } else {
        dx = (-horzMargin + vertMargin / 2);
      }
      // Scale the page down (between MIN_SCALE and 1)
      double opacity = MIN_ALPHA +
          (scaleFactor - MIN_SCALE) / (1 - MIN_SCALE) * (1 - MIN_ALPHA);

      return Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(dx, 0.0),
          child: Transform.scale(
            scale: scaleFactor,
            child: child,
          ),
        ),
      );
    } else {
      // (1,+Infinity]
      // This page is way off-screen to the right.
      // view.setAlpha(0);
    }

    return child;
  }
}

class DeepthPageTransformer extends PageTransformer {
  DeepthPageTransformer() : super(reverse: true);

  @override
  Widget transform(Widget child, TransformInfo info) {
    double? position = info.position;
    if (position! <= 0) {
      return Opacity(
        opacity: 1.0,
        child: Transform.translate(
          offset: const Offset(0.0, 0.0),
          child: Transform.scale(
            scale: 1.0,
            child: child,
          ),
        ),
      );
    } else if (position <= 1) {
      const double MIN_SCALE = 0.75;
      // Scale the page down (between MIN_SCALE and 1)
      double scaleFactor = MIN_SCALE + (1 - MIN_SCALE) * (1 - position);

      return Opacity(
        opacity: 1.0 - position,
        child: Transform.translate(
          offset: Offset(info.width! * -position, 0.0),
          child: Transform.scale(
            scale: scaleFactor,
            child: child,
          ),
        ),
      );
    }

    return child;
  }
}

class ScaleAndFadeTransformer extends PageTransformer {
  final double _scale;
  final double _fade;

  ScaleAndFadeTransformer({double fade: 0.3, double scale: 0.8})
      : _fade = fade,
        _scale = scale;

  @override
  Widget transform(Widget item, TransformInfo info) {
    double? position = info.position;
    double scaleFactor = (1 - position!.abs()) * (1 - _scale);
    double fadeFactor = (1 - position!.abs()) * (1 - _fade);
    double opacity = _fade + fadeFactor;
    double scale = _scale + scaleFactor;
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: item,
      ),
    );
  }
}
