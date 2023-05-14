import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:flutter/material.dart';

///消息体：声音消息
class AudioMessage extends StatelessWidget {
  final int id;
  final String messageId;
  final String? title;
  final bool isMyself;
  final bool fullScreen;
  ValueNotifier<String?> filename = ValueNotifier<String?>(null);

  AudioMessage({
    Key? key,
    required this.id,
    required this.messageId,
    required this.isMyself,
    this.title,
    this.fullScreen = false,
  }) : super(key: key) {
    messageAttachmentService
        .getDecryptFilename(messageId, title)
        .then((filename) {
      this.filename.value = filename;
    });
  }

  @override
  Widget build(BuildContext context) {
    var audioPlayer = ValueListenableBuilder<String?>(
        valueListenable: filename,
        builder: (context, filename, child) {
          if (filename != null) {
            final BlueFireAudioPlayerController audioMessagePlayerController =
                BlueFireAudioPlayerController();
            final PlatformMediaPlayer audioMessagePlayer = PlatformMediaPlayer(
              key: UniqueKey(),
              showPlaylist: false,
              mediaPlayerController: audioMessagePlayerController,
            );
            audioMessagePlayerController.clear();
            audioMessagePlayerController.addAll(filenames: [filename]);

            return audioMessagePlayer;
          }
          return Container();
        });

    return CommonMessage(
      child: audioPlayer,
    );
  }
}
