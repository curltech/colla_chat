import 'package:flutter/material.dart';
import 'dart:math' as math;


/// 五视频显示组件，一个蓝色的图标
class NoVideoWidget extends StatelessWidget {
  const NoVideoWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        child: LayoutBuilder(
          builder: (ctx, constraints) => Icon(
            Icons.videocam_off_outlined,
            color: Colors.blue,
            size: math.min(constraints.maxHeight, constraints.maxWidth) * 0.3,
          ),
        ),
      );
}
