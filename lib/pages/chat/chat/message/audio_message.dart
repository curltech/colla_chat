import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:flutter/material.dart';

///消息体：声音消息
class AudioMessage extends StatefulWidget {
  final int id;
  final String messageId;
  final String? title;
  final bool isMyself;
  final bool fullScreen;

  const AudioMessage({
    super.key,
    required this.id,
    required this.messageId,
    required this.isMyself,
    this.title,
    this.fullScreen = false,
  });

  @override
  State<StatefulWidget> createState() => _AudioMessageState();
}

class _AudioMessageState extends State<AudioMessage> {
  final BlueFireAudioPlayerController audioMessagePlayerController =
      BlueFireAudioPlayerController();
  late final PlatformMediaPlayer audioMessagePlayer;
  ValueNotifier<String?> filename = ValueNotifier<String?>(null);

  @override
  void initState() {
    messageAttachmentService
        .getDecryptFilename(widget.messageId, widget.title)
        .then((filename) {
      this.filename.value = filename;
    });
    audioMessagePlayer = PlatformMediaPlayer(
      key: UniqueKey(),
      showPlaylist: false,
      mediaPlayerController: audioMessagePlayerController,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var audioPlayer = ValueListenableBuilder<String?>(
        valueListenable: filename,
        builder: (context, filename, child) {
          if (filename != null) {
            if (widget.fullScreen) {
              audioMessagePlayerController.autoplay = true;
            }
            audioMessagePlayerController.clear();
            audioMessagePlayerController.addAll(filenames: [filename]);

            return audioMessagePlayer;
          }
          return Container();
        });
    if (widget.fullScreen) {
      return audioPlayer;
    }
    return CommonMessage(
      child: audioPlayer,
    );
  }

  @override
  void dispose() {
    audioMessagePlayerController.close();
    super.dispose();
  }
}
