import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/geolocator_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_launcher/map_launcher.dart';

class PlatformMapLauncherWidget extends StatelessWidget with TileDataMixin {
  ValueNotifier<List<AvailableMap>> maps =
      ValueNotifier<List<AvailableMap>>([]);

  PlatformMapLauncherWidget({super.key}) {
    _init();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'mapLauncher';

  @override
  IconData get iconData => Icons.web;

  @override
  String get title => 'MapLauncher';

  _init() async {
    maps.value = await GeolocatorUtil.installedMaps();
  }

  TileData? buildMapTileData(BuildContext context, int index) {
    AvailableMap map = maps.value[index];
    TileData tile = TileData(
        title: map.mapName,
        prefix: SvgPicture.asset(
          map.icon,
          height: 30.0,
          width: 30.0,
        ),
        subtitle: map.mapType.name,
        onTap: (int index, String title, {String? subtitle}) async {
          Position? position = await GeolocatorUtil.currentPosition(context);
          if (position != null) {
            GeolocatorUtil.showMarker(
                map, Coords(position.latitude, position.longitude),
                title: AppLocalizations.t('Current position'));
          }
        });

    return tile;
  }

  Widget buildMapLauncher(BuildContext context) {
    if (platformParams.mobile) {
      return ValueListenableBuilder(
          valueListenable: maps,
          builder:
              (BuildContext context, List<AvailableMap> maps, Widget? child) {
            return DataListView(
              itemCount: maps.length,
              itemBuilder: (BuildContext context, int index) {
                return buildMapTileData(context, index);
              },
            );
          });
    }
    return FutureBuilder(
        future: GeolocatorUtil.currentPosition(context),
        builder: (BuildContext context, AsyncSnapshot<Position?> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              Position? position = snapshot.data;
              if (position != null) {
                return GeolocatorUtil.showPosition(
                    title: AppLocalizations.t('Current position'),
                    position.latitude,
                    position.longitude);
              }
            }
          }
          return LoadingUtil.buildLoadingIndicator();
        });
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: title, withLeading: true, child: buildMapLauncher(context));
  }
}
