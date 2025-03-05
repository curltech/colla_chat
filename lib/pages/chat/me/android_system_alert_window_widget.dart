import 'package:colla_chat/plugin/overlay/android_system_alert_window.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

class SystemAlertWindowWidget extends StatelessWidget with TileDataMixin {
  const SystemAlertWindowWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'system_alert_window';

  @override
  IconData get iconData => Icons.sensor_window_outlined;

  @override
  String get title => 'System alert window';

  

  @override
  Widget build(BuildContext context) {
    var overlayApp = AppBarView(
        title: title,
        helpPath: routeName,
        withLeading: withLeading,
        child: Center(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: MaterialButton(
                  onPressed: overlayAppWindow.show,
                  textColor: Colors.white,
                  color: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: const Text("Show system alert window"),
                ),
              ),
            ],
          ),
        ));

    return overlayApp;
  }
}
