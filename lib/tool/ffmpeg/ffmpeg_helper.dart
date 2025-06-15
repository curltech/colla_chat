import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/security_storage.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/download_file_util.dart';
import 'package:colla_chat/tool/ffmpeg/base_ffmpeg_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/log.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/session_state.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/statistics.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:process_runner/process_runner.dart';

class FFMpegHelperSession {
  final List<FFmpegSession>? ffmpegSessions;
  Completer? completer;
  Stream<WorkerJob>? unfinishedJobs;
  final List<WorkerJob>? finishedJobs;
  SessionState state = SessionState.running;
  Function(FFMpegHelperSession session)? completeCallback;
  Function(Statistics statistics)? statisticsCallback;

  FFMpegHelperSession({
    this.ffmpegSessions,
    this.completer,
    this.unfinishedJobs,
    this.finishedJobs,
    this.completeCallback,
    this.statisticsCallback,
  }) {
    if (ffmpegSessions != null) {
      completer?.future.then((value) async {
        for (var ffmpegSession in ffmpegSessions!) {
          ReturnCode? rc = await ffmpegSession.getReturnCode();
          if (rc != null && rc.isValueError()) {
            state = SessionState.failed;
          }
        }
        completeCallback?.call(this);
      }).onError((err, trace) {
        state = SessionState.failed;
      });
    }
    if (unfinishedJobs != null) {
      unfinishedJobs = unfinishedJobs!.asBroadcastStream();
      StreamSubscription<WorkerJob> sub =
          unfinishedJobs!.listen((WorkerJob job) {
        int exitCode = job.result.exitCode;
        if (exitCode > 0) {
          state = SessionState.completed;
        } else {
          state = SessionState.failed;
          logger.e(job.result.output);
        }
        completeCallback?.call(this);
      });
    }
    if (finishedJobs != null) {
      state = SessionState.completed;
    }
  }

  cancelSession({String? name}) async {
    if (ffmpegSessions != null) {
      for (var ffmpegSession in ffmpegSessions!) {
        if (name != null) {
          String sessionId = '${ffmpegSession.getSessionId()}';
          if (sessionId == name) {
            ffmpegSession.cancel();
          }
        } else {
          ffmpegSession.cancel();
        }
      }
    }
    if (unfinishedJobs != null) {}
  }

  Future<SessionState> getState() {
    if (ffmpegSessions != null) {
      if (ffmpegSessions!.isNotEmpty) {
        return ffmpegSessions!.first.getState();
      }
    }

    return Future.value(state);
  }

  Future<List<String?>> getOutput() async {
    List<String?> output = [];
    if (ffmpegSessions != null) {
      for (var ffmpegSession in ffmpegSessions!) {
        output.add(await ffmpegSession.getOutput());
      }
    }
    if (finishedJobs != null) {
      for (var finishedJob in finishedJobs!) {
        int exitCode = finishedJob.result.exitCode;
        if (exitCode == 0) {
          output.add(finishedJob.result.output);
          state = SessionState.completed;
        } else {
          output.add(finishedJob.result.stderr);
          state = SessionState.failed;
          String err = finishedJob.result.stderr;
          logger.e('job error:$err');
        }
      }
    }
    if (unfinishedJobs != null) {
      await for (var finishedJob in unfinishedJobs!) {
        int exitCode = finishedJob.result.exitCode;
        if (exitCode == 0) {
          output.add(finishedJob.result.output);
          state = SessionState.completed;
        } else {
          output.add(finishedJob.result.stderr);
          state = SessionState.failed;
          String err = finishedJob.result.stderr;
          logger.e('job error:$err');
        }
      }
    }
    return output;
  }

  Future<List<ReturnCode?>> getReturnCode() async {
    List<ReturnCode?> returnCodes = [];
    if (ffmpegSessions != null) {
      for (var ffmpegSession in ffmpegSessions!) {
        ReturnCode? rc = await ffmpegSession.getReturnCode();
        returnCodes.add(rc);
      }
    }
    if (finishedJobs != null) {
      for (var finishedJob in finishedJobs!) {
        int exitCode = finishedJob.result.exitCode;
        if (exitCode == 0) {
          returnCodes.add(ReturnCode(ReturnCode.success));
          state = SessionState.completed;
        } else {
          returnCodes.add(ReturnCode(ReturnCode.cancel));
          state = SessionState.failed;
          String err = finishedJob.result.stderr;
          logger.e('job error:$err');
        }
      }
    }
    if (unfinishedJobs != null) {
      await for (var finishedJob in unfinishedJobs!) {
        int exitCode = finishedJob.result.exitCode;
        if (exitCode == 0) {
          returnCodes.add(ReturnCode(ReturnCode.success));
          state = SessionState.completed;
        } else {
          returnCodes.add(ReturnCode(ReturnCode.cancel));
          state = SessionState.failed;
          String err = finishedJob.result.stderr;
          logger.e('job error:$err');
        }
      }
    }

    return returnCodes;
  }

  Statistics? _convertStatistics(String output) {
    List<String> data = output.split("\n");
    Map<String, dynamic> temp = {};
    for (String element in data) {
      List<String> kv = element.split("=");
      if (kv.length == 2) {
        temp[kv.first] = kv.last;
      }
    }
    if (temp.isNotEmpty) {
      try {
        return Statistics(
          1,
          int.tryParse(temp['frame'] ?? '0') ?? 0,
          double.tryParse(temp['fps'] ?? '0.0') ?? 0.0,
          double.tryParse(temp['stream_0_0_q'] ?? '0.0') ?? 0.0,
          int.tryParse(temp['total_size'] ?? '0') ?? 0,
          int.tryParse(temp['out_time_us'] ?? '0') ?? 0,
          // 2189.6kbits/s => 2189.6
          double.tryParse((temp['bitrate'] ?? '0.0')
                  ?.replaceAll(RegExp('[a-z/]'), '')) ??
              0.0,
          // 2.15x => 2.15
          double.tryParse(
                  (temp['speed'] ?? '0.0')?.replaceAll(RegExp('[a-z/]'), '')) ??
              0.0,
        );
      } catch (e) {
        logger.e('statisticsCallback failure:$e');
      }
    }
    return null;
  }
}

class FFMpegHelper {
  static ProcessPool processPool = ProcessPool(numWorkers: 10, encoding: utf8);
  static const String _ffmpegUrl =
      "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip";
  static String? _ffmpegBinDirectory;
  static String? _ffmpegInstallationPath;

  static String? get ffmpegInstallationPath {
    return _ffmpegInstallationPath;
  }

  static set ffmpegInstallationPath(String? ffmpegInstallationPath) {
    _ffmpegInstallationPath = ffmpegInstallationPath;
    if (StringUtil.isNotEmpty(ffmpegInstallationPath)) {
      localSecurityStorage.save(
          'ffmpegInstallationPath', ffmpegInstallationPath!);
    } else {
      localSecurityStorage.remove('ffmpegInstallationPath');
    }
  }

  /// 初始化windows的ffmpeg的安装目录
  static Future<bool> initialize() async {
    bool exist = false;
    if (platformParams.windows) {
      String? ffmpegInstallationPath =
          await localSecurityStorage.get('ffmpegInstallationPath');
      if (StringUtil.isEmpty(ffmpegInstallationPath)) {
        Directory appDir = await getApplicationDocumentsDirectory();
        _ffmpegInstallationPath = path.join(appDir.path, "ffmpeg");
        await localSecurityStorage.save(
            'ffmpegInstallationPath', _ffmpegInstallationPath!);
      } else {
        _ffmpegInstallationPath = ffmpegInstallationPath;
      }
      _ffmpegBinDirectory = path.join(
          _ffmpegInstallationPath!, "ffmpeg-master-latest-win64-gpl", "bin");

      File ffmpeg = File(path.join(_ffmpegBinDirectory!, "ffmpeg.exe"));
      File ffprobe = File(path.join(_ffmpegBinDirectory!, "ffprobe.exe"));
      if ((await ffmpeg.exists()) && (await ffprobe.exists())) {
        exist = true;
      }
    } else if (platformParams.linux) {
      try {
        Process process = await Process.start(
          'ffmpeg',
          ['--help'],
        );
        return await process.exitCode == ReturnCode.success;
      } catch (e) {
        exist = false;
      }
    } else {
      exist = true;
    }

    return exist;
  }

  /// 在windows下安装ffmpeg
  static Future<bool> setupFFMpegOnWindows({
    CancelToken? cancelToken,
    void Function(DownloadProgress progress)? onProgress,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (platformParams.windows) {
      bool exist = await initialize();
      if (exist) {
        return true;
      }
      Directory tempDir = await getTemporaryDirectory();
      String tempFolderPath = path.join(tempDir.path, "ffmpeg");
      tempDir = Directory(tempFolderPath);
      if (await tempDir.exists() == false) {
        await tempDir.create(recursive: true);
      }
      Directory installationDir = Directory(_ffmpegInstallationPath!);
      if (await installationDir.exists() == false) {
        await installationDir.create(recursive: true);
      }
      final String ffmpegZipPath = path.join(tempFolderPath, "ffmpeg.zip");
      final File tempZipFile = File(ffmpegZipPath);
      if (await tempZipFile.exists() == false) {
        try {
          Dio dio = Dio();
          Response response = await dio.download(
            _ffmpegUrl,
            ffmpegZipPath,
            cancelToken: cancelToken,
            onReceiveProgress: (int received, int total) {
              onProgress?.call(DownloadProgress(
                downloaded: received,
                fileSize: total,
                phase: DownloadProgressPhase.downloading,
              ));
            },
            queryParameters: queryParameters,
          );
          if (response.statusCode == HttpStatus.ok) {
            onProgress?.call(DownloadProgress(
              downloaded: 0,
              fileSize: 0,
              phase: DownloadProgressPhase.decompressing,
            ));
            await compute(DownloadFileUtil.extractZipFileIsolate, {
              'zipFile': tempZipFile.path,
              'targetPath': _ffmpegInstallationPath,
            });
            onProgress?.call(DownloadProgress(
              downloaded: 0,
              fileSize: 0,
              phase: DownloadProgressPhase.inactive,
            ));
            return true;
          } else {
            onProgress?.call(DownloadProgress(
              downloaded: 0,
              fileSize: 0,
              phase: DownloadProgressPhase.inactive,
            ));
            return false;
          }
        } catch (e) {
          onProgress?.call(DownloadProgress(
            downloaded: 0,
            fileSize: 0,
            phase: DownloadProgressPhase.inactive,
          ));
          return false;
        }
      } else {
        onProgress?.call(DownloadProgress(
          downloaded: 0,
          fileSize: 0,
          phase: DownloadProgressPhase.decompressing,
        ));
        try {
          await compute(DownloadFileUtil.extractZipFileIsolate, {
            'zipFile': tempZipFile.path,
            'targetPath': _ffmpegInstallationPath,
          });
          onProgress?.call(DownloadProgress(
            downloaded: 0,
            fileSize: 0,
            phase: DownloadProgressPhase.inactive,
          ));
          return true;
        } catch (e) {
          onProgress?.call(DownloadProgress(
            downloaded: 0,
            fileSize: 0,
            phase: DownloadProgressPhase.inactive,
          ));
          return false;
        }
      }
    } else {
      onProgress?.call(DownloadProgress(
        downloaded: 0,
        fileSize: 0,
        phase: DownloadProgressPhase.inactive,
      ));
      return true;
    }
  }

  /// 异步运行ffmpeg
  static Future<FFMpegHelperSession> runAsync(
    List<String> commands, {
    void Function(FFMpegHelperSession)? completeCallback,
    void Function(Log)? logCallback,
    dynamic Function(Statistics)? statisticsCallback,
  }) async {
    if (platformParams.windows || platformParams.linux) {
      return await _runAsyncOnWindows(
        commands,
        completeCallback: completeCallback,
        statisticsCallback: statisticsCallback,
      );
    } else {
      return await _runAsyncOnNonWindows(
        commands,
        logCallback: logCallback,
        statisticsCallback: statisticsCallback,
        completeCallback: completeCallback,
      );
    }
  }

  /// 转换媒体文件，包括视频和图片格式的转换，最简单的使用是只有输入和输出文件，自动识别格式
  /// 容器格式：MP4，MKV，WebM，AVI
  /// 视频格式 libx264，libx265，H.262，H.264，H.265，VP8，VP9，AV1，NVENC，libvpx，libaom
  /// 音频格式 MP3，AAC，libfdk-aac
  /// 视频拼接：-i 1.mp4 -i 2.mp4 -i 3.mp4 -filter_complex '[0:0][0:1] [1:0][1:1] [2:0][2:1] concat=n=3:v=1:a=1 [v][a]' -map '[v]' -map '[a]’  output.mp4
  /// [0:0][0:1] [1:0][1:1] [2:0][2:1] 输入文件的视频、音频
  /// 4个视频2x2方式排列 -i 0.mp4 -i 1.mp4 -i 2.mp4 -i 3.mp4 -filter_complex "[0:v]pad=iw*2:ih*2[a];[a][1:v]overlay=w[b];[b][2:v]overlay=0:h[c];[c][3:v]overlay=w:h" out.mp4
  /// 竖向拼接2个视频 -i 0.mp4 -i 1.mp4 -filter_complex "[0:v]pad=iw:ih*2[a];[a][1:v]overlay=0:h" out_2.mp4
  /// 横向拼接3个视频 -i 0.mp4 -i 1.mp4 -i 2.mp4 -filter_complex "[0:v]pad=iw*3:ih*1[a];[a][1:v]overlay=w[b];[b][2:v]overlay=2.0*w" out_v3.mp4
  static String buildCommand({
    String? input, //输入文件，-i
    String? output, //输出文件
    String? inputCv, //输入视频编码器libx264，libx265，H.262，H.264，H.265
    String? inputCa, //输入音频编码器
    String? outputCv,
    String? outputCa,
    String?
        preset, //ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
    String? minrate, //最小码率为964K
    String? maxrate, //最大为3856K
    String? bufsize, //缓冲区大小2000K
    String?
        scale, //改变分辨率，640:-2 640宽，高度-2表示自动计算；iw/2:ih/2缩小一半；iw*0.9:ih*0.9原大小的0.9
    String? ss, //截取图片视频的开始时间
    String? to, //截取视频的结束时间
    String? vframes, //截取图片帧数
    bool? update,
    String? crf, //控制转码，取值范围为 0~51，其中0为无损模式，18~28是一个合理的范围，数值越大，画质越差
    String? qv, //图片质量
    String? aspect, //16:9视频屏宽比
    String? vcodec, //输出的编码h264，mpeg4，copy不重新编码
    String? s, //-s 320x240, 视频分辨率
  } //截取图片质量，1到5x
      ) {
    List<String> args = ['-y'];

    if (ss != null) args.add('-ss $ss');
    if (to != null) args.add('-to $to');
    if (preset != null) args.add('-pre $preset');
    if (minrate != null) args.add('-minrate $minrate');
    if (maxrate != null) args.add('-maxrate $maxrate');
    if (bufsize != null) args.add('-bufsize $bufsize');
    if (inputCa != null) args.add('-c:a $inputCa');
    if (inputCv != null) args.add('-c:v $inputCv');
    if (input != null) {
      if (!input.contains(' ')) {
        args.add('-i $input');
      } else {
        args.add('-i "$input"');
      }
    }
    if (outputCv != null) args.add('-c:v $outputCv');
    if (outputCa != null) args.add('-c:a $outputCa');
    if (vframes != null) args.add('-frames:v $vframes');
    if (update != null) args.add('-update $update');
    if (qv != null) args.add('-q:v $qv');
    if (crf != null) args.add('-crf $crf');
    if (scale != null) args.add('-vf scale=$scale');
    if (aspect != null) args.add('-aspect $aspect');
    if (vcodec != null) args.add('-vcodec $vcodec');
    if (s != null) args.add('-s $s');
    if (output != null) {
      if (!output.contains(' ')) {
        args.add(output);
      } else {
        args.add('"$output"');
      }
    }

    return args.join(' ');
  }

  /// 在windows环境异步运行ffmpeg，完成时回调
  static Future<FFMpegHelperSession> _runAsyncOnWindows(
    List<String> commands, {
    Function(Statistics statistics)? statisticsCallback,
    Function(FFMpegHelperSession)? completeCallback,
  }) async {
    Stream<WorkerJob> unfinishedJobs = await _startWindowsJobAsync(
      commands,
    );
    return FFMpegHelperSession(
      unfinishedJobs: unfinishedJobs,
      completeCallback: completeCallback,
      statisticsCallback: statisticsCallback,
    );
  }

  /// 在非windows环境异步运行ffmpeg，完成时回调
  static Future<FFMpegHelperSession> _runAsyncOnNonWindows(
    List<String> commands, {
    void Function(FFMpegHelperSession)? completeCallback,
    void Function(Log)? logCallback,
    void Function(Statistics)? statisticsCallback,
  }) async {
    List<FFmpegSession> sessions = [];
    Completer completer = Completer();
    for (var command in commands) {
      FFmpegSession session = await BaseFFMpegUtil.executeAsync(
        command,
        completeCallback: (FFmpegSession session) async {
          ReturnCode? rc = await session.getReturnCode();
          FFmpegSession? delete;
          for (var s in sessions) {
            int? sid = s.getSessionId();
            int? sessionId = session.getSessionId();
            if (sid == sessionId) {
              delete = s;
              break;
            }
          }
          if (delete != null) sessions.remove(delete);
          if (sessions.isEmpty) {
            completer.complete();
          }
        },
        logCallback: logCallback,
        statisticsCallback: statisticsCallback,
      );
      sessions.add(session);
    }

    return FFMpegHelperSession(
        ffmpegSessions: [...sessions],
        completer: completer,
        completeCallback: completeCallback,
        statisticsCallback: statisticsCallback);
  }

  /// 同步运行ffmpeg
  static Future<FFMpegHelperSession> runSync(
    List<String> commands, {
    void Function(FFMpegHelperSession)? completeCallback,
    void Function(Log)? logCallback,
    dynamic Function(Statistics)? statisticsCallback,
  }) async {
    if (platformParams.windows || platformParams.linux) {
      return _runSyncOnWindows(
        commands,
        completeCallback: completeCallback,
        statisticsCallback: statisticsCallback,
      );
    } else {
      return _runSyncOnNonWindows(
        commands,
        completeCallback: completeCallback,
        logCallback: logCallback,
        statisticsCallback: statisticsCallback,
      );
    }
  }

  static Future<Stream<WorkerJob>> _startWindowsJobAsync(
      List<String> commands) async {
    String ffmpeg = 'ffmpeg';
    if ((_ffmpegBinDirectory != null) && (platformParams.windows)) {
      ffmpeg = path.join(_ffmpegBinDirectory!, "ffmpeg.exe");
    }
    List<WorkerJob> jobs = [];
    for (var command in commands) {
      List<String> args = command.split(' ');
      WorkerJob job = WorkerJob([ffmpeg, ...args],
          workingDirectory: Directory(_ffmpegBinDirectory!));
      jobs.add(job);
    }
    if (processPool.inProgressJobs > 0) {
      logger
          .e('Have inProgressJobs:${processPool.inProgressJobs}, wait and try');
      throw 'Have inProgressJobs:${processPool.inProgressJobs}, wait and try';
    }
    Stream<WorkerJob> stream = processPool.startWorkers(jobs);

    return stream;
  }

  /// 在windows环境下启动ffmpeg进程
  static Future<List<WorkerJob>> _startWindowsJob(List<String> commands) async {
    String ffmpeg = 'ffmpeg';
    if ((_ffmpegBinDirectory != null) && (platformParams.windows)) {
      ffmpeg = path.join(_ffmpegBinDirectory!, "ffmpeg.exe");
    }
    List<WorkerJob> jobs = [];
    for (var command in commands) {
      WorkerJob job = WorkerJob([ffmpeg, command],
          workingDirectory: Directory(_ffmpegBinDirectory!));
      jobs.add(job);
    }
    List<WorkerJob> finishedJobs = await processPool.runToCompletion(jobs);

    return finishedJobs;
  }

  /// 在windows环境同步运行ffmpeg
  static Future<FFMpegHelperSession> _runSyncOnWindows(
    List<String> commands, {
    Function(FFMpegHelperSession)? completeCallback,
    Function(Statistics statistics)? statisticsCallback,
  }) async {
    List<WorkerJob> finishedJobs = await _startWindowsJob(
      commands,
    );
    return FFMpegHelperSession(
      finishedJobs: finishedJobs,
      completeCallback: completeCallback,
      statisticsCallback: statisticsCallback,
    );
  }

  /// 在非windows环境同步运行ffmpeg
  static Future<FFMpegHelperSession> _runSyncOnNonWindows(
    List<String> commands, {
    void Function(FFMpegHelperSession)? completeCallback,
    void Function(Log)? logCallback,
    Function(Statistics statistics)? statisticsCallback,
  }) async {
    List<FFmpegSession> sessions = [];
    for (var command in commands) {
      FFmpegSession session = await BaseFFMpegUtil.execute(
        command,
        logCallback: logCallback,
        statisticsCallback: statisticsCallback,
      );
      sessions.add(session);
    }
    return FFMpegHelperSession(
      ffmpegSessions: sessions,
      completeCallback: completeCallback,
    );
  }

  /// 运行probe
  static Future<MediaInformation?> getMediaInformationAsync(
      String filePath) async {
    if (platformParams.windows || platformParams.linux) {
      return _getMediaInformationAsyncOnWindows(filePath);
    } else {
      return _getMediaInformationAsyncOnNonWindows(filePath);
    }
  }

  /// 在非windows环境同步运行probe
  static Future<MediaInformation?> _getMediaInformationAsyncOnNonWindows(
      String filename) async {
    return await BaseFFMpegUtil.getMediaInformationAsync(filename);
  }

  /// 在windows环境同步运行probe
  static Future<MediaInformation?> _getMediaInformationAsyncOnWindows(
      String filePath) async {
    String ffprobe = 'ffprobe';
    if (((_ffmpegBinDirectory != null) && (Platform.isWindows))) {
      ffprobe = path.join(_ffmpegBinDirectory!, "ffprobe.exe");
    }
    final result = await Process.run(ffprobe, [
      '-v',
      'quiet',
      '-print_format',
      'json',
      '-show_format',
      '-show_streams',
      '-show_chapters',
      filePath,
    ]);
    if (result.stdout == null ||
        result.stdout is! String ||
        (result.stdout as String).isEmpty) {
      return null;
    }
    if (result.exitCode == ReturnCode.success) {
      try {
        final json = jsonDecode(result.stdout);
        return MediaInformation(json);
      } catch (e) {
        return null;
      }
    } else {
      return null;
    }
  }
}
