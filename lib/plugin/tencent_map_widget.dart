import 'dart:core';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/geolocator_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tencent_map_flutter/tencent_map_flutter.dart';

/// 调用tencent地图，用于移动设备，有流量限制，功能强大
class TencentMapWidget extends StatefulWidget {
  final bool androidTexture;

  final MapType mapType;

  final int? mapStyle;
  final double logoScale;

  final UIControlPosition? logoPosition;
  final UIControlPosition? scalePosition;
  final UIControlOffset? compassOffset;
  final bool compassEnabled;

  final bool scaleEnabled;

  final bool scaleFadeEnabled;

  final bool rotateGesturesEnabled;

  final bool scrollGesturesEnabled;

  final bool zoomGesturesEnabled;

  final bool skewGesturesEnabled;

  final bool trafficEnabled;

  final bool indoorViewEnabled;

  final bool indoorPickerEnabled;

  final bool buildingsEnabled;

  final bool buildings3dEnabled;

  final bool myLocationEnabled;

  final UserLocationType userLocationType;

  final void Function(double)? onScaleViewChanged;
  final void Function(CameraPosition)? onCameraMoveStart;
  final void Function(CameraPosition)? onCameraMove;
  final void Function(CameraPosition)? onCameraMoveEnd;
  final void Function(String, LatLng)? onMarkerDragStart;
  final void Function(String, LatLng)? onMarkerDrag;
  final void Function(String, LatLng)? onMarkerDragEnd;
  final void Function(LatLng)? onLongPress;
  final void Function(Location)? onLocation;
  final void Function(LatLng)? onUserLocationClick;
  final void Function({LocationPosition? locationPosition})? onSelectedMarker;

  final double latitude;
  final double longitude;

  const TencentMapWidget({
    super.key,
    this.androidTexture = false,
    this.mapType = MapType.normal,
    this.mapStyle,
    this.logoScale = 1.0,
    this.logoPosition,
    this.scalePosition,
    this.compassOffset,
    this.compassEnabled = true,
    this.scaleEnabled = true,
    this.scaleFadeEnabled = true,
    this.rotateGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.skewGesturesEnabled = true,
    this.trafficEnabled = false,
    this.indoorViewEnabled = false,
    this.indoorPickerEnabled = false,
    this.buildingsEnabled = true,
    this.buildings3dEnabled = false,
    this.myLocationEnabled = false,
    this.userLocationType = UserLocationType.trackingLocationRotate,
    this.onScaleViewChanged,
    this.onCameraMoveStart,
    this.onCameraMove,
    this.onCameraMoveEnd,
    this.onMarkerDragStart,
    this.onMarkerDrag,
    this.onMarkerDragEnd,
    this.onLocation,
    this.onUserLocationClick,
    required this.latitude,
    required this.longitude,
    this.onSelectedMarker,
    this.onLongPress,
  });

  @override
  State<StatefulWidget> createState() => TencentMapWidgetState();
}

class TencentMapWidgetState extends State<TencentMapWidget> {
  TencentMapWidgetState();

  late TencentMapController controller;
  Marker? selectedMarker;
  String selectedMarkerId = 'SelectedMarker';
  ValueNotifier<LocationPosition?> locationPosition =
      ValueNotifier<LocationPosition?>(null);

  @override
  void initState() {
    super.initState();
    TencentMap.init(agreePrivacy: true);
    requestLocationPermission();
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status != PermissionStatus.granted) {
      await Permission.location.request();
    }
  }

  void _add(LocationPosition locationPosition) async {
    controller.removeMarker(selectedMarkerId);
    selectedMarker = Marker(
      id: selectedMarkerId,
      position: LatLng(locationPosition.latitude, locationPosition.longitude),
      icon: Bitmap(asset: 'assets/images/marker.png'),
      anchor: Anchor(x: 0.5, y: 1),
      draggable: true,
    );
    controller.addMarker(selectedMarker!);
    List<geocoding.Placemark> placemarks =
        await GeolocatorUtil.placemarkFromCoordinates(
            locationPosition.latitude, locationPosition.longitude);
    if (placemarks.isNotEmpty) {
      geocoding.Placemark placemark = placemarks.first;
      locationPosition.name ??= placemark.name;
      locationPosition.address =
          '${placemark.street}\n${placemark.subLocality} ${placemark.locality} ${placemark.administrativeArea} ${placemark.country}';
      logger.w('placemarkFromCoordinates address:${locationPosition.address}');
    }
    this.locationPosition.value = locationPosition;
  }

  Widget _buildTencentMap(BuildContext context) {
    return TencentMap(
      key: widget.key,
      androidTexture: widget.androidTexture,
      mapType: widget.mapType,
      mapStyle: widget.mapStyle,
      logoScale: widget.logoScale,
      logoPosition: widget.logoPosition,
      scalePosition: widget.scalePosition,
      compassOffset: widget.compassOffset,
      compassEnabled: widget.compassEnabled,
      scaleEnabled: widget.scaleEnabled,
      scaleFadeEnabled: widget.scaleFadeEnabled,
      rotateGesturesEnabled: widget.rotateGesturesEnabled,
      scrollGesturesEnabled: widget.scrollGesturesEnabled,
      zoomGesturesEnabled: widget.zoomGesturesEnabled,
      skewGesturesEnabled: widget.skewGesturesEnabled,
      trafficEnabled: widget.trafficEnabled,
      indoorViewEnabled: widget.indoorViewEnabled,
      indoorPickerEnabled: widget.indoorPickerEnabled,
      buildingsEnabled: widget.buildingsEnabled,
      buildings3dEnabled: widget.buildings3dEnabled,
      myLocationEnabled: widget.myLocationEnabled,
      userLocationType: widget.userLocationType,
      onMapCreated: (controller) {
        this.controller = controller;
        LocationPosition locationPosition = LocationPosition(
            latitude: widget.latitude, longitude: widget.longitude);
        _add(locationPosition);
        controller.moveCamera(
          CameraPosition(
            position: LatLng(widget.latitude, widget.longitude),
            zoom: 14,
          ),
        );
      },
      onScaleViewChanged: widget.onScaleViewChanged,
      onPress: (position) {
        LocationPosition locationPosition = LocationPosition(
            latitude: position.latitude, longitude: position.longitude);
        _add(locationPosition);
      },
      onLongPress: widget.onLongPress,
      onTapPoi: (poi) {
        LocationPosition locationPosition = LocationPosition(
            latitude: poi.position.latitude,
            longitude: poi.position.longitude,
            name: poi.name);
        _add(locationPosition);
      },
      onCameraMoveStart: widget.onCameraMoveStart,
      onCameraMove: widget.onCameraMove,
      onCameraMoveEnd: widget.onCameraMoveEnd,
      onTapMarker: (markId) async {},
      onMarkerDragStart: widget.onMarkerDragStart,
      onMarkerDrag: widget.onMarkerDrag,
      onMarkerDragEnd: widget.onMarkerDragEnd,
      onLocation: widget.onLocation,
      onUserLocationClick: (position) async {
        LocationPosition locationPosition = LocationPosition(
            latitude: position.latitude, longitude: position.longitude);
        _add(locationPosition);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildTencentMap(context)),
        Row(
          children: [
            TextButton(
                onPressed: () async {
                  bool? confirm = await DialogUtil.confirm(
                      content:
                          'Selected position:${locationPosition.value?.latitude},${locationPosition.value?.longitude}, name:${locationPosition.value?.name}, address:${locationPosition.value?.address}, and selected?');
                  if (confirm == true) {
                    if (widget.onSelectedMarker != null) {
                      widget.onSelectedMarker!(
                          locationPosition: locationPosition.value);
                    }
                  }
                },
                child: Text(AppLocalizations.t('Select'))),
            ValueListenableBuilder(
                valueListenable: locationPosition,
                builder: (BuildContext context,
                    LocationPosition? locationPosition, Widget? child) {
                  return CommonAutoSizeText(
                      '${locationPosition?.name ?? ''}\n${locationPosition?.address ?? ''}',
                      maxLines: 4);
                }),
          ],
        ),
      ],
    );
  }
}
