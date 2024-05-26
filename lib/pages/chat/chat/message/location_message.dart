import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/geolocator_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';

///消息体：定位消息
class LocationMessage extends StatelessWidget {
  final String? thumbnail;
  final String content;
  final bool isMyself;
  final bool fullScreen;

  const LocationMessage(
      {super.key,
      required this.content,
      required this.isMyself,
      this.thumbnail,
      required this.fullScreen});

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
    String? address = locationPosition.address; //
    Widget headingWidget = Icon(Icons.location_on, color: myself.secondary);
    headingWidget = IconButton(
      icon: Icon(Icons.location_on, color: myself.primary),
      color: myself.primary,
      onPressed: () {
        GeolocatorUtil.showPosition(latitude, longitude, title: address);
      },
    );
    if (thumbnail != null) {
      headingWidget = ImageUtil.buildImageWidget(image: thumbnail);
    }
    Widget child;
    if (!fullScreen) {
      child = Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            headingWidget,
            const SizedBox(
              width: 5,
            ),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  CommonAutoSizeText(
                      '${AppLocalizations.t('Longitude')}:$longitude\n${AppLocalizations.t('Latitude')}:$latitude'),
                  CommonAutoSizeText(
                      '${AppLocalizations.t('Address')}:${address ?? ''}')
                ])),
          ]),
        ),
      );

      return CommonMessage(child: child);
    } else {
      child = GeolocatorUtil.showPosition(
        title: AppLocalizations.t('Location'),
        latitude,
        longitude,
      );

      return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: const ContinuousRectangleBorder(),
          child: child);
    }
  }
}
