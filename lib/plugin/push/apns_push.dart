import 'dart:async';

import 'package:flutter_apns/flutter_apns.dart';

class ApnsPush {
  final PushConnector connector = createPushConnector();

  configure() {
    connector.configure(
      onLaunch: (data) => onPush('onLaunch', data),
      onResume: (data) => onPush('onResume', data),
      onMessage: (data) => onPush('onMessage', data),
      onBackgroundMessage: _onBackgroundMessage,
    );

    connector.token.addListener(() {
      print('Token ${connector.token.value}');
    });
    connector.requestNotificationPermissions();

    //   connector.shouldPresent = (x) async {
    //     final remote = RemoteMessage.fromMap(x.payload);
    //     return remote.category == 'MEETING_INVITATION';
    //   };
    //   connector.setNotificationCategories([
    //     UNNotificationCategory(
    //       identifier: 'MEETING_INVITATION',
    //       actions: [
    //         UNNotificationAction(
    //           identifier: 'ACCEPT_ACTION',
    //           title: 'Accept',
    //           options: UNNotificationActionOptions.values,
    //         ),
    //         UNNotificationAction(
    //           identifier: 'DECLINE_ACTION',
    //           title: 'Decline',
    //           options: [],
    //         ),
    //       ],
    //       intentIdentifiers: [],
    //       options: UNNotificationCategoryOptions.values,
    //     ),
    //   ]);
  }

  Future<dynamic> onPush(String name, RemoteMessage payload) {
    final action = UNNotificationAction.getIdentifier(payload.data);

    if (action == 'MEETING_INVITATION') {
      // do something
    }

    return Future.value(true);
  }

  requestNotificationPermissions() {
    connector.requestNotificationPermissions();
  }

  Future<void> _onBackgroundMessage(RemoteMessage message) async {
    onPush('onBackgroundMessage', message);
  }
}
