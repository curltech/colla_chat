import 'dart:async';

import 'package:ffmpeg_kit_flutter_minimal/abstract_session.dart';
import 'package:ffmpeg_kit_flutter_minimal/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_minimal/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_minimal/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_minimal/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_minimal/ffprobe_session.dart';
import 'package:ffmpeg_kit_flutter_minimal/log.dart';
import 'package:ffmpeg_kit_flutter_minimal/media_information.dart';
import 'package:ffmpeg_kit_flutter_minimal/media_information_session.dart';
import 'package:ffmpeg_kit_flutter_minimal/statistics.dart';

/// 非windows环境下执行ffmpeg和probe
class BaseFFMpegUtil {
  static Future<String?> formats() async {
    final FFmpegSession session = await execute('configure -formats');
    final String? output = await session.getOutput();

    return output;
  }

  static Future<String?> encoders() async {
    final FFmpegSession session = await execute('configure -encoders');
    final String? output = await session.getOutput();

    return output;
  }

  static Future<String?> decoders() async {
    final FFmpegSession session = await execute('configure -decoders');
    final String? output = await session.getOutput();

    return output;
  }

  static Future<String?> help() async {
    final FFmpegSession session = await execute('configure --help');
    final String? output = await session.getOutput();

    return output;
  }

  /// 同步执行ffmpeg命令，可设置全局回调，返回会话，适用于简单命令
  static Future<FFmpegSession> execute(String command,
      {void Function(FFmpegSession session)? completeCallback,
      void Function(Log log)? logCallback,
      void Function(Statistics stat)? statisticsCallback}) async {
    FFmpegSession session = await FFmpegKit.execute(command);
    if (completeCallback != null) {
      FFmpegKitConfig.enableFFmpegSessionCompleteCallback(completeCallback);
    }
    if (logCallback != null) {
      FFmpegKitConfig.enableLogCallback(logCallback);
    }
    if (statisticsCallback != null) {
      FFmpegKitConfig.enableStatisticsCallback(statisticsCallback);
    }

    return session;
  }

  /// 异步执行ffmpeg命令，可设置回调，返回会话，适用于耗时较长的命令
  static Future<FFmpegSession> executeAsync(String command,
      {void Function(FFmpegSession session)? completeCallback,
      void Function(Log log)? logCallback,
      void Function(Statistics stat)? statisticsCallback}) async {
    FFmpegSession session = await FFmpegKit.executeAsync(
        command, completeCallback, logCallback, statisticsCallback);

    return session;
  }

  static Future<FFprobeSession?> probe(String command,
      {void Function(FFprobeSession)? completeCallback,
      void Function(Log)? logCallback,
      void Function(Statistics)? statisticsCallback}) async {
    FFprobeSession session = await FFprobeKit.execute(command);
    if (completeCallback != null) {
      FFmpegKitConfig.enableFFprobeSessionCompleteCallback(completeCallback);
    }
    if (logCallback != null) {
      FFmpegKitConfig.enableLogCallback(logCallback);
    }
    if (statisticsCallback != null) {
      FFmpegKitConfig.enableStatisticsCallback(statisticsCallback);
    }

    return session;
  }

  static Future<FFprobeSession?> probeAsync(String command,
      {void Function(FFprobeSession)? completeCallback,
      void Function(Log)? logCallback}) async {
    FFprobeSession session =
        await FFprobeKit.executeAsync(command, completeCallback, logCallback);

    return session;
  }

  static Future<MediaInformation?> getMediaInformationAsync(String filename,
      {void Function(MediaInformationSession)? completeCallback,
      void Function(Log)? logCallback}) async {
    Completer<MediaInformation?> completer = Completer<MediaInformation?>();
    try {
      await FFprobeKit.getMediaInformationAsync(filename,
          (MediaInformationSession session) async {
        final MediaInformation? information = session.getMediaInformation();
        if (information != null) {
          if (!completer.isCompleted) {
            completer.complete(information);
          }
        } else {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        }
      });
    } catch (e) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
    return completer.future;
  }

  static cancel([int? sessionId]) {
    FFmpegKit.cancel(sessionId);
  }

  static Future<Map<String, List<AbstractSession>>> listSessions() async {
    Map<String, List<AbstractSession>> sessionMap = {};
    List<AbstractSession> sessions = await FFmpegKit.listSessions();
    sessionMap['ffmpeg'] = sessions;
    sessions = await FFprobeKit.listFFprobeSessions();
    sessionMap['probe'] = sessions;
    sessions = await FFprobeKit.listMediaInformationSessions();
    sessionMap['information'] = sessions;

    return sessionMap;
  }
}
