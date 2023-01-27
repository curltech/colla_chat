import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_control_panel/video_player_control_panel.dart';

class VideoPlayer extends StatefulWidget {
  const VideoPlayer({Key? key}) : super(key: key);

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  VideoPlayerController? controller;
  final g_playlist = [
    'C:\\document\\iceland_compressed.mp4',
    "https://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_30mb.mp4",
    "https://freetestdata.com/wp-content/uploads/2022/02/Free_Test_Data_10MB_MOV.mov",
  ];
  int nowPlayIndex = 0;

  void playPrevVideo() {
    if (nowPlayIndex <= 0) return;
    playVideo(--nowPlayIndex);
  }

  void playNextVideo() {
    if (nowPlayIndex >= g_playlist.length - 1) return;
    playVideo(++nowPlayIndex);
  }

  void playVideo(int index) {
    controller?.dispose();

    var path = g_playlist[index];
    if (path.startsWith('http')) {
      controller = VideoPlayerController.network(path);
    } else {
      controller = VideoPlayerController.file(File(path));
    }

    // var captionFile =
    //     Future.value(SubRipCaptionFile(generateCaptionFileContent()));
    // controller!.setClosedCaptionFile(captionFile);

    setState(() {});
    controller!.initialize().then((value) {
      if (!controller!.value.isInitialized) {
        log("controller.initialize() failed");
        return;
      }

      controller!
          .play(); // NOTE: web not allowed auto play without user interaction
    }).catchError((e) {
      log("controller.initialize() error occurs: $e");
    });
  }

  @override
  void initState() {
    super.initState();
    playVideo(0);
  }

  @override
  void dispose() {
    super.dispose();
    controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget player = JkVideoControlPanel(
      controller!,
      showClosedCaptionButton: true,
      showFullscreenButton: true,
      showVolumeButton: true,
      onPrevClicked: (nowPlayIndex <= 0)
          ? null
          : () {
              playPrevVideo();
            },
      onNextClicked: (nowPlayIndex >= g_playlist.length - 1)
          ? null
          : () {
              playNextVideo();
            },
      onPlayEnded: () {
        playNextVideo();
      },
    );

    Widget player2 = JkVideoPlaylistPlayer(
      playlist: g_playlist,
      isLooping: true,
      autoplay: true,
    );

    return Row(children: [
      Expanded(child: player),
      //Expanded(child: player2),  // unmark this line to show 2 videos
    ]);
  }
}
