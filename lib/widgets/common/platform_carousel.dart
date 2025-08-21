import 'dart:async';

import 'package:another_transformer_page_view/another_transformer_page_view.dart';
import 'package:carousel_slider_plus/carousel_slider_plus.dart'
    as carousel_slider;
import 'package:flutter/gestures.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart'
    as flutter_carousel;
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/page_view_transformer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

enum PlatformSwiperDirection { none, left, right, top, bottom }

enum PlatformCarouselType { swiper, slide, carousel, page }

class PlatformCarouselController {
  final PlatformCarouselType platformCarouselType;
  carousel_slider.CarouselSliderController? carouselSliderController;
  flutter_carousel.FlutterCarouselController? flutterCarouselController;
  IndexController? indexController;
  CardSwiperController? cardSwiperController;

  PlatformCarouselController(
      {this.platformCarouselType = PlatformCarouselType.slide,
      this.carouselSliderController,
      this.flutterCarouselController,
      this.indexController,
      this.cardSwiperController}) {
    if (platformCarouselType == PlatformCarouselType.carousel) {
      carouselSliderController = carousel_slider.CarouselSliderController();
    } else if (platformCarouselType == PlatformCarouselType.slide) {
      flutterCarouselController = flutter_carousel.FlutterCarouselController();
    } else if (platformCarouselType == PlatformCarouselType.swiper) {
      cardSwiperController = CardSwiperController();
    } else if (platformCarouselType == PlatformCarouselType.page) {
      indexController = IndexController();
    }
  }

  move(int index) {
    if (carouselSliderController != null) {
      carouselSliderController!.animateToPage(index);
    } else if (flutterCarouselController != null) {
      flutterCarouselController!.animateToPage(index);
    } else if (cardSwiperController != null) {
      cardSwiperController!.moveTo(index);
    } else if (indexController != null) {
      indexController!.move(index);
    }
  }

  next() {
    if (carouselSliderController != null) {
      carouselSliderController!.nextPage();
    } else if (cardSwiperController != null) {
      flutterCarouselController!.nextPage();
    } else if (cardSwiperController != null) {
      cardSwiperController!.swipe(CardSwiperDirection.right);
    } else if (indexController != null) {
      indexController!.next();
    }
  }
}

class PlatformCarouselWidget extends StatelessWidget {
  late final PlatformCarouselController controller;
  final double? height;
  final double aspectRatio;
  final double viewportFraction;
  final int initialPage;
  final bool enableInfiniteScroll;
  final bool animateToClosest;
  final bool reverse;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Duration autoPlayAnimationDuration;
  final Curve autoPlayCurve;
  final bool enlargeCenterPage;
  final Axis scrollDirection;
  final Function(int currentIndex,
      {int? oldIndex,
      carousel_slider.CarouselPageChangedReason? reason,
      PlatformSwiperDirection? direction})? onPageChanged;
  final ValueChanged<double?>? onScrolled;
  final ScrollPhysics? scrollPhysics;
  final bool pageSnapping;
  final bool pauseAutoPlayOnTouch;
  final bool pauseAutoPlayOnManualNavigate;
  final bool pauseAutoPlayInFiniteScroll;
  final PageStorageKey? pageViewKey;
  final carousel_slider.CenterPageEnlargeStrategy enlargeStrategy;
  final double enlargeFactor;
  final bool disableCenter;
  final bool padEnds;
  final Clip clipBehavior;
  final bool keepPage;
  final ScrollPhysics? physics;
  final bool allowImplicitScrolling;
  final String? restorationId;
  final ScrollBehavior? scrollBehavior;
  final bool showIndicator;
  final flutter_carousel.SlideIndicator? slideIndicator;
  final bool floatingIndicator;
  final double? indicatorMargin;
  final DragStartBehavior dragStartBehavior;

  final Widget Function(BuildContext, int, {int? realIndex}) itemBuilder;
  final int itemCount;
  final bool disableGesture;

  PlatformCarouselWidget({
    super.key,
    this.height,
    this.aspectRatio = 16 / 9,
    this.viewportFraction = 1.0,
    this.initialPage = 0,
    this.enableInfiniteScroll = true,
    this.animateToClosest = true,
    this.reverse = false,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.autoPlayAnimationDuration = const Duration(milliseconds: 800),
    this.autoPlayCurve = Curves.fastOutSlowIn,
    this.enlargeCenterPage = false,
    this.onPageChanged,
    this.onScrolled,
    this.scrollPhysics,
    this.pageSnapping = true,
    this.scrollDirection = Axis.horizontal,
    this.pauseAutoPlayOnTouch = true,
    this.pauseAutoPlayOnManualNavigate = true,
    this.pauseAutoPlayInFiniteScroll = false,
    this.pageViewKey,
    this.enlargeStrategy = carousel_slider.CenterPageEnlargeStrategy.scale,
    this.enlargeFactor = 0.25,
    this.disableCenter = false,
    this.padEnds = true,
    this.clipBehavior = Clip.hardEdge,
    required this.itemBuilder,
    required this.itemCount,
    this.disableGesture = false,
    this.keepPage = true,
    this.physics = const BouncingScrollPhysics(),
    this.allowImplicitScrolling = false,
    this.restorationId,
    this.scrollBehavior,
    this.showIndicator = false,
    this.slideIndicator,
    this.floatingIndicator = true,
    this.indicatorMargin,
    this.dragStartBehavior = DragStartBehavior.start,
    PlatformCarouselController? controller,
  }) {
    if (controller == null) {
      this.controller = PlatformCarouselController(
          carouselSliderController: carousel_slider.CarouselSliderController());
    } else {
      this.controller = controller;
    }
  }

  Widget _buildCarouselSlider() {
    carousel_slider.CarouselOptions options = carousel_slider.CarouselOptions(
      height: height,
      aspectRatio: aspectRatio,
      viewportFraction: viewportFraction,
      initialPage: initialPage,
      enableInfiniteScroll: enableInfiniteScroll,
      reverse: reverse,
      autoPlay: autoPlay,
      autoPlayInterval: autoPlayInterval,
      autoPlayAnimationDuration: autoPlayAnimationDuration,
      autoPlayCurve: autoPlayCurve,
      enlargeCenterPage: enlargeCenterPage,
      onPageChanged: (index, reason) {
        onPageChanged?.call(index, reason: reason);
      },
      onScrolled: onScrolled,
      scrollPhysics: scrollPhysics,
      pageSnapping: pageSnapping,
      scrollDirection: scrollDirection,
      pauseAutoPlayOnTouch: pauseAutoPlayOnTouch,
      pauseAutoPlayOnManualNavigate: pauseAutoPlayOnManualNavigate,
      pauseAutoPlayInFiniteScroll: pauseAutoPlayInFiniteScroll,
      pageViewKey: pageViewKey,
      enlargeStrategy: enlargeStrategy,
      enlargeFactor: enlargeFactor,
      disableCenter: disableCenter,
      clipBehavior: clipBehavior,
      padEnds: padEnds,
    );
    return carousel_slider.CarouselSlider.builder(
      key: key,
      itemBuilder: (context, index, realIndex) {
        return itemBuilder.call(context, index, realIndex: realIndex);
      },
      options: options,
      itemCount: itemCount,
      controller: controller.carouselSliderController,
      disableGesture: disableGesture,
    );
  }

  Widget _buildFlutterCarousel() {
    flutter_carousel.CenterPageEnlargeStrategy? platformEnlargeStrategy =
        StringUtil.enumFromString(
            flutter_carousel.CenterPageEnlargeStrategy.values,
            enlargeStrategy.name);
    flutter_carousel.FlutterCarouselOptions options =
        flutter_carousel.FlutterCarouselOptions(
      controller: controller.flutterCarouselController,
      height: height,
      aspectRatio: aspectRatio,
      viewportFraction: viewportFraction,
      initialPage: initialPage,
      enableInfiniteScroll: enableInfiniteScroll,
      reverse: reverse,
      autoPlay: autoPlay,
      autoPlayInterval: autoPlayInterval,
      autoPlayAnimationDuration: autoPlayAnimationDuration,
      autoPlayCurve: autoPlayCurve,
      enlargeCenterPage: enlargeCenterPage,
      enlargeFactor: enlargeFactor,
      onPageChanged: (index, reason) {
        String name = reason.name;
        carousel_slider.CarouselPageChangedReason? r =
            StringUtil.enumFromString(
                carousel_slider.CarouselPageChangedReason.values, name);
        onPageChanged?.call(index, reason: r);
      },
      scrollDirection: scrollDirection,
      pauseAutoPlayOnTouch: pauseAutoPlayOnTouch,
      pauseAutoPlayOnManualNavigate: pauseAutoPlayOnManualNavigate,
      pauseAutoPlayInFiniteScroll: pauseAutoPlayInFiniteScroll,
      pageViewKey: pageViewKey,
      keepPage: keepPage,
      showIndicator: showIndicator,
      floatingIndicator: floatingIndicator,
      indicatorMargin: indicatorMargin ?? 0,
      slideIndicator: slideIndicator,
      clipBehavior: clipBehavior,
      scrollBehavior: scrollBehavior,
      pageSnapping: pageSnapping,
      padEnds: padEnds,
      dragStartBehavior: dragStartBehavior,
      allowImplicitScrolling: allowImplicitScrolling,
      restorationId: restorationId,
      enlargeStrategy: platformEnlargeStrategy!,
      disableCenter: disableCenter,
    );
    return flutter_carousel.FlutterCarousel.builder(
      key: key,
      itemBuilder: (context, index, realIndex) {
        return itemBuilder.call(context, index, realIndex: realIndex);
      },
      options: options,
      itemCount: itemCount,
    );
  }

  Widget _buildTransformerPageView() {
    return TransformerPageView(
        key: key,
        index: initialPage,
        duration: autoPlayAnimationDuration,
        loop: autoPlay,
        curve: autoPlayCurve,
        viewportFraction: viewportFraction,
        scrollDirection: scrollDirection,
        physics: physics,
        pageSnapping: pageSnapping,
        onPageChanged: (index) {
          onPageChanged?.call(index!);
        },
        controller: controller.indexController,
        pageController: TransformerPageController(),
        transformer: ThreeDTransformer(),
        itemBuilder: (context, index) {
          return itemBuilder.call(context, index);
        },
        itemCount: itemCount);
  }

  FutureOr<bool> onCardSwipe(
      int currentIndex, int? oldIndex, CardSwiperDirection direction) {
    if (onPageChanged != null) {
      PlatformSwiperDirection? platformSwiperDirection =
          StringUtil.enumFromString(
              PlatformSwiperDirection.values, direction.name);
      onPageChanged!(currentIndex,
          oldIndex: oldIndex, direction: platformSwiperDirection!);
    }
    return true;
  }

  CardSwiper _buildCardSwiper() {
    return CardSwiper(
      key: key,
      cardBuilder: (
        BuildContext context,
        int index,
        int horizontalOffsetPercentage,
        int verticalOffsetPercentage,
      ) {
        itemBuilder(context, index);

        return null;
      },
      cardsCount: itemCount,
      controller: controller.cardSwiperController,
      initialIndex: initialPage,
      duration: autoPlayAnimationDuration,
      isDisabled: physics is NeverScrollableScrollPhysics,
      onSwipe: onCardSwipe,
      allowedSwipeDirection: const AllowedSwipeDirection.all(),
      isLoop: autoPlay,
      numberOfCardsDisplayed: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (controller.platformCarouselType) {
      case PlatformCarouselType.carousel:
        return _buildCarouselSlider();
      case PlatformCarouselType.slide:
        return _buildFlutterCarousel();
      case PlatformCarouselType.swiper:
        return _buildCardSwiper();
      case PlatformCarouselType.page:
        return _buildTransformerPageView();
    }
  }
}
