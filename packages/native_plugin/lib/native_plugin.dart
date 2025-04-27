
import 'native_plugin_platform_interface.dart';

class NativePlugin {
  Future<String?> getPlatformVersion() {
    return NativePluginPlatform.instance.getPlatformVersion();
  }

  Future<int> createPipContentView() {
    return NativePluginPlatform.instance.createPipContentView();
  }

  Future<void> disposePipContentView(int viewId) {
    return NativePluginPlatform.instance.disposePipContentView(viewId);
  }
}
