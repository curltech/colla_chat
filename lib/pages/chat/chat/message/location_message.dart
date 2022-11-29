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
    LocationPosition locationPosition = LocationPosition.fromJson(map);
    var latitude = locationPosition.latitude; //纬度
    var longitude = locationPosition.longitude; //经度
    var altitude = locationPosition.altitude; //高度
    var speed = locationPosition.speed; //速度
    var speedAccuracy = locationPosition.speedAccuracy; //速度精度
    var accuracy = locationPosition.accuracy; //精度
    var floor = locationPosition.floor; //精度
    var heading = locationPosition.heading; //
    var address = locationPosition.address; //
    Widget headingWidget = Icon(
      Icons.location_on,
      color: appDataProvider.themeData.colorScheme.primary,
    );
    if (thumbnail != null) {
      headingWidget = ImageUtil.buildImageWidget(image: thumbnail);
    }
    Widget tile;
    if (chatMessageController.chatView == ChatView.full) {
      tile = InkWell(
          child: Center(
        child: ListTile(
          leading: headingWidget,
          subtitle: Text(
              '${AppLocalizations.t('Longitude')}:$longitude\n${AppLocalizations.t('Latitude')}:$latitude\n${AppLocalizations.t('Altitude')}:$altitude\n${AppLocalizations.t('Accuracy')}:$accuracy'),
          title: Text('${AppLocalizations.t('Address')}:$address'),
          isThreeLine: true,
        ),
      ));
    } else {
      tile = InkWell(
          child: Center(
        child: ListTile(
          leading: headingWidget,
          title: address != null
              ? Text('${AppLocalizations.t('Address')}:$address')
              : Text(
                  '${AppLocalizations.t('Longitude')}:$longitude\n${AppLocalizations.t('Latitude')}:$latitude'),
        ),
      ));
    }
    return Card(elevation: 0, child: tile);
  }
}
