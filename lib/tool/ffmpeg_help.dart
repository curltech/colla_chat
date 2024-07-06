import 'dart:io';

// import 'package:colla_chat/platform.dart';
// import 'package:colla_chat/tool/dialog_util.dart';
// import 'package:dio/dio.dart';
// import 'package:ffmpeg_helper/ffmpeg/args/log_level_arg.dart';
// import 'package:ffmpeg_helper/ffmpeg/args/overwrite_arg.dart';
// import 'package:ffmpeg_helper/ffmpeg/args/trim_arg.dart';
// import 'package:ffmpeg_helper/ffmpeg/ffmpeg_command.dart';
// import 'package:ffmpeg_helper/ffmpeg/ffmpeg_filter_chain.dart';
// import 'package:ffmpeg_helper/ffmpeg/ffmpeg_filter_graph.dart';
// import 'package:ffmpeg_helper/ffmpeg/ffmpeg_input.dart';
// import 'package:ffmpeg_helper/ffmpeg/filters/scale_filter.dart';
// import 'package:ffmpeg_helper/ffmpeg_helper.dart';
// import 'package:ffmpeg_helper/helpers/ffmpeg_helper_class.dart';
// import 'package:ffmpeg_helper/helpers/helper_progress.dart';
// import 'package:ffmpeg_helper/helpers/helper_sessions.dart';
// import 'package:flutter/material.dart';

class FfmpegHelpUtil {
  // static FFMpegHelper? ffmpeg;
  //
  // static initialize() async {
  //   await FFMpegHelper.instance.initialize();
  //   ffmpeg = FFMpegHelper.instance;
  // }
  //
  // Future<void> install(
  //   BuildContext context, {
  //   CancelToken? cancelToken,
  //   void Function(FFMpegProgress)? onProgress,
  //   Map<String, dynamic>? queryParameters,
  // }) async {
  //   if (platformParams.windows) {
  //     await ffmpeg!.setupFFMpegOnWindows(
  //       cancelToken: cancelToken,
  //       onProgress: onProgress,
  //       queryParameters: queryParameters,
  //     );
  //   } else if (platformParams.linux) {
  //     await DialogUtil.confirm(context,
  //         title: 'Install FFMpeg',
  //         content:
  //             'FFmpeg installation required by user.\nsudo apt-get install ffmpeg\nsudo snap install ffmpeg');
  //   }
  // }
  //
  // static run({
  //   String? input,
  //   String? output,
  //   dynamic Function(Statistics)? statisticsCallback,
  //   Function(File? outputFile)? onComplete,
  //   Function(Log)? logCallback,
  // }) async {
  //   final FFMpegCommand cliCommand = FFMpegCommand(
  //     inputs: [
  //       FFMpegInput.asset(input!),
  //     ],
  //     args: [
  //       const LogLevelArgument(LogLevel.info),
  //       const OverwriteArgument(),
  //       const TrimArgument(
  //         start: Duration(seconds: 0),
  //         end: Duration(seconds: 10),
  //       ),
  //     ],
  //     filterGraph: FilterGraph(
  //       chains: [
  //         FilterChain(
  //           inputs: [],
  //           filters: [
  //             ScaleFilter(
  //               height: 300,
  //               width: -2,
  //             ),
  //           ],
  //           outputs: [],
  //         ),
  //       ],
  //     ),
  //     outputFilepath: output!,
  //   );
  //   FFMpegHelperSession session = await ffmpeg!.runAsync(
  //     cliCommand,
  //     statisticsCallback: statisticsCallback,
  //     onComplete: onComplete,
  //   );
  // }
}
