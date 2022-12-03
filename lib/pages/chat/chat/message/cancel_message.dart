import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/geolocator_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/smart_dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';

///消息体：撤销消息
class CancelMessage extends StatelessWidget {
  final String content;
  final bool isMyself;

  const CancelMessage({Key? key, required this.content, required this.isMyself})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget leading = Icon(
      Icons.cancel,
      color: appDataProvider.themeData.colorScheme.primary,
    );
    Widget tile = Center(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          leading,
          const SizedBox(
            width: 5,
          ),
          Expanded(child: Text(content)),
        ]),
      ),
    );
    return Card(elevation: 0, child: tile);
  }
}
