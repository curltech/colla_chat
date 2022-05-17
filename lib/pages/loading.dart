import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';

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

class _LoadingState extends State<Loading> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Swiper(
        itemBuilder: (BuildContext context, int index) {
          return Image.asset(
            images[index],
            fit: BoxFit.fill,
          );
        },
        itemCount: images.length,
        pagination: SwiperPagination(),
        control: SwiperControl(),
      ),
    );
  }
}
