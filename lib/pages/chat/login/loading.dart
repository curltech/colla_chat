import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const List<String> darkBackgroudImages = [
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

const List<String> lightBackgroudImages = [
  'assets/images/bg/login-bg-wl-1.jpg',
  'assets/images/bg/login-bg-wl-2.jpg',
  'assets/images/bg/login-bg-wl-3.jpg',
  'assets/images/bg/login-bg-wl-4.jpg',
  'assets/images/bg/login-bg-wl-5.jpg',
  'assets/images/bg/login-bg-wl-6.jpg',
  'assets/images/bg/login-bg-wl-7.jpg',
  'assets/images/bg/login-bg-wl-8.jpg',
  'assets/images/bg/login-bg-wl-9.jpg',
  'assets/images/bg/login-bg-wl-10.jpg',
  'assets/images/bg/login-bg-wl-11.jpg',
];

class Loading extends StatefulWidget {
  final String title;
  final bool autoPlay;

  final lightChildren = <Widget>[];

  final darkChildren = <Widget>[];

  Loading({Key? key, required this.title, this.autoPlay = true})
      : super(key: key) {
    for (int i = 0; i < lightBackgroudImages.length; ++i) {
      var image = Image.asset(
        lightBackgroudImages[i],
        fit: BoxFit.cover,
      );
      lightChildren.add(image);
    }
    for (int i = 0; i < darkBackgroudImages.length; ++i) {
      var image = Image.asset(
        darkBackgroudImages[i],
        fit: BoxFit.cover,
      );
      darkChildren.add(image);
    }
  }

  @override
  State<StatefulWidget> createState() {
    return _LoadingState();
  }
}

class _LoadingState extends State<Loading> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    if (appDataProvider.brightness == Brightness.light.name) {
      _tabController =
          TabController(length: lightBackgroudImages.length, vsync: this);
      if (widget.autoPlay) {
        Future.doWhile(() async {
          var currentIndex = _tabController.index;
          if (currentIndex >= lightBackgroudImages.length - 1) {
            _tabController.index = 0;
          } else {
            _tabController.index = currentIndex + 1;
          }
          await Future.delayed(const Duration(seconds: 10));
          if (currentIndex >= lightBackgroudImages.length - 1) {
            return false;
          }
          return true;
        });
      }
    }
    if (appDataProvider.brightness == Brightness.dark.name) {
      _tabController =
          TabController(length: darkBackgroudImages.length, vsync: this);
      if (widget.autoPlay) {
        Future.doWhile(() async {
          var currentIndex = _tabController.index;
          if (currentIndex >= darkBackgroudImages.length - 1) {
            _tabController.index = 0;
          } else {
            _tabController.index = currentIndex + 1;
          }
          await Future.delayed(const Duration(seconds: 10));
          if (currentIndex >= darkBackgroudImages.length - 1) {
            return false;
          }
          return true;
        });
      }
    }

    // Future.delayed(const Duration(seconds: 10), () {
    //   Application.router.navigateTo(context, Routes.p2pLogin, replace: true);
    // });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    AppDataProvider appDataProvider = Provider.of<AppDataProvider>(context);
    if (appDataProvider.brightness == Brightness.light.name) {
      children = widget.lightChildren;
    }
    if (appDataProvider.brightness == Brightness.dark.name) {
      children = widget.darkChildren;
    }
    return TabBarView(
      controller: _tabController,
      children: children,
    );
  }

  @override
  void dispose() {
    // 释放资源
    _tabController.dispose();
    super.dispose();
  }
}
