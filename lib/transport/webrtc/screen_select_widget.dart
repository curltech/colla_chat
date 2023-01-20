import 'dart:async';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../webrtc/condition_import/unsupport.dart'
    if (dart.library.html) './condition_import/web.dart'
    if (dart.library.io) './condition_import/desktop.dart' as display_capture;

///共享屏幕的时候选择共享的应用
class ScreenSelectUtil {
  ///获取可共享的应用源的列表
  static Future<List<DesktopCapturerSource>> getSources(
      {SourceType sourceType = SourceType.Screen}) async {
    List<DesktopCapturerSource> sources = [];
    try {
      sources = await display_capture.getSources(types: [sourceType]);

      return sources;
    } catch (e) {
      logger.i(e.toString());
    }

    return sources;
  }
}

enum DialogStyle { dialog, smart }

///屏幕共享源的选择界面，包裹在showDialog中
class ScreenSelectDialog extends StatelessWidget {
  final DialogStyle dialogStyle;

  ScreenSelectDialog({super.key, this.dialogStyle = DialogStyle.dialog}) {
    Future.delayed(const Duration(milliseconds: 100), () {
      _getSources();
    });
    _subscriptions.add(desktopCapturer.onAdded.stream.listen((source) {
      _sources[source.id] = source;
      _stateSetter?.call(() {});
    }));

    _subscriptions.add(desktopCapturer.onRemoved.stream.listen((source) {
      _sources.remove(source.id);
      _stateSetter?.call(() {});
    }));

    _subscriptions
        .add(desktopCapturer.onThumbnailChanged.stream.listen((source) {
      _stateSetter?.call(() {});
    }));
  }

  final Map<String, DesktopCapturerSource> _sources = {};
  SourceType _sourceType = SourceType.Screen;
  DesktopCapturerSource? _selectedSource;
  final List<StreamSubscription<DesktopCapturerSource>> _subscriptions = [];
  StateSetter? _stateSetter;
  Timer? _timer;

  void _ok(context) async {
    _timer?.cancel();
    for (var element in _subscriptions) {
      element.cancel();
    }
    if (dialogStyle == DialogStyle.dialog) {
      Navigator.pop<DesktopCapturerSource>(context, _selectedSource);
    }
    if (dialogStyle == DialogStyle.smart) {
      SmartDialog.dismiss(result: _selectedSource);
    }
  }

  void _cancel(context) async {
    _timer?.cancel();
    for (var element in _subscriptions) {
      element.cancel();
    }
    if (dialogStyle == DialogStyle.dialog) {
      Navigator.pop<DesktopCapturerSource>(context, null);
    }
    if (dialogStyle == DialogStyle.smart) {
      SmartDialog.dismiss();
    }
  }

  Future<void> _getSources() async {
    try {
      var sources = await desktopCapturer.getSources(types: [_sourceType]);
      for (var element in sources) {
        logger.i(
            'name: ${element.name}, id: ${element.id}, type: ${element.type}');
      }
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        desktopCapturer.updateSources(types: [_sourceType]);
      });
      _sources.clear();
      for (var element in sources) {
        _sources[element.id] = element;
      }
      _stateSetter?.call(() {});
      return;
    } catch (e) {
      logger.i(e.toString());
    }
  }

  Widget _buildTitle(BuildContext context) {
    return AppBarWidget.buildTitleBar(
        title: Text(
          AppLocalizations.t('Choose what to share'),
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        rightWidgets: [
          InkWell(
            child: const Icon(Icons.close, color: Colors.white),
            onTap: () => _cancel(context),
          ),
        ]);
  }

  Widget _buildActionButton(BuildContext context) {
    var primary = myself.primary;
    return SizedBox(
      width: double.infinity,
      child: ButtonBar(
        children: <Widget>[
          MaterialButton(
            child: Text(
              AppLocalizations.t('Cancel'),
              style: const TextStyle(color: Colors.black),
            ),
            onPressed: () {
              _cancel(context);
            },
          ),
          MaterialButton(
            color: primary,
            child: Text(
              AppLocalizations.t('Share'),
            ),
            onPressed: () {
              _ok(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScreenOption(BuildContext context, StateSetter setState) {
    return Align(
        alignment: Alignment.center,
        child: GridView.count(
          crossAxisSpacing: 8,
          crossAxisCount: 2,
          children: _buildSourceWidget(context, SourceType.Screen, setState),
        ));
  }

  List<Widget> _buildSourceWidget(
      BuildContext context, SourceType sourceType, StateSetter setState) {
    List<Widget> sourceWidgets = [];
    for (var entry in _sources.entries) {
      var source = entry.value;
      if (source.type == sourceType) {
        Widget sourceWidget = ThumbnailWidget(
          onTap: (source) {
            setState(() {
              _selectedSource = source;
            });
          },
          source: source,
          selected: _selectedSource?.id == source.id,
        );
        sourceWidgets.add(sourceWidget);
      }
    }

    return sourceWidgets;
  }

  Widget _buildWindowsOption(BuildContext context, StateSetter setState) {
    return Align(
        alignment: Alignment.center,
        child: GridView.count(
          crossAxisSpacing: 8,
          crossAxisCount: 3,
          children: _buildSourceWidget(context, SourceType.Window, setState),
        ));
  }

  Widget _buildTabBar(BuildContext context) {
    var primary = myself.primary;
    return TabBar(
        indicatorColor: primary,
        onTap: (value) => Future.delayed(const Duration(milliseconds: 300), () {
              _sourceType = value == 0 ? SourceType.Screen : SourceType.Window;
              _getSources();
            }),
        tabs: [
          Tab(
              child: Text(
            AppLocalizations.t('Entire Screen'),
            style: const TextStyle(color: Colors.black),
          )),
          Tab(
              child: Text(
            AppLocalizations.t('Window'),
            style: const TextStyle(color: Colors.black),
          )),
        ]);
  }

  Widget _buildTabController(BuildContext context, StateSetter setState) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          Container(
            constraints: const BoxConstraints.expand(height: 24),
            child: _buildTabBar(context),
          ),
          const SizedBox(
            height: 2,
          ),
          Expanded(
            child: TabBarView(children: [
              _buildScreenOption(context, setState),
              _buildWindowsOption(context, setState),
            ]),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return Material(
      type: MaterialType.transparency,
      child: Center(
          child: Container(
        width: width,
        height: height,
        color: Colors.white,
        child: Column(
          children: <Widget>[
            _buildTitle(context),
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    _stateSetter = setState;
                    return _buildTabController(context, setState);
                  },
                ),
              ),
            ),
            _buildActionButton(context),
          ],
        ),
      )),
    );
  }
}

class ThumbnailWidget extends StatefulWidget {
  const ThumbnailWidget(
      {Key? key,
      required this.source,
      required this.selected,
      required this.onTap})
      : super(key: key);
  final DesktopCapturerSource source;
  final bool selected;
  final Function(DesktopCapturerSource) onTap;

  @override
  State createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<ThumbnailWidget> {
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _subscriptions.add(widget.source.onThumbnailChanged.stream.listen((event) {
      setState(() {});
    }));
    _subscriptions.add(widget.source.onNameChanged.stream.listen((event) {
      setState(() {});
    }));
  }

  @override
  void deactivate() {
    for (var element in _subscriptions) {
      element.cancel();
    }
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    var primary = myself.primary;
    return Column(
      children: [
        Expanded(
            child: Container(
          decoration: widget.selected
              ? BoxDecoration(border: Border.all(width: 2, color: primary))
              : null,
          child: InkWell(
            onTap: () {
              logger.i('Selected source id => ${widget.source.id}');
              widget.onTap(widget.source);
            },
            child: widget.source.thumbnail != null
                ? Image.memory(
                    widget.source.thumbnail!,
                    gaplessPlayback: true,
                    alignment: Alignment.center,
                  )
                : Container(),
          ),
        )),
        Text(
          widget.source.name,
          style: TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight:
                  widget.selected ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }
}
