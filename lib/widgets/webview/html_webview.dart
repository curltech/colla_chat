import 'package:colla_chat/tool/loading_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

/// flutter_widget_from_html，简单地渲染html，不用浏览器实现
class HtmlWebView extends StatefulWidget {
  final String html;

  const HtmlWebView({
    super.key,
    required this.html,
  });

  @override
  State createState() => _HtmlWebViewState();
}

class _HtmlWebViewState extends State<HtmlWebView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(context) {
    HtmlWidget htmlWidget = HtmlWidget(
      widget.html,
      onErrorBuilder: (context, element, error) {
        return Text(
          '$element error: $error',
          style: const TextStyle(color: Colors.white),
        );
      },
      onLoadingBuilder: (context, element, loadingProgress) {
        return LoadingUtil.buildCircularLoadingWidget();
      },
      renderMode: RenderMode.listView,
    );

    return htmlWidget;
  }
}
