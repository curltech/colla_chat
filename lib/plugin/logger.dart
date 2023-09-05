import 'dart:io';

import 'package:classic_logger/classic_logger.dart' as classic_logger;
import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:synchronized/extension.dart';

class CustomLogger {
  late Logger _logger;
  Logger? _myLogger;

  CustomLogger() {
    _logger = Logger(
      printer: PrettyPrinter(printTime: true),
      output: FileOutput(),
      level: Level.warning,
    );
    Logger.level = Level.warning;
  }

  Logger get logger {
    if (_myLogger != null) {
      return _myLogger!;
    }
    if (myself.id != null) {
      _myLogger = Logger(
        printer: PrettyPrinter(printTime: true),
        output: FileOutput(),
        level: Level.info,
      );
    }
    if (_myLogger != null) {
      return _myLogger!;
    } else {
      return _logger;
    }
  }

  Logger? get myLogger {
    return _myLogger;
  }

  clearMyLogger() {
    _myLogger = null;
  }

  t(dynamic msg) {
    logger.v(msg);
  }

  d(dynamic msg) {
    logger.d(msg);
  }

  i(dynamic msg) {
    logger.i(msg);
  }

  w(dynamic msg) {
    logger.w(msg);
  }

  e(dynamic msg) {
    logger.e(msg);
  }

  f(dynamic msg) {
    logger.wtf(msg);
  }
}

class FileOutput extends LogOutput {
  File? file;

  FileOutput() {
    init();
  }

  @override
  init() async {
    var current = DateTime.now();
    var filename =
        'colla_chat-${current.year}-${current.month}-${current.day}.log';
    filename = p.join(myself.myPath, filename);
    file = File(filename);
    bool exist = await file!.exists();
    if (!exist) {
      try {
        file = await file!.create(recursive: true);
      } catch (e) {
        print('create file:$filename failure, $e');
      }
    }
  }

  @override
  void output(OutputEvent event) {
    loggerController.append(event.lines);
    if (file != null) {
      event.lines.forEach(print);
      IOSink sink = file!.openWrite(mode: FileMode.append);
      sink.writeln(event.lines);
      sink.close();
    }
  }
}

final customLogger = CustomLogger();

//var log = easylogger.Logger;

class ClassicLogger {
  late classic_logger.Logger logger;

  ClassicLogger(String filename) {
    logger = classic_logger.Logger.fromConfig(classic_logger.LogConfig(
      baseLevel: classic_logger.LogLevel.info,
      output: classic_logger.MultiOutput([
        classic_logger.ConsoleOutput(),
        classic_logger.FileOutput(filename),
      ]),
    ));
  }

  t(String msg) {
    logger.trace(msg);
  }

  d(String msg) {
    logger.debug(msg);
  }

  i(String msg) {
    logger.info(msg);
  }

  w(String msg) {
    logger.warn(msg);
  }

  e(String msg) {
    logger.error(msg);
  }

  f(String msg) {
    logger.fatal(msg);
  }
}

final logger = customLogger;

class LoggerController with ChangeNotifier {
  int total = 100;
  final List<String> _logs = [];

  append(List<String> logs) async {
    if (_logs.length >= 100) {
      await synchronized(() async {
        try {
          _logs.removeRange(0, logs.length);
        } catch (e) {}
      });
    }
    await synchronized(() async {
      return _logs.addAll(logs);
    });

    notifyListeners();
  }

  List<String> get logs {
    return _logs;
  }
}

final LoggerController loggerController = LoggerController();

class LoggerConsoleWidget extends StatefulWidget {
  const LoggerConsoleWidget({Key? key}) : super(key: key);

  @override
  State<LoggerConsoleWidget> createState() => _LoggerConsoleWidgetState();
}

class _LoggerConsoleWidgetState extends State<LoggerConsoleWidget> {
  @override
  void initState() {
    super.initState();
    loggerController.addListener(_update);
  }

  _update() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onDoubleTap: () {
          setState(() {
            loggerController.logs.clear();
          });
        },
        child: Card(
            elevation: 0.0,
            margin: EdgeInsets.zero,
            shape: const ContinuousRectangleBorder(),
            child: ListView.builder(
              reverse: true,
              shrinkWrap: true,
              itemCount: loggerController.logs.length,
              itemBuilder: (context, index) {
                final log = loggerController.logs.elementAt(index);
                return Text(log);
              },
            )));
  }

  @override
  void dispose() {
    loggerController.removeListener(_update);
    super.dispose();
  }
}
