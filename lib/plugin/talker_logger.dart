import 'dart:developer';
import 'dart:io';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart' as talker_logger;

class FileTalkerObserver extends TalkerObserver {
  File? file;

  FileTalkerObserver() {
    init();
  }

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
  late Talker _logger;
  Talker? _myLogger;
  TalkerSettings settings = TalkerSettings(
    /// You can enable/disable all talker processes with this field
    enabled: true,

    /// You can enable/disable saving logs data in history
    useHistory: true,

    /// Length of history that saving logs data
    maxHistoryItems: 100,

    /// You can enable/disable console logs
    useConsoleLogs: true,
  );

  TalkerLogger() {
    _logger = TalkerFlutter.init(
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
          logger: talker_logger.TalkerLogger(
              output: log, settings: TalkerLoggerSettings()),
          observer: FileTalkerObserver());
    }
    if (_myLogger != null) {
      return _myLogger!;
    } else {
      return _logger;
    }
  }

  t(String msg) {
    logger.verbose(msg);
  }

  d(String msg) {
    logger.debug(msg);
  }

  i(String msg) {
    logger.info(msg);
  }

  w(String msg) {
    logger.warning(msg);
  }

  e(String msg) {
    logger.error(msg);
  }

  f(String msg) {
    logger.critical(msg);
  }

  clearMyLogger() {
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
            talker: talkerLogger.logger,
            appBarTitle: AppLocalizations.t('Logger'),
            theme: const TalkerScreenTheme(
              logColors: {
                TalkerLogType.warning: Colors.amber,
                TalkerLogType.error: Colors.red,
                TalkerLogType.info: Colors.green,
              },
            )));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
