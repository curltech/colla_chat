import 'package:colla_chat/pages/index/index_view.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelpInformationController {
  final RxString title = ''.obs;
  final RxString information = ''.obs;
}

final HelpInformationController helpInformationController =
    HelpInformationController();

// 帮助信息页面
class HelpInformationWidget extends StatelessWidget {
  const HelpInformationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return AppBarView(
          title: helpInformationController.title.value,
          isAppBar: false,
          rightWidget: IconButton(
              onPressed: () {
                sliderDrawerKey.currentState?.closeSlider();
              },
              icon: Icon(Icons.clear)),
          child: Container(
              color: Colors.white.withAlpha(0),
              child: Text(helpInformationController.information.value)));
    });
  }
}
