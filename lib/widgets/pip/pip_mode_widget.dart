// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:pip_mode/pip_mode.dart';
//
// /// 一个简单的将widget用画中画显示的组件
// class PipModeWidget extends StatelessWidget {
//   final PipController pipController;
//   final Widget child;
//   final double width;
//   final double height;
//
//   const PipModeWidget(
//       {super.key,
//       required this.pipController,
//       required this.child,
//       this.width = 300,
//       this.height = 400});
//
//   @override
//   Widget build(BuildContext context) {
//     return PipWidget(
//         controller: pipController,
//         onInitialized: (success) {
//           log('Pip Widget 1 Initialized: $success');
//         },
//         child: Container(
//           width: width,
//           height: height,
//           alignment: Alignment.center,
//           child: child,
//         ));
//   }
// }
