import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_slider_drawer/flutter_slider_drawer.dart';
import 'package:get/get.dart';

/// 自适应的容器，在竖屏的时候显示单个组件，滑动屏幕切换
/// 横屏的时候横向排列，可拖拽调整尺寸
class AdaptiveContainer extends StatelessWidget {
  final SwiperController swiperController = SwiperController();
  final resizableController = ResizableController();
  GlobalKey<SliderDrawerState> sliderDrawerKey = GlobalKey<SliderDrawerState>();
  final Widget main;
  final Widget body;
  final RxInt index = 0.obs;

  AdaptiveContainer({super.key, required this.main, required this.body});

  @override
  Widget build(BuildContext context) {
    if (appDataProvider.landscape) {
      if (appDataProvider.bodyWidth == 0) {
        return ResizableContainer(
          controller: resizableController,
          children: [
            ResizableChild(
                divider: ResizableDivider(
                  thickness: 2,
                  color: myself.primary,
                ),
                size: const ResizableSize.ratio(0.4),
                child: main),
            ResizableChild(child: body)
          ],
          direction: Axis.horizontal,
        );
      }
    }

    return Swiper(
      controller: swiperController,
      index: index.value,
      onIndexChanged: (index) {
        this.index.value = index;
      },
      itemCount: 2,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return main;
        } else {
          return body;
        }
      },
    );
    return SliderDrawer(
      key: sliderDrawerKey,
      slider: main,
      child: body,
    );
  }
}
