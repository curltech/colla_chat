import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_session.dart';
import 'package:ffmpeg_kit_flutter/log.dart';
import 'package:ffmpeg_kit_flutter/media_information.dart';
import 'package:ffmpeg_kit_flutter/media_information_session.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';

class FfmpegUtil {
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

  static Future<FFmpegSession> execute(String command,
      {void Function(FFmpegSession session)? sessionComplete,
      void Function(Log log)? logCallback,
      void Function(Statistics stat)? statisticsCallback}) async {
    FFmpegSession session = await FFmpegKit.execute(command);
    if (sessionComplete != null) {
      FFmpegKitConfig.enableFFmpegSessionCompleteCallback(sessionComplete);
    }
    if (logCallback != null) {
      FFmpegKitConfig.enableLogCallback(logCallback);
    }
    if (statisticsCallback != null) {
      FFmpegKitConfig.enableStatisticsCallback(statisticsCallback);
    }
    final ReturnCode? returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
    } else if (ReturnCode.isCancel(returnCode)) {
    } else {}

    // Unique session id created for this execution
    final sessionId = session.getSessionId();

    // Command arguments as a single string
    //final command = session.getCommand();

    // Command arguments
    final commandArguments = session.getArguments();

    // State of the execution. Shows whether it is still running or completed
    final state = await session.getState();

    final startTime = session.getStartTime();
    final endTime = await session.getEndTime();
    final duration = await session.getDuration();

    // Console output generated for this execution
    final output = await session.getOutput();

    // The stack trace if FFmpegKit fails to run a command
    final failStackTrace = await session.getFailStackTrace();

    // The list of logs generated for this execution
    final logs = await session.getLogs();

    // The list of statistics generated for this execution (only available on FFmpegSession)
    final statistics = await session.getStatistics();

    return session;
  }

  /// 转换媒体文件，包括视频和图片格式的转换，最简单的使用是只有输入和输出文件，自动识别格式
  /// 容器格式：MP4，MKV，WebM，AVI
  /// 视频格式 libx264，libx265，H.262，H.264，H.265，VP8，VP9，AV1，NVENC，libvpx，libaom
  /// 音频格式 MP3，AAC，libfdk-aac
  static Future<FFmpegSession> convert(
      {String? input,
      String? output,
      String? inputCv,
      String? inputCa,
      String? outputCv,
      String? outputCa,
      String? preset =
          'faster', //ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
      String? minrate,
      String? maxrate,
      String? bufsize,
      String? scale,
      String? ss, //截取图片时间
      String? vframes, //截取图片帧数
      String? qv, //截取图片质量，1到5
      void Function(FFmpegSession session)? sessionComplete,
      void Function(Log log)? logCallback,
      void Function(Statistics stat)? statisticsCallback}) {
    String command = '-y';

    command += ss ?? ' -ss $ss';
    command += preset ?? ' -preset $preset';
    command += vframes ?? ' -vframes $vframes';
    command += qv ?? ' -q:v $qv';
    command += scale ?? ' -vf scale=$scale:-1';
    command += minrate ?? ' -minrate $minrate';
    command += maxrate ?? ' -maxrate $maxrate';
    command += bufsize ?? ' -bufsize $bufsize';
    command += inputCa ?? ' -c:a $inputCa';
    command += inputCv ?? ' -c:v $inputCv';
    command += input ?? ' -i $input';
    command += outputCv ?? ' -c:v $outputCv';
    command += outputCa ?? ' -c:a $outputCa';
    command += output ?? ' $output';

    return execute(command,
        sessionComplete: sessionComplete,
        logCallback: logCallback,
        statisticsCallback: statisticsCallback);
  }

  static Future<ReturnCode?> probe(String command,
      {void Function(FFprobeSession)? ffprobeSessionCompleteCallback}) async {
    FFprobeSession session = await FFprobeKit.execute(command);
    if (ffprobeSessionCompleteCallback != null) {
      FFmpegKitConfig.enableFFprobeSessionCompleteCallback(
          ffprobeSessionCompleteCallback);
    }
    ReturnCode? returnCode = await session.getReturnCode();

    return returnCode;
  }

  static Future<MediaInformation?> getMediaInformation(String filename,
      {void Function(MediaInformationSession)?
          mediaInformationSessionCompleteCallback}) async {
    MediaInformationSession session =
        await FFprobeKit.getMediaInformation(filename);

    if (mediaInformationSessionCompleteCallback != null) {
      FFmpegKitConfig.enableMediaInformationSessionCompleteCallback(
          mediaInformationSessionCompleteCallback);
    }
    final MediaInformation? information = session.getMediaInformation();

    if (information == null) {
      final state =
          FFmpegKitConfig.sessionStateToString(await session.getState());
      final returnCode = await session.getReturnCode();
      final failStackTrace = await session.getFailStackTrace();
      final duration = await session.getDuration();
      final output = await session.getOutput();
    }

    return information;
  }

  static cancel([int? sessionId]) {
    FFmpegKit.cancel(sessionId);
  }
}
