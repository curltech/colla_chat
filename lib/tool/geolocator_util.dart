import 'dart:async';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import 'package:map_launcher/map_launcher.dart' as map_launcher;
import 'package:map_launcher/map_launcher.dart';
import 'package:maps_launcher/maps_launcher.dart';
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

  ///获取安装的地图软件列表,android/ios,调用安装的地图应用
  static Future<List<map_launcher.AvailableMap>> installedMaps() async {
    final availableMaps = await map_launcher.MapLauncher.installedMaps;

    return availableMaps;
  }

  ///根据地图和位置调用安装的地图软件,android/ios,调用安装的地图应用
  static Future<void> showMarker(
      map_launcher.AvailableMap map, map_launcher.Coords coords,
      {required String title}) async {
    await map.showMarker(
      coords: coords,
      title: title,
    );
  }

  ///是否安装了地图类型,android/ios,调用安装的地图应用
  static Future<bool?> isMapAvailable(map_launcher.MapType mapType) async {
    return await map_launcher.MapLauncher.isMapAvailable(mapType);
  }

  ///根据地图的类型调用安装的地图软件,android/ios,调用安装的地图应用
  static Future<void> mapLauncher(
      {map_launcher.MapType? mapType,
      required double latitude,
      required double longitude,
      required String title,
      String? description}) async {
    var coords = map_launcher.Coords(latitude, longitude);
    if (mapType == null) {
      List<AvailableMap> availableMap = await installedMaps();
      if (availableMap.isNotEmpty) {
        mapType = availableMap.first.mapType;
      }
    }
    if (mapType != null) {
      await map_launcher.MapLauncher.showMarker(
        mapType: mapType,
        coords: coords,
        title: title,
        description: description,
      );
    }
  }

  ///构建地图Widget,Android/iOS
  static platform_map.PlatformMap buildPlatformMap(
      {required double latitude, required double longitude, double zoom = 0}) {
    var target = platform_map.LatLng(latitude, longitude);
    return platform_map.PlatformMap(
      initialCameraPosition: platform_map.CameraPosition(
        target: target,
        zoom: zoom,
      ),
      markers: <platform_map.Marker>{
        platform_map.Marker(
          markerId: platform_map.MarkerId('marker_1'),
          position: target,
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

  /// url地图
  static Future<bool> launchQuery(String query) async {
    return await MapsLauncher.launchQuery(query);
  }

  /// url地图
  static Future<bool> launchCoordinates(
    double latitude,
    double longitude, [
    String? label,
  ]) async {
    return await MapsLauncher.launchCoordinates(latitude, longitude, label);
  }

  /// 使用Open Street Map，需要翻墙
  static FlutterLocationPicker buildLocationPicker({
    Key? key,
    double? latitude,
    double? longitude,
    required void Function(PickedData) onPicked,
    void Function(Exception)? onError,
    double stepZoom = 1,
    double initZoom = 17,
    double minZoomLevel = 2,
    double maxZoomLevel = 18.4,
    String urlTemplate = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    String mapLanguage = 'en',
    String selectLocationButtonText = 'Set Current Location',
    Duration mapAnimationDuration = const Duration(milliseconds: 2000),
    bool trackMyPosition = false,
    bool showZoomController = true,
    bool showLocationController = true,
    bool showSelectLocationButton = true,
    ButtonStyle? selectLocationButtonStyle,
    Color? selectLocationTextColor,
    bool showSearchBar = true,
    Color? searchBarBackgroundColor,
    Color? searchBarTextColor,
    String searchBarHintText = 'Search location',
    Color? searchBarHintColor,
    Color? mapLoadingBackgroundColor,
    Color? locationButtonBackgroundColor,
    Color? zoomButtonsBackgroundColor,
    Color? zoomButtonsColor,
    Color? locationButtonsColor,
    Color markerIconColor = Colors.red,
    IconData markerIcon = Icons.location_pin,
    Widget? loadingWidget,
  }) {
    LatLong? latLong;
    if (latitude != null && longitude != null) {
      latLong = LatLong(latitude, longitude);
    }
    selectLocationButtonText = AppLocalizations.t(selectLocationButtonText);
    searchBarHintText = AppLocalizations.t(searchBarHintText);
    return FlutterLocationPicker(
      initPosition: latLong,
      key: key,
      onPicked: onPicked,
      onError: onError,
      stepZoom: stepZoom,
      initZoom: initZoom,
      minZoomLevel: minZoomLevel,
      maxZoomLevel: maxZoomLevel,
      urlTemplate: urlTemplate,
      mapLanguage: mapLanguage,
      selectLocationButtonText: selectLocationButtonText,
      mapAnimationDuration: mapAnimationDuration,
      trackMyPosition: trackMyPosition,
      showZoomController: showZoomController,
      showLocationController: showLocationController,
      showSelectLocationButton: showSelectLocationButton,
      selectLocationButtonStyle: selectLocationButtonStyle,
      selectLocationTextColor: selectLocationTextColor,
      showSearchBar: showSearchBar,
      searchBarBackgroundColor: searchBarBackgroundColor,
      searchBarTextColor: searchBarTextColor,
      searchBarHintText: searchBarHintText,
      searchBarHintColor: searchBarHintColor,
      mapLoadingBackgroundColor: mapLoadingBackgroundColor,
      locationButtonBackgroundColor: locationButtonBackgroundColor,
      zoomButtonsBackgroundColor: zoomButtonsBackgroundColor,
      zoomButtonsColor: zoomButtonsColor,
      locationButtonsColor: locationButtonsColor,
      markerIconColor: markerIconColor,
      markerIcon: markerIcon,
      loadingWidget: loadingWidget,
    );
  }
}
