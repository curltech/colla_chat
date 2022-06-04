import 'package:flutter/material.dart';
import '../routers/application.dart';
import '../routers/routes.dart';

const List<String> images = [
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

  const Loading({Key? key, required this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LoadingState();
  }
}

/// 继承State的类管理状态数据，状态数据为类的属性，当属性发生变化时，组件的自动重绘，
/// 类似Vue的data与组件v-model的关系但是是单向的，绑定的组件修改时，状态数据不会自动修改
/// 修改属性必须在setState方法的回调函数中进行
class _LoadingState extends State<Loading> {
  int _currentIndex = 0;
  bool _autoPlay = false;

  @override
  void initState() {
    super.initState();
    if (_autoPlay) {
      Future.doWhile(() async {
        setState(() {
          if (_currentIndex == images.length - 1) {
            _currentIndex = 0;
          } else {
            _currentIndex++;
          }
        });
        await Future.delayed(const Duration(seconds: 1));
        if (_currentIndex >= images.length - 1) {
          return false;
        }
        return true;
      });
    }

    Future.delayed(Duration(seconds: 10), () {
      Application.router.navigateTo(context, Routes.p2pLogin, replace: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: GestureDetector(
            onHorizontalDragEnd: (DragEndDetails details) {
              setState(() {
                if (_currentIndex == images.length - 1) {
                  _currentIndex = 0;
                } else {
                  _currentIndex++;
                }
              });
            },
            child: Center(
                child: IndexedStack(
              index: 0,
              children: [
                Image.asset(
                  images[_currentIndex],
                  fit: BoxFit.fill,
                )
              ],
            ))));
  }
}
