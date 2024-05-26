import 'dart:core';
import 'dart:math';
import 'dart:ui';

import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/geolocator_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

/// 调用apple地图，用于IOS设备，
class AppleMapWidget extends StatefulWidget {
  CameraPosition initialCameraPosition;
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
  Set<Polyline>? polylines;
  Set<Circle>? circles;
  Set<Polygon>? polygons;
  void Function()? onCameraMoveStarted;
  void Function(CameraPosition)? onCameraMove;
  void Function()? onCameraIdle;
  void Function({LocationPosition? locationPosition})? onSelectedMarker;
  SnapshotOptions? snapshotOptions;
  bool insetsLayoutMarginsFromSafeArea = true;

  AppleMapWidget({
    super.key,
    required this.initialCameraPosition,
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
    this.polylines,
    this.circles,
    this.polygons,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.onSelectedMarker,
    this.snapshotOptions,
    this.insetsLayoutMarginsFromSafeArea = true,
  });

  @override
  State<StatefulWidget> createState() => AppleMapWidgetState();
}

class AppleMapWidgetState extends State<AppleMapWidget> {
  AppleMapWidgetState();

  late AppleMapController controller;
  Annotation? selectedAnnotation;
  String selectedAnnotationId = 'SelectedAnnotation';
  ValueNotifier<LocationPosition?> locationPosition =
      ValueNotifier<LocationPosition?>(null);

  @override
  void initState() {
    super.initState();
  }

  // 增加标记
  Future<void> _add(LocationPosition locationPosition) async {
    final AnnotationId annotationId = AnnotationId(selectedAnnotationId);
    BitmapDescriptor bitMapDescriptor =
        BitmapDescriptor.markerAnnotationWithHue(BitmapDescriptor.hueRed);
    selectedAnnotation = Annotation(
        annotationId: annotationId,
        icon: bitMapDescriptor,
        position: LatLng(locationPosition.latitude, locationPosition.longitude),
        draggable: true,
        zIndex: 1,
        infoWindow: const InfoWindow(
          anchor: Offset(0.5, 1),
          snippet: '*',
        ));
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
    setState(() {});
  }

  void _remove() {
    setState(() {
      selectedAnnotation = null;
    });
  }

  Future<void> _changeInfo() async {
    if (selectedAnnotation != null) {
      final String newSnippet = selectedAnnotation!.infoWindow.snippet! +
          (selectedAnnotation!.infoWindow.snippet!.length % 10 == 0
              ? '\n'
              : '*');
      setState(() {
        selectedAnnotation = selectedAnnotation!.copyWith(
          infoWindowParam: selectedAnnotation!.infoWindow.copyWith(
            snippetParam: newSnippet,
          ),
        );
      });
    }
  }

  Future<void> _changeAlpha() async {
    final double current = selectedAnnotation!.alpha;
    setState(() {
      if (selectedAnnotation != null) {
        selectedAnnotation = selectedAnnotation!.copyWith(
          alphaParam: current < 0.1 ? 1.0 : current * 0.75,
        );
      }
    });
  }

  Future<void> _showInfoWindow() async {
    if (selectedAnnotation != null) {
      await controller.showMarkerInfoWindow(selectedAnnotation!.annotationId);
    }
  }

  Future<void> _hideInfoWindow() async {
    if (selectedAnnotation != null) {
      controller.hideMarkerInfoWindow(selectedAnnotation!.annotationId);
    }
  }

  List<ActionData> _buildMapActionData() {
    final List<ActionData> mapPopActionData = [];
    mapPopActionData.add(ActionData(
        label: 'Remove',
        tooltip: 'Remove annotation',
        icon: const Icon(Icons.remove)));
    mapPopActionData.add(ActionData(
        label: 'Change',
        tooltip: 'Change info',
        icon: const Icon(Icons.change_circle_outlined)));
    mapPopActionData.add(ActionData(
        label: 'Alpha',
        tooltip: 'Change alpha',
        icon: const Icon(Icons.sort_by_alpha_outlined)));
    mapPopActionData.add(ActionData(
        label: 'Show',
        tooltip: 'Show infoWindow',
        icon: const Icon(Icons.visibility)));
    mapPopActionData.add(ActionData(
        label: 'Hide',
        tooltip: 'Hide infoWindow',
        icon: const Icon(Icons.visibility_off_outlined)));

    return mapPopActionData;
  }

  _onMaoPopAction(BuildContext context, int index, String label,
      {String? value}) async {
    switch (label) {
      case 'Remove':
        _remove();
      case 'Change':
        _changeInfo();
      case 'Alpha':
        _changeAlpha();
      case 'Show':
        _showInfoWindow();
      case 'Hide':
        _hideInfoWindow();
    }
  }

  Widget _buildAppleMapWidget(BuildContext context) {
    return AppleMap(
      key: widget.key,
      initialCameraPosition: widget.initialCameraPosition,
      onMapCreated: (controller) {
        this.controller = controller;
        LocationPosition locationPosition = LocationPosition(
            latitude: widget.initialCameraPosition.target.latitude,
            longitude: widget.initialCameraPosition.target.longitude);
        _add(locationPosition);
        controller.moveCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(widget.initialCameraPosition.target.latitude,
                widget.initialCameraPosition.target.longitude),
            14.0,
          ),
        );
      },
      gestureRecognizers: widget.gestureRecognizers,
      compassEnabled: widget.compassEnabled,
      trafficEnabled: widget.trafficEnabled,
      mapType: widget.mapType,
      minMaxZoomPreference: widget.minMaxZoomPreference,
      trackingMode: widget.trackingMode,
      rotateGesturesEnabled: widget.rotateGesturesEnabled,
      scrollGesturesEnabled: widget.scrollGesturesEnabled,
      zoomGesturesEnabled: widget.zoomGesturesEnabled,
      pitchGesturesEnabled: widget.pitchGesturesEnabled,
      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: widget.myLocationButtonEnabled,
      padding: widget.padding,
      annotations: selectedAnnotation != null ? {selectedAnnotation!} : null,
      polylines: widget.polylines,
      circles: widget.circles,
      polygons: widget.polygons,
      onCameraMoveStarted: widget.onCameraMoveStarted,
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
      onTap: (position) {
        LocationPosition locationPosition = LocationPosition(
            latitude: position.latitude, longitude: position.longitude);
        _add(locationPosition);
      },
      onLongPress: null,
      snapshotOptions: widget.snapshotOptions,
      insetsLayoutMarginsFromSafeArea: widget.insetsLayoutMarginsFromSafeArea,
    );
  }

  _onLongPress(LatLng latLng) async {
    await DialogUtil.show(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            elevation: 0.0,
            insetPadding: EdgeInsets.zero,
            child: DataActionCard(
                onPressed: (int index, String label, {String? value}) {
                  Navigator.pop(context);
                  _onMaoPopAction(context, index, label, value: value);
                },
                crossAxisCount: 4,
                actions: _buildMapActionData(),
                height: 200,
                width: appDataProvider.secondaryBodyWidth,
                iconSize: 30));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildAppleMapWidget(context)),
        Row(
          children: [
            TextButton(
                onPressed: () async {
                  bool? confirm = await DialogUtil.confirm(context,
                      content:
                          'Selected position:${locationPosition.value!.latitude},${locationPosition.value!.longitude}, name:${locationPosition.value!.name}, address:${locationPosition.value!.address}, and selected?');
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
