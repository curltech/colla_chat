import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/webview/platform_webview.dart';
import 'package:flutter/material.dart';

class HtmlPreviewController with ChangeNotifier {
  String? _title;
  String? _initialUrl;
  String? _html;
  String? _initialFilename;

  String? get title {
    return _title;
  }

  String? get initialUrl {
    return _initialUrl;
  }

  String? get html {
    return _html;
  }

  String? get initialFilename {
    return _initialFilename;
  }

  set title(String? title) {
    if (_title != title) {
      _title = title;
    }
  }

  set initialUrl(String? initialUrl) {
    if (_initialUrl != initialUrl) {
      _initialUrl = initialUrl;
      notifyListeners();
    }
  }

  set html(String? html) {
    if (_html != html) {
      _html = html;
      notifyListeners();
    }
  }

  set initialFilename(String? initialFilename) {
    if (_initialFilename != initialFilename) {
      _initialFilename = initialFilename;
      notifyListeners();
    }
  }
}

final HtmlPreviewController htmlPreviewController = HtmlPreviewController();

class HtmlPreviewWidget extends StatefulWidget with TileDataMixin {
  const HtmlPreviewWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'html_preview';

  @override
  IconData get iconData => Icons.preview;

  @override
  String get title => '';

  @override
  State<StatefulWidget> createState() => _HtmlPreviewWidgetState();
}

class _HtmlPreviewWidgetState extends State<HtmlPreviewWidget> {
  @override
  void initState() {
    htmlPreviewController.addListener(_update);
    super.initState();
  }

  void _update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: htmlPreviewController.title,
        withLeading: widget.withLeading,
        child: PlatformWebView(
            webViewController: PlatformWebViewController(),
            initialUrl: htmlPreviewController.initialUrl,
            html: htmlPreviewController.html,
            initialFilename: htmlPreviewController.initialFilename));

    return appBarView;
  }

  @override
  void dispose() {
    htmlPreviewController.removeListener(_update);
    super.dispose();
  }
}
