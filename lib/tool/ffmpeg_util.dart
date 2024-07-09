import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/tool/ffmpeg/ffmpeg_helper.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:ffmpeg_kit_flutter/abstract_session.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter/log.dart';
import 'package:ffmpeg_kit_flutter/media_information.dart';
import 'package:ffmpeg_kit_flutter/media_information_session.dart';

class FFMpegUtil {
  static Future<String?> formats() async {
    final FFMpegHelperSession session =
        await FFMpegHelper.runSync(['-formats']);
    final List<String?> output = await session.getOutput();

    return output.firstOrNull;
  }

  static Future<String?> encoders() async {
    final FFMpegHelperSession session =
        await FFMpegHelper.runSync(['-encoders']);
    final List<String?> output = await session.getOutput();

    return output.firstOrNull;
  }

  static Future<String?> decoders() async {
    final FFMpegHelperSession session =
        await FFMpegHelper.runSync(['-decoders']);
    final List<String?> output = await session.getOutput();

    return output.firstOrNull;
  }

  static Future<String?> help() async {
    final FFMpegHelperSession session = await FFMpegHelper.runSync(['-help']);
    final List<String?> output = await session.getOutput();

    return output.firstOrNull;
  }

  static Future<Uint8List?> thumbnail({
    String? videoFile,
    int quality = 10,
    int position = 30,
  }) async {
    Completer<Uint8List?> data = Completer<Uint8List?>();
    String filename = await FileUtil.getTempFilename(extension: 'jpg');
    await FFMpegHelper.convertAsync(
        input: videoFile,
        output: filename,
        ss: '00:00:30',
        vframes: '1',
        qv: '$quality',
        completeCallback: (FFMpegHelperSession session) {
          File file = File(filename);
          if (file.existsSync()) {
            Uint8List d = file.readAsBytesSync();
            file.delete();
            data.complete(d);
          } else {
            data.complete();
          }
        });
    return data.future;
  }

  static Future<MediaInformation?> getMediaInformation(String filename,
      {void Function(MediaInformationSession)? completeCallback,
      void Function(Log)? logCallback}) async {
    MediaInformation? mediaInformation =
        await FFMpegHelper.getMediaInformationAsync(filename);

    return mediaInformation;
  }

  static cancel({FFMpegHelperSession? session}) {
    session?.cancelSession();
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
