import 'dart:async';
import 'package:another_transformer_page_view/another_transformer_page_view.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/page_view_transformer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

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
      cardBuilder: (
        BuildContext context,
        int index,
        int horizontalOffsetPercentage,
        int verticalOffsetPercentage,
      ) {
        widget.itemBuilder(context, index);
      },
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
