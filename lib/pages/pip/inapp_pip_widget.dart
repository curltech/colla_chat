import 'package:flutter/material.dart';
import 'package:flutter_in_app_pip/flutter_in_app_pip.dart';

/// Replace your MaterialApp with PiPMaterialApp
/// If using MaterialApp.router, you can replace it with PiPMaterialApp.router
class InAppPipWidget extends StatelessWidget {
  final Widget child;

  const InAppPipWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    PictureInPicture.startPiP(
        pipWidget: PiPWidget(
      onPiPClose: () {
        //Handle closing events e.g. dispose controllers.
      },
      elevation: 10, //Optional
      pipBorderRadius: 10,
      child: child, //Optional
    ));
    PictureInPicture.startPiP(
        pipWidget: NavigatablePiPWidget(
      onPiPClose: () {
        //Handle closing events e.g. dispose controllers.
      },
      elevation: 10, //Optional
      pipBorderRadius: 10,
      builder: (BuildContext context) {
        return child;
      }, //Optional
    ));

    PictureInPicture.updatePiPParams(
      pipParams: PiPParams(
        pipWindowHeight: 144,
        pipWindowWidth: 256,
        bottomSpace: 64,
        leftSpace: 64,
        rightSpace: 64,
        topSpace: 64,
        maxSize: Size(256, 144),
        minSize: Size(144, 108),
        movable: true,
        resizable: false,
        initialCorner: PIPViewCorner.bottomRight,
      ),
    );
    PictureInPicture.stopPiP();
    throw UnimplementedError();
  }
}
