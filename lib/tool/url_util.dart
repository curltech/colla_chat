import 'package:url_launcher/url_launcher.dart';

class UrlUtil {
  ///处理file,http,mailto,tel,sms
  ///适用于各种平台
  Future<bool> launch(
    String url, {
    LaunchMode mode = LaunchMode.inAppWebView,
    WebViewConfiguration webViewConfiguration = const WebViewConfiguration(),
    String? webOnlyWindowName,
  }) async {
    final Uri uri = Uri.parse(url);
    bool success = await launchUrl(uri,
        mode: mode,
        webViewConfiguration: webViewConfiguration,
        webOnlyWindowName: webOnlyWindowName);

    return success;
  }
}
