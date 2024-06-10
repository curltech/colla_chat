import 'dart:async';

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple_maps;
import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/apple_map_widget.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/plugin/tencent_map_widget.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import 'package:map_launcher/map_launcher.dart' as map_launcher;
import 'package:tencent_map_flutter/tencent_map_flutter.dart' as tencent_map;

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
  String? name;
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
    this.name,
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
        name = json['name'],
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
        'name': name,
        'address': address,
      };
}

class GeolocatorUtil {
  ///以下是基本的定位服务提供的功能，主要是经纬度的获取
  static Future<LocationPermission> checkPermission(
      BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermission.denied;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      bool? confirm = await DialogUtil.confirm(context,
          content:
              'The app has no location permission, do you want to set it?');
      if (confirm != null && confirm) {
        // await Geolocator.openAppSettings();
        await Geolocator.openLocationSettings();
      }
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  static Future<Position?> currentPosition(
    BuildContext context, {
    LocationAccuracy desiredAccuracy = LocationAccuracy.bestForNavigation,
    bool forceAndroidLocationManager = false,
    Duration? timeLimit,
  }) async {
    LocationPermission permission = await checkPermission(context);
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: desiredAccuracy,
          forceAndroidLocationManager: forceAndroidLocationManager,
          timeLimit: timeLimit);
    }
    return null;
  }

  static Future<Position?> lastKnownPosition(BuildContext context,
      {bool forceAndroidLocationManager = false}) async {
    LocationPermission permission = await checkPermission(context);
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: forceAndroidLocationManager,
      );
    }
    return null;
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

  /// 以下是经纬度与地址之间的转换查询，采用apple和google的地图服务
  static Future<List<geocoding.Location>> locationFromAddress(
      String address) async {
    if (await isPresent()) {
      try {
        List<geocoding.Location> locations =
            await geocoding.locationFromAddress(address);

        return locations;
      } catch (e) {
        logger.e('locationFromAddress error:$e');
      }
    }
    return [];
  }

  static Future<List<geocoding.Placemark>> placemarkFromCoordinates(
      double latitude, double longitude) async {
    if (await isPresent()) {
      try {
        List<geocoding.Placemark> placemarks =
            await geocoding.placemarkFromCoordinates(latitude, longitude);

        return placemarks;
      } catch (e) {
        logger.e('placemarkFromCoordinates error:$e');
      }
    }
    return [];
  }

  //设置语言国家，en_US，zh_CN
  static setLocaleIdentifier(String localeIdentifier) async {
    await geocoding.setLocaleIdentifier(localeIdentifier);
  }

  static Future<bool> isPresent() async {
    return await geocoding.isPresent();
  }

  ///以下是计算经纬度，计算地图距离
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
    logger.i(p.round().toString());
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
  static FlutterLocationPicker buildOpenStreetLocationPicker({
    Key? key,
    double? latitude,
    double? longitude,
    required void Function(PickedData) onPicked,
    void Function(Exception)? onError,
    double stepZoom = 1,
    double initZoom = 17,
    double minZoomLevel = 2,
    double maxZoomLevel = 18.4,
    String urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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

  static TencentMapWidget buildTencentLocationPicker(
      {Key? key,
      required double latitude,
      required double longitude,
      required void Function({LocationPosition? locationPosition})
          onSelectedMarker}) {
    return TencentMapWidget(
        androidTexture: true,
        myLocationEnabled: true,
        latitude: latitude,
        longitude: longitude,
        userLocationType: tencent_map.UserLocationType.trackingLocationRotate,
        onSelectedMarker: ({LocationPosition? locationPosition}) {
          onSelectedMarker(locationPosition: locationPosition);
        });
  }

  static Widget buildAppleLocationPicker(
      {Key? key,
      required double latitude,
      required double longitude,
      required void Function({LocationPosition? locationPosition})
          onSelectedMarker}) {
    Widget appleMapWidget = AppleMapWidget(
      initialCameraPosition: CameraPosition(
        target: LatLng(latitude, longitude),
        zoom: 11,
      ),
      myLocationEnabled: true,
      onSelectedMarker: ({LocationPosition? locationPosition}) {
        onSelectedMarker(locationPosition: locationPosition);
      },
    );

    return appleMapWidget;
  }

  static Widget showPosition(double latitude, double longitude,
      {BuildContext? context, String? title}) {
    title ??= AppLocalizations.t('Current position');
    if (platformParams.mobile) {
      GeolocatorUtil.mapLauncher(
          title: title, latitude: latitude, longitude: longitude);
    } else {
      if (context != null) {
        DialogUtil.show(
            context: context,
            builder: (BuildContext? context) {
              return Card(
                  elevation: 0.0,
                  margin: EdgeInsets.zero,
                  shape: const ContinuousRectangleBorder(),
                  child: Column(children: [
                    Text(title!),
                    Expanded(
                        child: GeolocatorUtil.buildOpenStreetLocationPicker(
                            latitude: latitude,
                            longitude: longitude,
                            onPicked: (PickedData data) {
                              Navigator.pop(context!);
                            }))
                  ]));
            });
      } else {
        return GeolocatorUtil.buildOpenStreetLocationPicker(
            latitude: latitude, longitude: longitude, onPicked: (data) {});
      }
    }
    return Container();
  }

  static Widget buildLocationPicker(
      {Key? key,
      required double latitude,
      required double longitude,
      required void Function({LocationPosition? locationPosition})
          onSelectedMarker}) {
    if (platformParams.ios) {
      return buildAppleLocationPicker(
        latitude: latitude,
        longitude: longitude,
        onSelectedMarker: onSelectedMarker,
      );
    } else if (platformParams.android) {
      return buildTencentLocationPicker(
        latitude: latitude,
        longitude: longitude,
        onSelectedMarker: ({LocationPosition? locationPosition}) {
          onSelectedMarker(locationPosition: locationPosition);
        },
      );
    } else {
      return GeolocatorUtil.buildOpenStreetLocationPicker(
          latitude: latitude,
          longitude: longitude,
          onPicked: (PickedData data) {
            longitude = data.latLong.longitude;
            latitude = data.latLong.latitude;
            String address = data.address;
            LocationPosition? locationPosition = LocationPosition(
                latitude: latitude, longitude: longitude, address: address);
            onSelectedMarker(locationPosition: locationPosition);
          });
    }
  }
}
