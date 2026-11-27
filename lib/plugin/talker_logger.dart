import 'dart:developer';
import 'dart:io';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:talker_flutter/talker_flutter.dart' as talker_logger;
import 'package:talker_flutter/talker_flutter.dart';

class FileTalkerObserver extends TalkerObserver {
  File? file;

  FileTalkerObserver() {
    init();
  }

  Future<void> init() async {
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
  void onException(TalkerException exception) {
    super.onException(exception);
  }

  @override
  void onLog(TalkerData log) {
    super.onLog(log);
    String message = log.generateTextMessage();
    if (file != null) {
      IOSink sink = file!.openWrite(mode: FileMode.append);
      sink.writeln(message);
      sink.close();
    }
  }
}

class TalkerLogger {
  late Talker _talkerLogger;
  Talker? _myLogger;
  final Logger _logger = Logger(
    printer: PrettyPrinter(printTime: true),
    level: Level.info,
  );

  TalkerSettings settings = TalkerSettings(
    /// You can enable/disable all talker processes with this field
    enabled: true,

    /// You can enable/disable saving logs data in history
    useHistory: true,

    /// Length of history that saving logs data
    maxHistoryItems: 100,

    /// You can enable/disable console logs
    useConsoleLogs: false,
  );

  TalkerLogger() {
    _talkerLogger = TalkerFlutter.init(
        settings: settings,
        logger: talker_logger.TalkerLogger(
            output: log, settings: TalkerLoggerSettings()),
        observer: FileTalkerObserver());
  }

  Talker get logger {
    if (_myLogger != null) {
      return _myLogger!;
    }
    if (myself.id != null) {
      _myLogger = TalkerFlutter.init(
          settings: settings,
          logger: talker_logger.TalkerLogger(
              output: log, settings: TalkerLoggerSettings()),
          observer: FileTalkerObserver());
    }
    if (_myLogger != null) {
      return _myLogger!;
    } else {
      return _talkerLogger;
    }
  }

  void t(String msg) {
    _talkerLogger.verbose(msg);
    _logger.t(msg);
  }

  void d(String msg) {
    _talkerLogger.debug(msg);
    _logger.d(msg);
  }

  void i(String msg) {
    _talkerLogger.info(msg);
    _logger.i(msg);
  }

  void w(String msg) {
    _talkerLogger.warning(msg);
    _logger.w(msg);
  }

  void e(String msg) {
    _talkerLogger.error(msg);
    _logger.e(msg);
  }

  void f(String msg) {
    _talkerLogger.critical(msg);
    _logger.f(msg);
  }

  void clearMyLogger() {
    _myLogger = null;
  }
}

final TalkerLogger talkerLogger = TalkerLogger();

final logger = talkerLogger;

class TalkerLoggerScreenWidget extends StatefulWidget {
  const TalkerLoggerScreenWidget({super.key});

  @override
  State<TalkerLoggerScreenWidget> createState() =>
      _TalkerLoggerScreenWidgetState();
}

class _TalkerLoggerScreenWidgetState extends State<TalkerLoggerScreenWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 0.0,
        margin: EdgeInsets.zero,
        shape: const ContinuousRectangleBorder(),
        child: TalkerScreen(
          talker: talkerLogger._talkerLogger,
          appBarTitle: AppLocalizations.t('Logger'),
        ));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
