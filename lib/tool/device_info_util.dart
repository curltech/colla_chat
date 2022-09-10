import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfo {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  Future<AndroidDeviceInfo> getAndroidInfo() async {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo;
  }

  Future<IosDeviceInfo> getIosDeviceInfo() async {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    return iosInfo;
  }

  Future<WebBrowserInfo> getWebBrowserInfo() async {
    WebBrowserInfo webBrowserInfo = await deviceInfo.webBrowserInfo;
    return webBrowserInfo;
  }

  Future<LinuxDeviceInfo> getLinuxDeviceInfo() async {
    LinuxDeviceInfo linuxDeviceInfo = await deviceInfo.linuxInfo;
    return linuxDeviceInfo;
  }

  Future<MacOsDeviceInfo> getMacOsDeviceInfo() async {
    MacOsDeviceInfo macOsDeviceInfo = await deviceInfo.macOsInfo;
    return macOsDeviceInfo;
  }

  Future<WindowsDeviceInfo> getWindowsDeviceInfo() async {
    WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
    return windowsInfo;
  }
}

final deviceInfo = DeviceInfo();
