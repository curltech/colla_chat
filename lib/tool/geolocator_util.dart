import 'dart:async';

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple_maps;
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import 'package:map_launcher/map_launcher.dart' as map_launcher;

class LocationPosition {
  double latitude;
  double longitude;
  double? altitude;
  double? accuracy;
  double? heading;
  int? floor;
  double? speed;
  double? speedAccuracy;
  bool? isMocked;
  String? address;
  Map<String, dynamic>? addressData;

  LocationPosition({
    required this.longitude,
    required this.latitude,
    this.accuracy,
    this.altitude,
    this.heading,
    this.speed,
    this.speedAccuracy,
    this.address,
    this.addressData,
    this.floor,
    this.isMocked = false,
  });

  LocationPosition.fromJson(Map<String, dynamic> json)
      : latitude = json['latitude'] ?? 0,
        longitude = json['longitude'] ?? 0,
        altitude = json['altitude'] ?? 0.0,
        accuracy = json['accuracy'] ?? 0.0,
        heading = json['heading'] ?? 0.0,
        floor = json['floor'],
        speed = json['speed'] ?? 0.0,
        speedAccuracy = json['speed_accuracy'] ?? 0.0,
        isMocked = json['is_mocked'] ?? false,
        address = json['address'];

  Map<String, dynamic> toJson() => {
        'longitude': longitude,
        'latitude': latitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'floor': floor,
        'heading': heading,
        'speed': speed,
        'speed_accuracy': speedAccuracy,
        'is_mocked': isMocked,
        'address': address,
      };
}

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
  static double distance(latlong2.LatLng x, latlong2.LatLng y) {
    const latlong2.Distance distance = latlong2.Distance();
    final double meter = distance(x, y);

    return meter;
  }

  static latlong2.LatLng offset(latlong2.LatLng x) {
    const latlong2.Distance distance = latlong2.Distance();
    final num distanceInMeter = (6378 * latlong2.pi / 4).round();
    final p = distance.offset(x, distanceInMeter, 180);
    // LatLng(latitude:-45.219848, longitude:0.0)
    logger.i(p.round());
    // 45° 13' 11.45" S, 0° 0' 0.00" O
    logger.i(p.toSexagesimal());

    return p;
  }

  static latlong2.Path<latlong2.LatLng> smoothPath(
      Iterable<latlong2.LatLng> coordinates) {
    // zigzag is a list of coordinates
    final latlong2.Path path = latlong2.Path.from(coordinates);

    // Result is below
    final latlong2.Path steps = path.equalize(8, smoothPath: true);

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

  ///是否安装了地图软件,android/ios,调用安装的地图应用
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
      List<map_launcher.AvailableMap> availableMap = await installedMaps();
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

  /// 谷歌地图，需要price key
  static google_maps.GoogleMap buildGoogleMap({
    Key? key,
    required double latitude,
    required double longitude,
    double bearing = 0, //方向
    double tilt = 0, //角度
    double zoom = 0,
  }) {
    Completer<google_maps.GoogleMapController> controllerCompleter =
        Completer();
    google_maps.CameraPosition cameraPosition = google_maps.CameraPosition(
        bearing: bearing,
        target: google_maps.LatLng(longitude, latitude),
        tilt: tilt,
        zoom: zoom);

    return google_maps.GoogleMap(
      key: key,
      mapType: google_maps.MapType.hybrid,
      initialCameraPosition: cameraPosition,
      onMapCreated: (google_maps.GoogleMapController controller) {
        controllerCompleter.complete(controller);
      },
    );
  }

  /// 苹果地图
  static apple_maps.AppleMap buildAppleMap({
    Key? key,
    required double latitude,
    required double longitude,
    double bearing = 0, //方向
    double tilt = 0, //角度
    double zoom = 0,
  }) {
    Completer<apple_maps.AppleMapController> controllerCompleter = Completer();
    apple_maps.CameraPosition cameraPosition = apple_maps.CameraPosition(
        heading: bearing,
        target: apple_maps.LatLng(longitude, latitude),
        pitch: tilt,
        zoom: zoom);

    return apple_maps.AppleMap(
      key: key,
      mapType: apple_maps.MapType.hybrid,
      initialCameraPosition: cameraPosition,
      onMapCreated: (apple_maps.AppleMapController controller) {
        controllerCompleter.complete(controller);
      },
    );
  }

  /// 使用Open Street Map，需要翻墙，支持所有的平台
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
    String mapLanguage = 'cn',
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
    Widget? markerIcon = const Icon(
      Icons.location_pin,
      color: Colors.red,
    ),
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
      markerIcon: markerIcon,
      loadingWidget: loadingWidget,
    );
  }
}
