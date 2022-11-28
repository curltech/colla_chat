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

///消息体：定位消息
class LocationMessage extends StatelessWidget {
  final String? thumbnail;
  final String content;
  final bool isMyself;

  const LocationMessage(
      {Key? key, required this.content, required this.isMyself, this.thumbnail})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> map = JsonUtil.toJson(content);
    Position position = Position.fromMap(map);
    var latitude = position.latitude; //纬度
    var longitude = position.longitude; //经度
    var altitude = position.altitude; //高度
    var speed = position.speed; //速度
    var speedAccuracy = position.speedAccuracy; //速度精度
    var accuracy = position.accuracy; //精度
    var floor = position.floor; //精度
    var heading = position.heading; //
    Widget headingWidget = Icon(
      Icons.location_on,
      color: appDataProvider.themeData.colorScheme.primary,
    );
    if (thumbnail != null) {
      headingWidget = ImageUtil.buildImageWidget(image: thumbnail);
    }
    double height;
    Widget tile;
    if (chatMessageController.chatView == ChatView.full) {
      height = 190;
      tile = InkWell(
        child: ListTile(
          leading: headingWidget,
          title: Text(
              '${AppLocalizations.t('Longitude')}:$longitude\n${AppLocalizations.t('Latitude')}:$latitude\n${AppLocalizations.t('Altitude')}:$altitude\n${AppLocalizations.t('Accuracy')}:$accuracy'),
          subtitle: Text(
              '${AppLocalizations.t('Speed')}:$speed\n${AppLocalizations.t('SpeedAccuracy')}:$speedAccuracy\n${AppLocalizations.t('Heading')}:$heading\n${AppLocalizations.t('Floor')}:$floor'),
          isThreeLine: true,
        ),
      );
    } else {
      height = 130;
      tile = InkWell(
        child: ListTile(
          leading: headingWidget,
          title: Text(
              '${AppLocalizations.t('Longitude')}:$longitude\n${AppLocalizations.t('Latitude')}:$latitude'),
          subtitle: Text('${AppLocalizations.t('Altitude')}:$altitude'),
          isThreeLine: true,
        ),
      );
    }
    return SizedBox(height: height, child: Card(elevation: 0, child: tile));
  }
}
