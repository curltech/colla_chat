import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

/// flutter_html，显示html字符串
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
    return Html(
      data: widget.html,
    );
  }
}
