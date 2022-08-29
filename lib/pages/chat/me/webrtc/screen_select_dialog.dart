import 'dart:async';

import 'package:colla_chat/plugin/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import './condition_import/unsupport.dart'
    if (dart.library.html) './condition_import/web.dart'
    if (dart.library.io) './condition_import/desktop.dart' as displayCapturer;

class ScreenSelectUtil {
  static Future<List<DesktopCapturerSource>> getSources(
      {SourceType sourceType = SourceType.Screen}) async {
    List<DesktopCapturerSource> sources = [];
    try {
      sources = await displayCapturer.getSources(types: [sourceType]);

      return sources;
    } catch (e) {
      logger.i(e.toString());
    }

    return sources;
  }
}

class ScreenSelectDialog extends Dialog {
  ScreenSelectDialog({Key? key}) : super(key: key) {
    Future.delayed(const Duration(milliseconds: 100), () {
      _getSources();
      _timer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
        _getSources();
      });
    });
  }

  List<DesktopCapturerSource> _sources = [];
  SourceType _sourceType = SourceType.Screen;
  DesktopCapturerSource? _selectedSource;
  StateSetter? _stateSetter;
  Timer? _timer;

  void _pop(context) {
    _timer?.cancel();
    Navigator.pop<DesktopCapturerSource>(context, _selectedSource);
  }

  Future<void> _getSources() async {
    try {
      var sources = await ScreenSelectUtil.getSources(sourceType: _sourceType);
      for (var element in sources) {
        logger.i(
            'name: ${element.name}, id: ${element.id}, type: ${element.type}');
      }
      _stateSetter?.call(() {
        _sources = sources;
      });
      return;
    } catch (e) {
      logger.i(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
          child: Container(
        width: 640,
        height: 560,
        color: Colors.white,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10),
              child: Stack(
                children: <Widget>[
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Choose what to share',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      child: const Icon(Icons.close),
                      onTap: () => _pop(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    _stateSetter = setState;
                    return DefaultTabController(
                      length: 2,
                      child: Column(
                        children: <Widget>[
                          Container(
                            constraints:
                                const BoxConstraints.expand(height: 24),
                            child: TabBar(
                                onTap: (value) => Future.delayed(
                                        const Duration(milliseconds: 300), () {
                                      _sourceType = value == 0
                                          ? SourceType.Screen
                                          : SourceType.Window;
                                      _getSources();
                                    }),
                                tabs: const [
                                  Tab(
                                      child: Text(
                                    'Entrire Screen',
                                    style: TextStyle(color: Colors.black54),
                                  )),
                                  Tab(
                                      child: Text(
                                    'Window',
                                    style: TextStyle(color: Colors.black54),
                                  )),
                                ]),
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Expanded(
                            child: TabBarView(children: [
                              Align(
                                  alignment: Alignment.center,
                                  child: GridView.count(
                                    crossAxisSpacing: 8,
                                    crossAxisCount: 2,
                                    children: _sources
                                        .where((element) =>
                                            element.type == SourceType.Screen)
                                        .map((e) => Column(
                                              children: [
                                                Expanded(
                                                    child: Container(
                                                  decoration: (_selectedSource !=
                                                              null &&
                                                          _selectedSource!.id ==
                                                              e.id)
                                                      ? BoxDecoration(
                                                          border: Border.all(
                                                              width: 2,
                                                              color: Colors
                                                                  .blueAccent))
                                                      : null,
                                                  child: InkWell(
                                                    onTap: () {
                                                      logger.i(
                                                          'Selected screen id => ${e.id}');
                                                      setState(() {
                                                        _selectedSource = e;
                                                      });
                                                    },
                                                    child: e.thumbnail != null
                                                        ? Image.memory(
                                                            e.thumbnail!,
                                                            scale: 1.0,
                                                            repeat: ImageRepeat
                                                                .noRepeat,
                                                          )
                                                        : Container(),
                                                  ),
                                                )),
                                                Text(
                                                  e.name,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black87,
                                                      fontWeight:
                                                          (_selectedSource !=
                                                                      null &&
                                                                  _selectedSource!
                                                                          .id ==
                                                                      e.id)
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal),
                                                ),
                                              ],
                                            ))
                                        .toList(),
                                  )),
                              Align(
                                  alignment: Alignment.center,
                                  child: GridView.count(
                                    crossAxisSpacing: 8,
                                    crossAxisCount: 3,
                                    children: _sources
                                        .where((element) =>
                                            element.type == SourceType.Window)
                                        .map((e) => Column(
                                              children: [
                                                Expanded(
                                                    child: Container(
                                                  decoration: (_selectedSource !=
                                                              null &&
                                                          _selectedSource!.id ==
                                                              e.id)
                                                      ? BoxDecoration(
                                                          border: Border.all(
                                                              width: 2,
                                                              color: Colors
                                                                  .blueAccent))
                                                      : null,
                                                  child: InkWell(
                                                    onTap: () {
                                                      logger.i(
                                                          'Selected window id => ${e.id}');
                                                      setState(() {
                                                        _selectedSource = e;
                                                      });
                                                    },
                                                    child: e.thumbnail != null
                                                        ? Image.memory(
                                                            e.thumbnail!,
                                                            scale: 1.0,
                                                            repeat: ImageRepeat
                                                                .noRepeat,
                                                          )
                                                        : Container(),
                                                  ),
                                                )),
                                                Text(
                                                  e.name,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black87,
                                                      fontWeight:
                                                          (_selectedSource !=
                                                                      null &&
                                                                  _selectedSource!
                                                                          .id ==
                                                                      e.id)
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal),
                                                ),
                                              ],
                                            ))
                                        .toList(),
                                  )),
                            ]),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ButtonBar(
                children: <Widget>[
                  MaterialButton(
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black54),
                    ),
                    onPressed: () {
                      _pop(context);
                    },
                  ),
                  MaterialButton(
                    color: Theme.of(context).primaryColor,
                    child: const Text(
                      'Share',
                    ),
                    onPressed: () {
                      _pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }
}
