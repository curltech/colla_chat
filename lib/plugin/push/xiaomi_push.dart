import 'package:xiao_mi_push_plugin/xiao_mi_push_plugin.dart';
import 'package:xiao_mi_push_plugin/xiao_mi_push_plugin_listener.dart';

class XiaomiPush {
  init() => XiaoMiPushPlugin.init(
      appId: "2882303761518406102", appKey: "5981840633102");

  setAlias() => XiaoMiPushPlugin.setAlias(alias: "test", category: "test");

  unsetAlias() => XiaoMiPushPlugin.unsetAlias(alias: "test", category: "test");

  getAllAlias() async => await XiaoMiPushPlugin.getAllAlias();

  setUserAccount() =>
      XiaoMiPushPlugin.setUserAccount(userAccount: "test", category: "test");

  unsetUserAccount() =>
      XiaoMiPushPlugin.unsetUserAccount(userAccount: "test", category: "test");

  getAllUserAccount() async => await XiaoMiPushPlugin.getAllUserAccount();

  subscribe() => XiaoMiPushPlugin.subscribe(topic: "test", category: "test");

  unsubscribe() =>
      XiaoMiPushPlugin.unsubscribe(topic: "test", category: "test");

  getAllTopic() async => await XiaoMiPushPlugin.getAllTopic();

  getRegId() async => await XiaoMiPushPlugin.getRegId();

  addListener() {
    XiaoMiPushPlugin.addListener(onXiaoMiPushListener);
  }

  removeListener() {
    XiaoMiPushPlugin.removeListener(onXiaoMiPushListener);
  }

  /// NotificationMessageClicked	接收服务器推送的通知消息，用户点击后触发	MiPushMessageEntity
  /// RequirePermissions	当所需要的权限未获取到的时候会回调该接口	List
  /// ReceivePassThroughMessage	接收服务器推送的透传消息	MiPushMessageEntity
  /// CommandResult	获取给服务器发送命令的结果	MiPushCommandMessageEntity
  /// ReceiveRegisterResult	获取给服务器发送注册命令的结果	MiPushCommandMessageEntity
  /// NotificationMessageArrived	接收服务器推送的通知消息，消息到达客户端时触发，还可以接受应用在前台时不弹出通知的通知消息(在MIUI上，只有应用处于启动状态，或者自启动白名单中，才可以通过此方法接受到该消息)	MiPushMessageEntity
  onXiaoMiPushListener(XiaoMiPushListenerTypeEnum type, dynamic params) {}
}
