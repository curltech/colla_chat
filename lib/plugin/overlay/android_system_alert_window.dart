import 'dart:isolate';
import 'dart:ui';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:flutter/material.dart';
import 'package:system_alert_window/system_alert_window.dart';

class AndroidSystemAlertWindow {
  appToForeground() {
    // AppToForeground.appToForeground();
  }

  Future<bool?> requestPermissions(
      {SystemWindowPrefMode prefMode = SystemWindowPrefMode.OVERLAY}) async {
    return await SystemAlertWindow.requestPermissions(prefMode: prefMode);
  }

  /// 显示系统窗口
  show() {
    // 系统窗口头
    SystemWindowHeader header = SystemWindowHeader(
        title: SystemWindowText(
            text: AppLocalizations.t('Incoming Call'),
            fontSize: 10,
            textColor: Colors.black45),
        padding: SystemWindowPadding.setSymmetricPadding(12, 12),
        subTitle: SystemWindowText(
            text: AppLocalizations.t('9898989899'),
            fontSize: 14,
            fontWeight: FontWeight.BOLD,
            textColor: Colors.black87),
        decoration: SystemWindowDecoration(startColor: Colors.grey),
        button: SystemWindowButton(
            text: SystemWindowText(
                text: AppLocalizations.t('Spam'),
                fontSize: 10,
                textColor: Colors.black45),
            tag: "spam_btn"),
        buttonPosition: ButtonPosition.TRAILING);
    // 系统窗口主体
    SystemWindowBody body = SystemWindowBody(
      rows: [
        EachRow(
          columns: [
            EachColumn(
              text: SystemWindowText(
                  text: AppLocalizations.t('Some body'),
                  fontSize: 12,
                  textColor: Colors.black),
            ),
          ],
          gravity: ContentGravity.CENTER,
        ),
        EachRow(columns: [
          EachColumn(
              text: SystemWindowText(
                  text: AppLocalizations.t('Long data of the body'),
                  fontSize: 12,
                  textColor: Colors.black,
                  fontWeight: FontWeight.BOLD),
              padding: SystemWindowPadding.setSymmetricPadding(6, 8),
              decoration: SystemWindowDecoration(
                  startColor: Colors.black, borderRadius: 25.0),
              margin: SystemWindowMargin(top: 4)),
        ], gravity: ContentGravity.CENTER),
        EachRow(
          columns: [
            EachColumn(
              text: SystemWindowText(
                  text: AppLocalizations.t('Description'),
                  fontSize: 10,
                  textColor: Colors.black45),
            ),
          ],
          gravity: ContentGravity.LEFT,
          margin: SystemWindowMargin(top: 8),
        ),
        EachRow(
          columns: [
            EachColumn(
              text: SystemWindowText(
                  text: AppLocalizations.t('Some random description.'),
                  fontSize: 13,
                  textColor: Colors.black54,
                  fontWeight: FontWeight.BOLD),
            ),
          ],
          gravity: ContentGravity.LEFT,
        ),
      ],
      padding: SystemWindowPadding(left: 16, right: 16, bottom: 12, top: 12),
    );
    // 系统窗口底部
    SystemWindowFooter footer = SystemWindowFooter(
        buttons: [
          SystemWindowButton(
            text: SystemWindowText(
                text: AppLocalizations.t('Simple button'),
                fontSize: 12,
                textColor: Colors.blue),
            tag: "simple_button",
            padding:
                SystemWindowPadding(left: 10, right: 10, bottom: 10, top: 10),
            width: 0,
            height: SystemWindowButton.WRAP_CONTENT,
            decoration: SystemWindowDecoration(
                startColor: Colors.white,
                endColor: Colors.white,
                borderWidth: 0,
                borderRadius: 0.0),
          ),
          SystemWindowButton(
            text: SystemWindowText(
                text: AppLocalizations.t('Focus button'),
                fontSize: 12,
                textColor: Colors.white),
            tag: "focus_button",
            width: 0,
            padding:
                SystemWindowPadding(left: 10, right: 10, bottom: 10, top: 10),
            height: SystemWindowButton.WRAP_CONTENT,
            decoration: SystemWindowDecoration(
                startColor: Colors.lightBlueAccent,
                endColor: Colors.blue,
                borderWidth: 0,
                borderRadius: 30.0),
          )
        ],
        padding: SystemWindowPadding(left: 16, right: 16, bottom: 12, top: 10),
        decoration: SystemWindowDecoration(startColor: Colors.white),
        buttonsPosition: ButtonPosition.CENTER);
    // 显示系统窗口
    SystemAlertWindow.showSystemWindow(
        height: 230,
        header: header,
        body: body,
        footer: footer,
        margin: SystemWindowMargin(left: 8, right: 8, top: 200, bottom: 0),
        gravity: SystemWindowGravity.TOP,
        notificationTitle: AppLocalizations.t('Incoming Call'),
        notificationBody: AppLocalizations.t('+1 646 980 4741'),
        prefMode: SystemWindowPrefMode.OVERLAY,
        backgroundColor: Colors.black12,
        isDisableClicks: false);

    if (platformParams.android) {
      SystemAlertWindow.registerOnClickListener(callBack);
    }
  }

  /// 更新系统窗口
  update() {
    SystemWindowHeader header = SystemWindowHeader(
        title: SystemWindowText(
            text: "Outgoing Call", fontSize: 10, textColor: Colors.black45),
        padding: SystemWindowPadding.setSymmetricPadding(12, 12),
        subTitle: SystemWindowText(
            text: "8989898989",
            fontSize: 14,
            fontWeight: FontWeight.BOLD,
            textColor: Colors.black87),
        decoration: SystemWindowDecoration(startColor: Colors.grey[100]),
        button: SystemWindowButton(
            text: SystemWindowText(
                text: "Spam", fontSize: 10, textColor: Colors.black45),
            tag: "spam_btn"),
        buttonPosition: ButtonPosition.TRAILING);
    SystemWindowBody body = SystemWindowBody(
      rows: [
        EachRow(
          columns: [
            EachColumn(
              text: SystemWindowText(
                  text: "Updated body",
                  fontSize: 12,
                  textColor: Colors.black45),
            ),
          ],
          gravity: ContentGravity.CENTER,
        ),
        EachRow(columns: [
          EachColumn(
              text: SystemWindowText(
                  text: "Updated long data of the body",
                  fontSize: 12,
                  textColor: Colors.black87,
                  fontWeight: FontWeight.BOLD),
              padding: SystemWindowPadding.setSymmetricPadding(6, 8),
              decoration: SystemWindowDecoration(
                  startColor: Colors.black12, borderRadius: 25.0),
              margin: SystemWindowMargin(top: 4)),
        ], gravity: ContentGravity.CENTER),
        EachRow(
          columns: [
            EachColumn(
              text: SystemWindowText(
                  text: "Description", fontSize: 10, textColor: Colors.black45),
            ),
          ],
          gravity: ContentGravity.LEFT,
          margin: SystemWindowMargin(top: 8),
        ),
        EachRow(
          columns: [
            EachColumn(
              text: SystemWindowText(
                  text: "Updated random description.",
                  fontSize: 13,
                  textColor: Colors.black54,
                  fontWeight: FontWeight.BOLD),
            ),
          ],
          gravity: ContentGravity.LEFT,
        ),
      ],
      padding: SystemWindowPadding(left: 16, right: 16, bottom: 12, top: 12),
    );
    SystemWindowFooter footer = SystemWindowFooter(
        buttons: [
          SystemWindowButton(
            text: SystemWindowText(
                text: "Updated Simple button",
                fontSize: 12,
                textColor: Colors.blue),
            tag: "updated_simple_button",
            padding:
                SystemWindowPadding(left: 10, right: 10, bottom: 10, top: 10),
            width: 0,
            height: SystemWindowButton.WRAP_CONTENT,
            decoration: SystemWindowDecoration(
                startColor: Colors.white,
                endColor: Colors.white,
                borderWidth: 0,
                borderRadius: 0.0),
          ),
          SystemWindowButton(
            text: SystemWindowText(
                text: "Focus button", fontSize: 12, textColor: Colors.white),
            tag: "focus_button",
            width: 0,
            padding:
                SystemWindowPadding(left: 10, right: 10, bottom: 10, top: 10),
            height: SystemWindowButton.WRAP_CONTENT,
            decoration: SystemWindowDecoration(
                startColor: Colors.blueAccent,
                endColor: Colors.blue,
                borderWidth: 0,
                borderRadius: 30.0),
          )
        ],
        padding: SystemWindowPadding(left: 16, right: 16, bottom: 12, top: 10),
        decoration: SystemWindowDecoration(startColor: Colors.white),
        buttonsPosition: ButtonPosition.CENTER);
    SystemAlertWindow.updateSystemWindow(
        height: 230,
        header: header,
        body: body,
        footer: footer,
        margin: SystemWindowMargin(left: 8, right: 8, top: 200, bottom: 0),
        gravity: SystemWindowGravity.TOP,
        notificationTitle: "Outgoing Call",
        notificationBody: "+1 646 980 4741",
        prefMode: SystemWindowPrefMode.OVERLAY,
        backgroundColor: Colors.transparent,
        isDisableClicks: true);
  }

  close({SystemWindowPrefMode prefMode = SystemWindowPrefMode.OVERLAY}) {
    SystemAlertWindow.closeSystemWindow(prefMode: prefMode);
  }

  remove() {
    SystemAlertWindow.removeOnClickListener();
  }

  static const mainPortName = "foreground_port";

  listen() async {
    ReceivePort port = ReceivePort();
    IsolateNameServer.registerPortWithName(port.sendPort, mainPortName);
    port.listen((dynamic callBackData) {
      String tag = callBackData[0];
    });
  }

  /// 主线程和系统窗口线程之间发送数据
  Future<dynamic> shareData(dynamic data) async {
    SendPort? port = IsolateNameServer.lookupPortByName(mainPortName);
    port?.send(data);
  }
}

AndroidSystemAlertWindow overlayAppWindow = AndroidSystemAlertWindow();

@pragma('vm:entry-point')
void callBack(String tag) {
  WidgetsFlutterBinding.ensureInitialized();
  print(tag);
  switch (tag) {
    case "simple_button":
    case "updated_simple_button":
      SystemAlertWindow.closeSystemWindow(
          prefMode: SystemWindowPrefMode.OVERLAY);
      break;
    case "focus_button":
      print("Focus button has been called");
      break;
    default:
      print("OnClick event of $tag");
  }
}
