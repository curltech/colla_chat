import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/security_storage.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/ffmpeg/base_ffmpeg_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter/log.dart';
import 'package:ffmpeg_kit_flutter/media_information.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/session_state.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';
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
          double.tryParse(temp['out_time_us'] ?? '0') ?? 0,
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

class FFMpegProgress {
  FFMpegProgressPhase phase;
  int fileSize;
  int downloaded;

  FFMpegProgress({
    required this.phase,
    required this.fileSize,
    required this.downloaded,
  });
}

enum FFMpegProgressPhase {
  downloading,
  decompressing,
  inactive,
}

class FFMpegHelper {
  static ProcessPool processPool = ProcessPool(numWorkers: 10, encoding: utf8);
  static const String _ffmpegUrl =
      "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip";
  static String? _tempFolderPath;
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
        Directory ffmpegInstallDir = await getApplicationDocumentsDirectory();
        _ffmpegInstallationPath = path.join(ffmpegInstallDir.path, "ffmpeg");
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
      if (!exist) {
        Directory tempDir = await getTemporaryDirectory();
        _tempFolderPath = path.join(tempDir.path, "ffmpeg");
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

  /// 解压缩安装文件
  static Future<void> extractZipFileIsolate(Map data) async {
    try {
      String? zipFilePath = data['zipFile'];
      String? targetPath = data['targetPath'];
      if ((zipFilePath != null) && (targetPath != null)) {
        await extractFileToDisk(zipFilePath, targetPath);
      }
    } catch (e) {
      return;
    }
  }

  /// 在windows下安装ffmpeg
  static Future<bool> setupFFMpegOnWindows({
    CancelToken? cancelToken,
    void Function(FFMpegProgress progress)? onProgress,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (platformParams.windows) {
      bool exist = await initialize();
      if (exist) {
        return true;
      }
      Directory tempDir = Directory(_tempFolderPath!);
      if (await tempDir.exists() == false) {
        await tempDir.create(recursive: true);
      }
      Directory installationDir = Directory(_ffmpegInstallationPath!);
      if (await installationDir.exists() == false) {
        await installationDir.create(recursive: true);
      }
      final String ffmpegZipPath = path.join(_tempFolderPath!, "ffmpeg.zip");
      final File tempZipFile = File(ffmpegZipPath);
      if (await tempZipFile.exists() == false) {
        try {
          Dio dio = Dio();
          Response response = await dio.download(
            _ffmpegUrl,
            ffmpegZipPath,
            cancelToken: cancelToken,
            onReceiveProgress: (int received, int total) {
              onProgress?.call(FFMpegProgress(
                downloaded: received,
                fileSize: total,
                phase: FFMpegProgressPhase.downloading,
              ));
            },
            queryParameters: queryParameters,
          );
          if (response.statusCode == HttpStatus.ok) {
            onProgress?.call(FFMpegProgress(
              downloaded: 0,
              fileSize: 0,
              phase: FFMpegProgressPhase.decompressing,
            ));
            await compute(extractZipFileIsolate, {
              'zipFile': tempZipFile.path,
              'targetPath': _ffmpegInstallationPath,
            });
            onProgress?.call(FFMpegProgress(
              downloaded: 0,
              fileSize: 0,
              phase: FFMpegProgressPhase.inactive,
            ));
            return true;
          } else {
            onProgress?.call(FFMpegProgress(
              downloaded: 0,
              fileSize: 0,
              phase: FFMpegProgressPhase.inactive,
            ));
            return false;
          }
        } catch (e) {
          onProgress?.call(FFMpegProgress(
            downloaded: 0,
            fileSize: 0,
            phase: FFMpegProgressPhase.inactive,
          ));
          return false;
        }
      } else {
        onProgress?.call(FFMpegProgress(
          downloaded: 0,
          fileSize: 0,
          phase: FFMpegProgressPhase.decompressing,
        ));
        try {
          await compute(extractZipFileIsolate, {
            'zipFile': tempZipFile.path,
            'targetPath': _ffmpegInstallationPath,
          });
          onProgress?.call(FFMpegProgress(
            downloaded: 0,
            fileSize: 0,
            phase: FFMpegProgressPhase.inactive,
          ));
          return true;
        } catch (e) {
          onProgress?.call(FFMpegProgress(
            downloaded: 0,
            fileSize: 0,
            phase: FFMpegProgressPhase.inactive,
          ));
          return false;
        }
      }
    } else {
      onProgress?.call(FFMpegProgress(
        downloaded: 0,
        fileSize: 0,
        phase: FFMpegProgressPhase.inactive,
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
  static String buildCommand({
    String? input,
    String? output,
    String? inputCv,
    String? inputCa,
    String? outputCv,
    String? outputCa,
    String?
        preset, //ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
    String? minrate,
    String? maxrate,
    String? bufsize,
    String? scale,
    String? ss, //截取图片时间
    String? vframes, //截取图片帧数
    bool? update,
    String? qv,
  } //截取图片质量，1到5x
      ) {
    List<String> args = ['-y'];

    if (ss != null) args.add('-ss $ss');
    if (preset != null) args.add('-pre $preset');
    if (scale != null) args.add('-vf scale=$scale:-1');
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
