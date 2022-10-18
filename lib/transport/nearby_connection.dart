import 'dart:async';
import 'dart:convert';

import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';

enum DeviceType { advertiser, browser }

class NearbyConnectionPool {
  final nearbyService = NearbyService();
  final _nearbyConnections = <String, Device>{};
  final _connectedNearbyConnections = <String, Device>{};
  StreamSubscription<dynamic>? subscription;
  StreamSubscription<dynamic>? receivedDataSubscription;

  NearbyConnectionPool();

  ///搜索附近的设备
  void search(DeviceType deviceType) async {
    String? devInfo;
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (platformParams.android) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      devInfo = androidInfo.model;
    }
    if (platformParams.ios) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      devInfo = iosInfo.localizedModel;
    }
    devInfo = devInfo ?? '';
    await nearbyService.init(
        serviceType: 'mpconn',
        deviceName: devInfo,
        strategy: Strategy.P2P_CLUSTER,
        callback: (isRunning) async {
          if (isRunning) {
            if (deviceType == DeviceType.browser) {
              await nearbyService.stopBrowsingForPeers();
              await Future.delayed(const Duration(microseconds: 200));
              await nearbyService.startBrowsingForPeers();
            } else {
              await nearbyService.stopAdvertisingPeer();
              await nearbyService.stopBrowsingForPeers();
              await Future.delayed(const Duration(microseconds: 200));
              await nearbyService.startAdvertisingPeer();
              await nearbyService.startBrowsingForPeers();
            }
          }
        });
    subscription = nearbyService.stateChangedSubscription(
        callback: (List<Device> devices) async {
      // _nearbyConnections.clear();
      // _connectedNearbyConnections.clear();
      for (var device in devices) {
        logger.i(
            " deviceId: ${device.deviceId} | deviceName: ${device.deviceName} | state: ${device.state}");

        if (platformParams.android) {
          if (device.state == SessionState.connected) {
            await nearbyService.stopBrowsingForPeers();
          } else {
            await nearbyService.startBrowsingForPeers();
          }
        }
        _nearbyConnections[device.deviceId] = device;
        if (device.state == SessionState.connected) {
          _connectedNearbyConnections[device.deviceId] = device;
        }
      }
    });

    receivedDataSubscription =
        nearbyService.dataReceivedSubscription(callback: (message) {
      onMessage(message);
    });
  }

  invitePeer(Device device) async {
    if (device.state == SessionState.notConnected) {
      await nearbyService.invitePeer(
        deviceID: device.deviceId,
        deviceName: device.deviceName,
      );
    }
  }

  disconnectPeer(Device device) async {
    if (device.state == SessionState.connected) {
      await nearbyService.disconnectPeer(deviceID: device.deviceId);
    }
  }

  FutureOr<dynamic> send(String deviceId, String message) {
    return nearbyService.sendMessage(deviceId, message);
  }

  onMessage(dynamic message) {
    logger.i("dataReceivedSubscription: ${jsonEncode(message)}");
  }

  void dispose() {
    if (subscription != null) {
      subscription!.cancel();
      subscription = null;
    }
    if (receivedDataSubscription != null) {
      receivedDataSubscription!.cancel();
      receivedDataSubscription = null;
    }
    nearbyService.stopBrowsingForPeers();
    nearbyService.stopAdvertisingPeer();
  }
}

final NearbyConnectionPool nearbyConnectionPool = NearbyConnectionPool();
