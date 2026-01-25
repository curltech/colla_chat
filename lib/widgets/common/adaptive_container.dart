import 'package:carousel_slider_plus/carousel_options.dart';
import 'package:colla_chat/widgets/common/platform_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_slider_drawer/flutter_slider_drawer.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';

enum ContainerType { resizeable, carousel, slider, zoom }

class AdaptiveContainerController {
  late final PlatformCarouselController? platformCarouselController;
  late final ResizableController? resizableController;
  late final GlobalKey<SliderDrawerState>? sliderDrawerKey;
  late final ZoomDrawerController? zoomDrawerController;

  final ContainerType containerType;
  final double pixels;
  final RxInt index = 0.obs;

  AdaptiveContainerController(
      {this.containerType = ContainerType.resizeable, this.pixels = 320}) {
    if (containerType == ContainerType.resizeable) {
      resizableController = ResizableController();
      platformCarouselController = null;
      sliderDrawerKey = null;
      zoomDrawerController = null;
    } else if (containerType == ContainerType.carousel) {
      platformCarouselController = PlatformCarouselController();
      resizableController = null;
      sliderDrawerKey = null;
      zoomDrawerController = null;
    } else if (containerType == ContainerType.slider) {
      sliderDrawerKey = GlobalKey<SliderDrawerState>();
      platformCarouselController = null;
      resizableController = null;
      zoomDrawerController = null;
    } else if (containerType == ContainerType.zoom) {
      zoomDrawerController = ZoomDrawerController();
      platformCarouselController = null;
      sliderDrawerKey = null;
      resizableController = null;
    }
  }

  void closeSlider() {
    index.value = 1;
    sliderDrawerKey?.currentState?.closeSlider();
    platformCarouselController?.move(index.value);
    if (zoomDrawerController != null) {
      zoomDrawerController!.close!();
    }
    resizableController?.setSizes([
      ResizableSize.pixels(0),
      ResizableSize.expand(),
    ]);
  }

  void openSlider() {
    index.value = 0;
    sliderDrawerKey?.currentState?.openSlider();
    platformCarouselController?.move(index.value);
    if (zoomDrawerController != null) {
      zoomDrawerController!.open!();
    }
    resizableController?.setSizes([
      ResizableSize.pixels(pixels),
      ResizableSize.expand(),
    ]);
  }

  void toggle() {
    if (index.value == 0) {
      index.value = 1;
      resizableController?.setSizes([
        ResizableSize.pixels(0),
        ResizableSize.expand(),
      ]);
    } else if (index.value == 1) {
      index.value = 0;
      resizableController?.setSizes([
        ResizableSize.pixels(pixels),
        ResizableSize.expand(),
      ]);
    }
    sliderDrawerKey?.currentState?.toggle();
    platformCarouselController?.move(index.value);
    if (zoomDrawerController != null) {
      zoomDrawerController!.toggle!();
    }
  }

  bool? isDrawerOpen() {
    if (sliderDrawerKey != null) {
      return sliderDrawerKey?.currentState?.isDrawerOpen;
    }
    if (platformCarouselController != null) index.value == 0;
    if (zoomDrawerController != null) {
      return zoomDrawerController!.isOpen!();
    }
    return null;
  }
}

/// 自适应的容器，在竖屏的时候显示单个组件，滑动屏幕切换
/// 横屏的时候横向排列，可拖拽调整尺寸
class AdaptiveContainer extends StatelessWidget {
  final AdaptiveContainerController controller;
  final Widget main;
  final Widget body;

  final double dividerThickness;
  final Color? dividerColor;

  AdaptiveContainer({
    super.key,
    required this.main,
    required this.body,
    required this.controller,
    this.dividerThickness = 2.0,
    this.dividerColor,
  }) {}

  @override
  Widget build(BuildContext context) {
    if (controller.containerType == ContainerType.resizeable) {
      return ResizableContainer(
        controller: controller.resizableController,
        children: [
          ResizableChild(
              divider: ResizableDivider(
                thickness: dividerThickness,
                color: dividerColor,
              ),
              size: ResizableSize.pixels(controller.pixels),
              child: main),
          ResizableChild(child: body)
        ],
        direction: Axis.horizontal,
      );
    }
    if (controller.containerType == ContainerType.slider) {
      return SliderDrawer(
        key: controller.sliderDrawerKey,
        sliderOpenSize: controller.pixels,
        backgroundColor: Colors.white.withAlpha(1),
        slider: controller.isDrawerOpen() == true ? Container() : main,
        child: body,
      );
    }
    if (controller.containerType == ContainerType.zoom) {
      return ZoomDrawer(
        controller: controller.zoomDrawerController,
        style: DrawerStyle.defaultStyle,
        menuScreen: main,
        mainScreen: body,
        showShadow: true,
        // drawerShadowsBackgroundColor: Colors.grey,
        slideWidth: controller.pixels,
        openCurve: Curves.fastOutSlowIn,
        closeCurve: Curves.bounceIn,
      );
    }
    if (controller.containerType == ContainerType.carousel) {
      return PlatformCarouselWidget(
        controller: controller.platformCarouselController,
        initialPage: controller.index.value,
        onPageChanged: (int index,
            {PlatformSwiperDirection? direction,
            int? oldIndex,
            CarouselPageChangedReason? reason}) {
          controller.index.value = index;
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

    return Container();
  }
}
