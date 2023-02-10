import 'dart:async';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/pages/chat/index/global_chat_message_controller.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';

enum DeviceType { advertiser, browser }

class NearbyConnectionPool with ChangeNotifier {
  final nearbyService = NearbyService();
  final _nearbyConnections = <String, Device>{};
  final _connectedNearbyConnections = <String, Device>{};
  StreamSubscription<dynamic>? subscription;
  StreamSubscription<dynamic>? receivedDataSubscription;

  NearbyConnectionPool();

  Map<String, Device> get nearbyConnections {
    return _nearbyConnections;
  }

  Map<String, Device> get connectedNearbyConnections {
    return _connectedNearbyConnections;
  }

  ///搜索附近的设备
  Future<dynamic> search(DeviceType deviceType) async {
    String? devInfo;
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (platformParams.android) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      devInfo = androidInfo.model;
    } else if (platformParams.ios) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      devInfo = iosInfo.localizedModel;
    }
    devInfo = devInfo ?? '';
    var result = await nearbyService.init(
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
      notifyListeners();
    });

    receivedDataSubscription =
        nearbyService.dataReceivedSubscription(callback: (message) {
      onMessage(message);
    });

    return result;
  }

  FutureOr<dynamic> invitePeer(Device device) async {
    if (device.state == SessionState.notConnected) {
      return await nearbyService.invitePeer(
        deviceID: device.deviceId,
        deviceName: device.deviceName,
      );
    }
  }

  FutureOr<dynamic> disconnectPeer(Device device) async {
    if (device.state == SessionState.connected) {
      return await nearbyService.disconnectPeer(deviceID: device.deviceId);
    }
  }

  FutureOr<dynamic> send(String deviceId, dynamic obj) {
    var jsonStr = JsonUtil.toJsonString(obj);
    List<int> data = CryptoUtil.stringToUtf8(jsonStr);
    String message = CryptoUtil.encodeBase64(data);
    if (_connectedNearbyConnections.containsKey(deviceId)) {
      return nearbyService.sendMessage(deviceId, message);
    } else {
      return false;
    }
  }

  onMessage(dynamic message) async {
    String data = CryptoUtil.utf8ToString(message);
    var json = JsonUtil.toJson(data);
    ChatMessage chatMessage = ChatMessage.fromJson(json);

    await globalChatMessageController.receiveChatMessage(chatMessage);
  }

  @override
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
    super.dispose();
  }
}

final NearbyConnectionPool nearbyConnectionPool = NearbyConnectionPool();
