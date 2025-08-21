import 'package:carousel_slider_plus/carousel_options.dart';
import 'package:colla_chat/widgets/common/platform_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_slider_drawer/flutter_slider_drawer.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';

enum ContainerType { resizeable, slider, card, swiper, zoom }

/// 自适应的容器，在竖屏的时候显示单个组件，滑动屏幕切换
/// 横屏的时候横向排列，可拖拽调整尺寸
class AdaptiveContainer extends StatelessWidget {
  late final PlatformCarouselController? controller;
  late final ResizableController? resizableController;
  late final GlobalKey<SliderDrawerState>? sliderDrawerKey;
  late final ZoomDrawerController? zoomDrawerController;
  late final CardSwiperController? cardSwiperController;

  final Widget main;
  final Widget body;
  final RxInt index = 0.obs;
  final ContainerType containerType;
  final double dividerThickness;
  final Color? dividerColor;
  final double pixels;

  AdaptiveContainer(
      {super.key,
      required this.main,
      required this.body,
      this.containerType = ContainerType.resizeable,
      this.dividerThickness = 2.0,
      this.dividerColor,
      this.pixels = 320}) {
    if (containerType == ContainerType.resizeable) {
      resizableController = ResizableController();
      controller = null;
      sliderDrawerKey = null;
      zoomDrawerController = null;
      cardSwiperController = null;
    } else if (containerType == ContainerType.swiper) {
      controller = PlatformCarouselController();
      resizableController = null;
      sliderDrawerKey = null;
      zoomDrawerController = null;
      cardSwiperController = null;
    } else if (containerType == ContainerType.slider) {
      sliderDrawerKey = GlobalKey<SliderDrawerState>();
      controller = null;
      resizableController = null;
      zoomDrawerController = null;
      cardSwiperController = null;
    } else if (containerType == ContainerType.zoom) {
      zoomDrawerController = ZoomDrawerController();
      controller = null;
      sliderDrawerKey = null;
      resizableController = null;
      cardSwiperController = null;
    } else {
      cardSwiperController = CardSwiperController();
      controller = null;
      sliderDrawerKey = null;
      resizableController = null;
      zoomDrawerController = null;
    }
  }

  closeSlider() {
    sliderDrawerKey?.currentState?.closeSlider();
    controller?.move(1);
    if (zoomDrawerController != null) {
      zoomDrawerController!.close!();
    }
    resizableController?.setSizes([ResizableSize.pixels(0)]);
  }

  openSlider() {
    sliderDrawerKey?.currentState?.openSlider();
    controller?.move(0);
    if (zoomDrawerController != null) {
      zoomDrawerController!.open!();
    }
    resizableController?.setSizes([ResizableSize.pixels(pixels)]);
  }

  toggle() {
    sliderDrawerKey?.currentState?.toggle();
    if (index.value == 0) {
      controller?.move(1);
    } else if (index.value == 1) {
      controller?.move(0);
    }
    if (zoomDrawerController != null) {
      zoomDrawerController!.toggle!();
    }
  }

  bool? isDrawerOpen() {
    if (sliderDrawerKey != null) {
      return sliderDrawerKey?.currentState?.isDrawerOpen;
    }
    if (controller != null) index.value == 0;
    if (zoomDrawerController != null) {
      return zoomDrawerController!.isOpen!();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (containerType == ContainerType.resizeable) {
      return ResizableContainer(
        controller: resizableController,
        children: [
          ResizableChild(
              divider: ResizableDivider(
                thickness: dividerThickness,
                color: dividerColor,
              ),
              size: ResizableSize.pixels(pixels),
              child: main),
          ResizableChild(child: body)
        ],
        direction: Axis.horizontal,
      );
    }
    if (containerType == ContainerType.slider) {
      return SliderDrawer(
        key: sliderDrawerKey,
        sliderOpenSize: pixels,
        backgroundColor: Colors.white.withAlpha(1),
        slider: isDrawerOpen() == true ? Container() : main,
        child: body,
      );
    }
    if (containerType == ContainerType.zoom) {
      return ZoomDrawer(
        controller: zoomDrawerController,
        style: DrawerStyle.defaultStyle,
        menuScreen: main,
        mainScreen: body,
        showShadow: true,
        // drawerShadowsBackgroundColor: Colors.grey,
        slideWidth: pixels,
        openCurve: Curves.fastOutSlowIn,
        closeCurve: Curves.bounceIn,
      );
    }
    if (containerType == ContainerType.swiper) {
      return PlatformCarouselWidget(
        controller: controller,
        initialPage: index.value,
        onPageChanged: (int index,
            {PlatformSwiperDirection? direction,
            int? oldIndex,
            CarouselPageChangedReason? reason}) {
          this.index.value = index;
        },
        itemCount: 2,
        itemBuilder: (BuildContext context, int index, {int? realIndex}) {
          if (index == 0) {
            return main;
          } else {
            return body;
          }
        },
      );
    }

    return CardSwiper(
      controller: cardSwiperController,
      initialIndex: index.value,
      onSwipe: (int oldIndex, int? newIndex, CardSwiperDirection direction) {
        index.value = newIndex ?? oldIndex;

        return newIndex == null ? false : true;
      },
      cardsCount: 2,
      cardBuilder: (BuildContext context, int index,
          int horizontalOffsetPercentage, int verticalOffsetPercentage) {
        if (index == 0) {
          return main;
        } else {
          return body;
        }
      },
    );
  }
}
