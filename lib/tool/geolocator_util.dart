import 'dart:async';

import 'package:colla_chat/plugin/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_launcher/map_launcher.dart' as map_launcher;
import 'package:platform_maps_flutter/platform_maps_flutter.dart'
    as platform_map;

class GeolocatorUtil {
  static Future<Position?> checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return null;
  }

  static Future<Position> currentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.best,
    bool forceAndroidLocationManager = false,
    Duration? timeLimit,
  }) async {
    var permission = await checkPermission();
    if (permission == null) {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: desiredAccuracy,
          forceAndroidLocationManager: forceAndroidLocationManager,
          timeLimit: timeLimit);
    }
    return permission;
  }

  static Future<Position?> lastKnownPosition(
      {bool forceAndroidLocationManager = false}) async {
    var permission = await checkPermission();
    if (permission == null) {
      return await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: forceAndroidLocationManager,
      );
    }
    return permission;
  }

  static StreamSubscription<Position> positionStream() {
    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
          forceLocationManager: true,
          intervalDuration: const Duration(seconds: 10),
          //(Optional) Set foreground notification config to keep the app alive
          //when going to the background
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText:
                "Example app will continue to receive your location even when you aren't using it",
            notificationTitle: "Running in Background",
            enableWakeLock: true,
          ));
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 100,
        pauseLocationUpdatesAutomatically: true,
        // Only set to true if our app will be started up in the background.
        showBackgroundLocationIndicator: false,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
    }

    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      logger.i(position == null
          ? 'Unknown'
          : '${position.latitude.toString()}, ${position.longitude.toString()}');
    });

    return positionStream;
  }

  ///计算地图距离
  static double distance(LatLng x, LatLng y) {
    const Distance distance = Distance();
    final double meter = distance(x, y);

    return meter;
  }

  static LatLng offset(LatLng x) {
    const Distance distance = Distance();
    final num distanceInMeter = (6378 * pi / 4).round();
    final p = distance.offset(x, distanceInMeter, 180);
    // LatLng(latitude:-45.219848, longitude:0.0)
    logger.i(p.round());
    // 45° 13' 11.45" S, 0° 0' 0.00" O
    logger.i(p.toSexagesimal());

    return p;
  }

  static Path<LatLng> smoothPath(Iterable<LatLng> coordinates) {
    // zigzag is a list of coordinates
    final Path path = Path.from(coordinates);

    // Result is below
    final Path steps = path.equalize(8, smoothPath: true);

    return steps;
  }

  ///Leaflet地图
  static FlutterMap buildFlutterMap(LatLng center, double zoom) {
    return FlutterMap(
      mapController: MapController(),
      options: MapOptions(
        center: center,
        zoom: zoom,
      ),
      nonRotatedChildren: [
        AttributionWidget.defaultWidget(
          source: 'OpenStreetMap contributors',
          onSourceTapped: null,
        ),
      ],
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
      ],
    );
  }

  ///获取安装的地图软件列表
  static Future<List<map_launcher.AvailableMap>> installedMaps() async {
    final availableMaps = await map_launcher.MapLauncher.installedMaps;

    return availableMaps;
  }

  ///根据地图和位置调用安装的地图软件
  static Future<void> showMarker(
      map_launcher.AvailableMap map, map_launcher.Coords coords,
      {required String title}) async {
    await map.showMarker(
      coords: coords,
      title: title,
    );
  }

  ///是否安装了地图类型
  static Future<bool?> isMapAvailable(map_launcher.MapType mapType) async {
    return await map_launcher.MapLauncher.isMapAvailable(mapType);
  }

  ///根据地图的类型调用安装的地图软件
  static Future<void> mapLauncher(
      map_launcher.MapType mapType, map_launcher.Coords coords,
      {required String title, String? description}) async {
    await map_launcher.MapLauncher.showMarker(
      mapType: mapType,
      coords: coords,
      title: title,
      description: description,
    );
  }

  ///构建地图Widget
  static platform_map.PlatformMap buildPlatformMap(
      {required platform_map.LatLng target, double zoom = 0}) {
    return platform_map.PlatformMap(
      initialCameraPosition: platform_map.CameraPosition(
        target: target,
        zoom: zoom,
      ),
      markers: <platform_map.Marker>{
        platform_map.Marker(
          markerId: platform_map.MarkerId('marker_1'),
          position: const platform_map.LatLng(47.6, 8.8796),
          consumeTapEvents: true,
          infoWindow: const platform_map.InfoWindow(
            title: 'PlatformMarker',
            snippet: "Hi I'm a Platform Marker",
          ),
          onTap: () {
            logger.i("Marker tapped");
          },
        ),
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onTap: (location) => logger.i('onTap: $location'),
      onCameraMove: (cameraUpdate) => logger.i('onCameraMove: $cameraUpdate'),
      compassEnabled: true,
      onMapCreated: (controller) {
        Future.delayed(const Duration(seconds: 2)).then(
          (_) {
            controller.animateCamera(
              platform_map.CameraUpdate.newCameraPosition(
                const platform_map.CameraPosition(
                  bearing: 270.0,
                  target: platform_map.LatLng(51.5160895, -0.1294527),
                  tilt: 30.0,
                  zoom: 18,
                ),
              ),
            );
          },
        );
      },
    );
  }

  ///当前位置的地图
  Widget buildCurrentLocationLayer({
    Key? key,
    LocationMarkerStyle style = const LocationMarkerStyle(),
    Stream<LocationMarkerPosition>? positionStream,
    Stream<LocationMarkerHeading>? headingStream,
    Stream<double?>? centerCurrentLocationStream,
    Stream<void>? turnHeadingUpLocationStream,
    CenterOnLocationUpdate centerOnLocationUpdate =
        CenterOnLocationUpdate.never,
    TurnOnHeadingUpdate turnOnHeadingUpdate = TurnOnHeadingUpdate.never,
    Duration centerAnimationDuration = const Duration(milliseconds: 200),
    Curve centerAnimationCurve = Curves.fastOutSlowIn,
    Duration turnAnimationDuration = const Duration(milliseconds: 200),
    Curve turnAnimationCurve = Curves.easeInOut,
    Duration moveAnimationDuration = const Duration(milliseconds: 200),
    Curve moveAnimationCurve = Curves.fastOutSlowIn,
    Duration rotateAnimationDuration = const Duration(milliseconds: 200),
    Curve rotateAnimationCurve = Curves.easeInOut,
  }) {
    return CurrentLocationLayer(
      key: key,
      style: style,
      positionStream: positionStream,
      headingStream: headingStream,
      centerCurrentLocationStream: centerCurrentLocationStream,
      turnHeadingUpLocationStream: turnHeadingUpLocationStream,
      centerOnLocationUpdate: centerOnLocationUpdate,
      turnOnHeadingUpdate: turnOnHeadingUpdate,
      centerAnimationDuration: centerAnimationDuration,
      centerAnimationCurve: centerAnimationCurve,
      turnAnimationDuration: turnAnimationDuration,
      turnAnimationCurve: turnAnimationCurve,
      moveAnimationDuration: moveAnimationDuration,
      moveAnimationCurve: moveAnimationCurve,
      rotateAnimationDuration: rotateAnimationDuration,
      rotateAnimationCurve: rotateAnimationCurve,
    );
  }
}
