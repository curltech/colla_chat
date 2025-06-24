import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/media_editor/ffmpeg/ffmpeg_helper.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/abstract_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/log.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information_session.dart';

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
    int quality = 1,
    int position = 30,
  }) async {
    Completer<Uint8List?> data = Completer<Uint8List?>();
    String filename = await FileUtil.getTempFilename(extension: 'jpg');
    String command = FFMpegHelper.buildCommand(
      input: videoFile,
      output: filename,
      ss: '00:00:30',
      vframes: '1',
      qv: '$quality',
    );
    await FFMpegHelper.runAsync([command],
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
