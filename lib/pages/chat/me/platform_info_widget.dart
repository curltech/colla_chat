import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

class PlatformInfoWidget extends StatelessWidget with TileDataMixin {
  const PlatformInfoWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'platform_info';

  @override
  IconData get iconData => Icons.personal_video;

  @override
  String get title => 'Platform information';

  

  @override
  Widget build(BuildContext context) {
    final List<TileData> platformInfoTileData = [
      TileData(
        title: 'AppName',
        suffix: appName,
      ),
      TileData(
        title: 'AppVersion',
        suffix: appVersion,
      ),
      TileData(
        title: 'AppVendor',
        suffix: appVendor,
      ),
      TileData(
        title: 'VendorUrl',
        suffix: vendorUrl,
      ),
      TileData(
        title: 'LocalHostname',
        suffix: platformParams.localHostname,
      ),
      TileData(
        title: 'OperatingSystem',
        suffix: platformParams.operatingSystem,
      ),
      TileData(
        title: 'OperatingSystemVersion',
        subtitle: platformParams.operatingSystemVersion,
      ),
      TileData(
        title: 'Environment Version',
        subtitle: platformParams.version,
      ),
      TileData(
        title: 'DeviceData',
        subtitle: platformParams.deviceData.toString(),
      ),
      TileData(
        title: 'Sqlite3Path',
        subtitle: appDataProvider.sqlite3Path,
      ),
      TileData(
        title: 'DataLength',
        subtitle: appDataProvider.dataLength.toString(),
      ),
    ];

    var platformInfo = AppBarView(
      title: title,
      helpPath: routeName,
      withLeading: withLeading,
      child: DataListView(
        itemCount: platformInfoTileData.length,
        itemBuilder: (BuildContext context, int index) {
          return platformInfoTileData[index];
        },
      ),
    );

    return platformInfo;
  }
}
