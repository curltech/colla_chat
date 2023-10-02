import 'dart:typed_data';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/qrcode_widget.dart';
import 'package:colla_chat/plugin/overlay/overlay_app_window.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OverlayAppWindowWidget extends StatefulWidget with TileDataMixin {
  const OverlayAppWindowWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _OverlayAppWindowWidgetState();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'overlay_app';

  @override
  IconData get iconData => Icons.sensor_window_outlined;

  @override
  String get title => 'Overlay app window';
}

class _OverlayAppWindowWidgetState extends State<OverlayAppWindowWidget>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var overlayApp = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
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
