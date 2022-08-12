import 'package:classic_logger/classic_logger.dart' as classic_logger;
import 'package:logger/logger.dart';

class CustomLogger {
  late Logger logger;

  CustomLogger() {
    logger = Logger(
      printer: PrettyPrinter(printTime: true),
      level: Level.info,
    );
    Logger.level = Level.warning;
  }
}

class FileOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    event.lines.forEach(print);
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

final logger = customLogger.logger;
