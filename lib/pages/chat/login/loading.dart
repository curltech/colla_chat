import 'package:flutter/material.dart';

import '../../../widgets/common/keep_alive_wrapper.dart';

const List<String> backgroudImages = [
  'assets/images/bg/login-bg-wd-1.jpg',
  'assets/images/bg/login-bg-wd-2.jpg',
  'assets/images/bg/login-bg-wd-3.jpg',
  'assets/images/bg/login-bg-wd-4.jpg',
  'assets/images/bg/login-bg-wd-5.jpg',
  'assets/images/bg/login-bg-wd-6.jpg',
  'assets/images/bg/login-bg-wd-7.jpg',
  'assets/images/bg/login-bg-wd-8.jpg',
  'assets/images/bg/login-bg-wd-9.jpg',
  'assets/images/bg/login-bg-wd-10.jpg',
  'assets/images/bg/login-bg-wd-11.jpg',
];

class Loading extends StatefulWidget {
  final String title;
  bool autoPlay;

  Loading({Key? key, required this.title, this.autoPlay = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LoadingState();
  }
}

class _LoadingState extends State<Loading> with SingleTickerProviderStateMixin {
  var _children = <Widget>[];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: backgroudImages.length, vsync: this);
    for (int i = 0; i < backgroudImages.length; ++i) {
      var image = KeepAliveWrapper(
          keepAlive: true,
          child: Image.asset(
            backgroudImages[i],
            fit: BoxFit.cover,
          ));
      _children.add(image);
    }
    if (widget.autoPlay) {
      Future.doWhile(() async {
        var currentIndex = _tabController.index;
        if (currentIndex >= backgroudImages.length - 1) {
          _tabController.index = 0;
        } else {
          _tabController.index = currentIndex + 1;
        }
        await Future.delayed(const Duration(seconds: 1));
        if (currentIndex >= backgroudImages.length - 1) {
          return false;
        }
        return true;
      });
    }

    // Future.delayed(const Duration(seconds: 10), () {
    //   Application.router.navigateTo(context, Routes.p2pLogin, replace: true);
    // });
  }

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: _tabController,
      children: _children,
    );
  }

  @override
  void dispose() {
    // 释放资源
    _tabController.dispose();
    super.dispose();
  }
}
