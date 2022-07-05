import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/pages/chat/chat/widget/sound_msg_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../tool/util.dart';
import 'i_sound_msg_entity.dart';
import 'msg_avatar.dart';

class SoundMsg extends StatefulWidget {
  final ChatMessage model;

  SoundMsg(this.model);

  @override
  _SoundMsgState createState() => _SoundMsgState();
}

class _SoundMsgState extends State<SoundMsg> with TickerProviderStateMixin {
  late Duration duration;
  late Duration position;

  late AnimationController controller;
  late Animation animation;
  late FlutterSound flutterSound;
  AudioPlayer audioPlayer = AudioPlayer();

  late StreamSubscription _positionSubscription;
  late StreamSubscription _audioPlayerStateSubscription;
  late StreamSubscription _playerSubscription;

  double sliderCurrentPosition = 0.0;
  double maxDuration = 1.0;

  @override
  void initState() {
    super.initState();
    flutterSound = FlutterSound();
    // flutterSound.setSubscriptionDuration(0.01);
    // flutterSound.setDbPeakLevelUpdate(0.8);
    // flutterSound.setDbLevelEnabled(true);
    initializeDateFormatting();
    initAudioPlayer();
  }

  void initAudioPlayer() {
    //控制语音动画
    controller = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    final Animation<double> curve =
        CurvedAnimation(parent: controller, curve: Curves.easeOut);
    animation = IntTween(begin: 0, end: 3).animate(curve)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller.reverse();
        }
        if (status == AnimationStatus.dismissed) {
          controller.forward();
        }
      });
//
//    _audioPlayerStateSubscription =
//        flutterSound.onPlayerStateChanged.listen((s) {
//      if (s != null) {
//      } else {
//        controller.reset();
//        setState(() {
//          position = duration;
//        });
//      }
//    }, onError: (msg) {
//      setState(() {
//        duration = Duration(seconds: 0);
//        position = Duration(seconds: 0);
//      });
//    });
  }

  void start(String path) async {
    DialogUtil.showToast("正在兼容最新flutter");
    // try {
    //   controller.forward();
    //   await flutterSound.startPlayer(path);
    //   await flutterSound.setVolume(1.0);
    //   debugPrint('startPlayer: $path');
    //
    //   _playerSubscription = flutterSound.onPlayerStateChanged.listen((e) {
    //     if (e != null) {
    //       sliderCurrentPosition = e.currentPosition;
    //       maxDuration = e.duration;
    //
    //       DateTime date = DateTime.fromMillisecondsSinceEpoch(
    //           e.currentPosition.toInt(),
    //           isUtc: true);
    //       String txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
    //
    //       print(txt.substring(0, 8).toString());
    //     }
    //   });
    // } catch (err) {
    //   print('error: $err');
    // }
  }

  playNew(url) async {
    int result = await audioPlayer.play(url);
    if (result == 1) {
      DialogUtil.showToast('播放中');
    } else {
      DialogUtil.showToast('播放出问题了');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSelf = widget.model.receiverPeerId != myself.peerId;
    var soundImg;
    var leftSoundNames = [
      'assets/images/chat/sound_left_0.webp',
      'assets/images/chat/sound_left_1.webp',
      'assets/images/chat/sound_left_2.webp',
      'assets/images/chat/sound_left_3.webp',
    ];

    var rightSoundNames = [
      'assets/images/chat/sound_right_0.png',
      'assets/images/chat/sound_right_1.webp',
      'assets/images/chat/sound_right_2.webp',
      'assets/images/chat/sound_right_3.png',
    ];
    if (isSelf) {
      soundImg = rightSoundNames;
    } else {
      soundImg = leftSoundNames;
    }

    SoundMsgEntity model = SoundMsgEntity.fromJson({});
    ISoundMsgEntity iModel = ISoundMsgEntity.fromJson({});
    bool isIos = Platform.isIOS;
    if (!CollectUtil.listNoEmpty(isIos ? iModel.soundUrls : model.urls))
      return Container();

    var urls = isIos ? iModel.soundUrls[0] : model.urls[0];
    var body = [
      MsgAvatar(model: widget.model),
      Container(
        width: 100.0,
        padding: EdgeInsets.only(right: 10.0),
        child: FlatButton(
          padding: EdgeInsets.only(left: 18.0, right: 4.0),
          child: Row(
            mainAxisAlignment:
                isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text("0\"", textAlign: TextAlign.start, maxLines: 1),
              Spacer(),
              Image.asset(
                  animation != null
                      ? soundImg[animation.value % 3]
                      : soundImg[3],
                  height: 20.0,
                  color: Colors.black,
                  fit: BoxFit.cover),
              Spacer()
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          color: widget.model.receiverPeerId != myself.peerId
              ? Color(0xff98E165)
              : Colors.white,
          onPressed: () {
            if (StringUtil.isNotEmpty(urls)) {
              playNew(urls);
            } else {
              DialogUtil.showToast('未知错误');
            }
          },
        ),
      ),
      Spacer(),
    ];
    if (isSelf) {
      body = body.reversed.toList();
    } else {
      body = body;
    }
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5.0),
      child: Row(children: body),
    );
  }

  @override
  void dispose() {
    if (_positionSubscription != null) {
      _positionSubscription.cancel();
    }
    if (_audioPlayerStateSubscription != null) {
      _audioPlayerStateSubscription.cancel();
    }
    if (_playerSubscription != null) {
      _playerSubscription.cancel();
    }
    controller.dispose();
    super.dispose();
  }
}
