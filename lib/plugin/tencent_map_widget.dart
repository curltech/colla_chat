import 'dart:core';

import 'package:flutter/material.dart';
import 'package:tencent_map_flutter/tencent_map_flutter.dart';

/// 调用tencent地图，用于移动设备，有流量限制，功能强大
class TencentMapWidget extends StatelessWidget {
  late TencentMapController controller;

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

  late final void Function(TencentMapController)? onMapCreated;

  final void Function(double)? onScaleViewChanged;
  late final void Function(Position)? onPress;
  late final void Function(Position)? onLongPress;
  late final void Function(Poi)? onTapPoi;
  final void Function(CameraPosition)? onCameraMoveStart;
  final void Function(CameraPosition)? onCameraMove;
  final void Function(CameraPosition)? onCameraMoveEnd;
  late final void Function(String)? onTapMarker;
  final void Function(String, Position)? onMarkerDragStart;
  final void Function(String, Position)? onMarkerDrag;
  final void Function(String, Position)? onMarkerDragEnd;
  final void Function(Location)? onLocation;
  final void Function(Position)? onUserLocationClick;

  final String markerId = 'current_marker_id';

  double? latitude;
  double? longitude;

  TencentMapWidget({
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
    this.onMapCreated,
    this.onScaleViewChanged,
    this.onPress,
    this.onLongPress,
    this.onTapPoi,
    this.onCameraMoveStart,
    this.onCameraMove,
    this.onCameraMoveEnd,
    this.onTapMarker,
    this.onMarkerDragStart,
    this.onMarkerDrag,
    this.onMarkerDragEnd,
    this.onLocation,
    this.onUserLocationClick,
    this.latitude,
    this.longitude,
  }) {
    onMapCreated = (TencentMapController controller) {
      this.controller = controller;
      if (latitude != null && longitude != null) {
        _onTap(Position(latitude: latitude!, longitude: longitude!));
      }
    };
    onPress = _onTap;
    onLongPress = _onTap;
    onTapPoi = (poi) => _onTap(poi.position);
    onTapMarker = _onTapMarker;
  }

  void _onTap(Position position) async {
    latitude = position.latitude;
    longitude = position.longitude;
    final marker = Marker(
      id: markerId,
      position: position,
      icon: Bitmap(asset: 'images/marker.png'),
      anchor: Anchor(x: 0.5, y: 1),
      draggable: true,
    );
    controller.addMarker(marker);
  }

  void _onTapMarker(String markerId) {
    controller.removeMarker(markerId);
  }

  @override
  Widget build(BuildContext context) {
    return TencentMap(
      key: super.key,
      androidTexture: androidTexture,
      mapType: mapType,
      mapStyle: mapStyle,
      logoScale: logoScale,
      logoPosition: logoPosition,
      scalePosition: scalePosition,
      compassOffset: compassOffset,
      compassEnabled: compassEnabled,
      scaleEnabled: scaleEnabled,
      scaleFadeEnabled: scaleFadeEnabled,
      rotateGesturesEnabled: rotateGesturesEnabled,
      scrollGesturesEnabled: scrollGesturesEnabled,
      zoomGesturesEnabled: zoomGesturesEnabled,
      skewGesturesEnabled: skewGesturesEnabled,
      trafficEnabled: trafficEnabled,
      indoorViewEnabled: indoorViewEnabled,
      indoorPickerEnabled: indoorPickerEnabled,
      buildingsEnabled: buildingsEnabled,
      buildings3dEnabled: buildings3dEnabled,
      myLocationEnabled: myLocationEnabled,
      userLocationType: userLocationType,
      onMapCreated: onMapCreated,
      onScaleViewChanged: onScaleViewChanged,
      onPress: onPress,
      onLongPress: onLongPress,
      onTapPoi: onTapPoi,
      onCameraMoveStart: onCameraMoveStart,
      onCameraMove: onCameraMove,
      onCameraMoveEnd: onCameraMoveEnd,
      onTapMarker: onTapMarker,
      onMarkerDragStart: onMarkerDragStart,
      onMarkerDrag: onMarkerDrag,
      onMarkerDragEnd: onMarkerDragEnd,
      onLocation: onLocation,
      onUserLocationClick: onUserLocationClick,
    );
  }
}
