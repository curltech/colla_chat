import 'package:logger/logger.dart';

class CustomLogger {
  late Logger logger;

  CustomLogger() {
    logger = Logger(
      printer: PrettyPrinter(),
      level: Level.info,
    );
    Logger.level = Level.warning;
  }
}

final customLogger = CustomLogger();
final logger = customLogger.logger;

//var log = easylogger.Logger;
