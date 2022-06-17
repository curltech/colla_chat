import 'dart:math';

import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/widgets/common/image_widget.dart';
import 'package:flutter/material.dart';

import '../../../../constant/base.dart';

///聊天时候的头像组件
class MsgAvatar extends StatefulWidget {
  final ChatMessage model;

  MsgAvatar({
    required this.model,
  });

  _MsgAvatarState createState() => _MsgAvatarState();
}

class _MsgAvatarState extends State<MsgAvatar> with TickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController controller;

  @override
  initState() {
    super.initState();
    start(true);
  }

  start(bool isInit) {
    controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    animation = TweenSequence<double>([
      //使用TweenSequence进行多组补间动画
      TweenSequenceItem<double>(tween: Tween(begin: 0, end: 10), weight: 1),
      TweenSequenceItem<double>(tween: Tween(begin: 10, end: 0), weight: 1),
      TweenSequenceItem<double>(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem<double>(tween: Tween(begin: -10, end: 0), weight: 1),
    ]).animate(controller);
    if (!isInit) controller.forward();
  }

  Widget build(BuildContext context) {
    return InkWell(
      child: AnimateWidget(
        animation: animation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(5.0)),
          ),
          margin: EdgeInsets.only(right: 10.0),

          ///目前是缺省头像
          child: ImageWidget(
            image: defaultIcon,
            height: 35,
            width: 35,
            fit: BoxFit.cover,
          ),
        ),
      ),
      onDoubleTap: () {
        setState(() => start(false));
      },
      onTap: () {
        ///点击头像显示联系人的信息页面，等待实现
        // routePush(ContactsDetailsPage(
        //   title: widget.model.nickName,
        //   avatar: widget.model.avatar,
        //   id: widget.model.id,
        // ));
      },
    );
  }

  dispose() {
    controller.dispose();
    super.dispose();
  }
}

class AnimateWidget extends AnimatedWidget {
  final Widget child;

  AnimateWidget({
    required Animation<double> animation,
    required this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable as Animation<double>;
    var result = Transform(
      transform: Matrix4.rotationZ(animation.value * pi / 180),
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(5)),
        child: child,
      ),
    );
    return result;
  }
}
