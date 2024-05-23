import 'dart:core';

import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 调用apple地图，用于IOS设备，
class AppleMapWidget extends StatelessWidget {
  late AppleMapController controller;
  CameraPosition initialCameraPosition;
  void Function(AppleMapController)? onMapCreated;
  Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  bool compassEnabled = true;
  bool trafficEnabled = false;
  MapType mapType = MapType.standard;
  MinMaxZoomPreference minMaxZoomPreference = MinMaxZoomPreference.unbounded;
  TrackingMode trackingMode = TrackingMode.none;
  bool rotateGesturesEnabled = true;
  bool scrollGesturesEnabled = true;
  bool zoomGesturesEnabled = true;
  bool pitchGesturesEnabled = true;
  bool myLocationEnabled = false;
  bool myLocationButtonEnabled = false;
  EdgeInsets padding = EdgeInsets.zero;
  Set<Annotation>? annotations;
  Set<Polyline>? polylines;
  Set<Circle>? circles;
  Set<Polygon>? polygons;
  void Function()? onCameraMoveStarted;
  void Function(CameraPosition)? onCameraMove;
  void Function()? onCameraIdle;
  void Function(LatLng)? onTap;
  void Function(LatLng)? onLongPress;
  SnapshotOptions? snapshotOptions;
  bool insetsLayoutMarginsFromSafeArea = true;

  AppleMapWidget({
    super.key,
    required this.initialCameraPosition,
    this.onMapCreated,
    this.gestureRecognizers,
    this.compassEnabled = true,
    this.trafficEnabled = false,
    this.mapType = MapType.standard,
    this.minMaxZoomPreference = MinMaxZoomPreference.unbounded,
    this.trackingMode = TrackingMode.none,
    this.rotateGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.pitchGesturesEnabled = true,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.padding = EdgeInsets.zero,
    this.annotations,
    this.polylines,
    this.circles,
    this.polygons,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.onTap,
    this.onLongPress,
    this.snapshotOptions,
    this.insetsLayoutMarginsFromSafeArea = true,
  }) {
    onMapCreated = (AppleMapController controller) {
      this.controller = controller;
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppleMap(
      key: super.key,
      initialCameraPosition: initialCameraPosition,
      onMapCreated: onMapCreated,
      gestureRecognizers: gestureRecognizers,
      compassEnabled: compassEnabled,
      trafficEnabled: trafficEnabled,
      mapType: mapType,
      minMaxZoomPreference: minMaxZoomPreference,
      trackingMode: trackingMode,
      rotateGesturesEnabled: rotateGesturesEnabled,
      scrollGesturesEnabled: scrollGesturesEnabled,
      zoomGesturesEnabled: zoomGesturesEnabled,
      pitchGesturesEnabled: pitchGesturesEnabled,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationButtonEnabled,
      padding: padding,
      annotations: annotations,
      polylines: polylines,
      circles: circles,
      polygons: polygons,
      onCameraMoveStarted: onCameraMoveStarted,
      onCameraMove: onCameraMove,
      onCameraIdle: onCameraIdle,
      onTap: onTap,
      onLongPress: onLongPress,
      snapshotOptions: snapshotOptions,
      insetsLayoutMarginsFromSafeArea: insetsLayoutMarginsFromSafeArea,
    );
  }
}
