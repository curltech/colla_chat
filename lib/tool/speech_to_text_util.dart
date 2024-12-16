import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextUtil {
  static Future<SpeechToText?> initialize({
    void Function(SpeechRecognitionError)? onError,
    void Function(String)? onStatus,
  }) async {
    if (platformParams.windows || platformParams.linux) {
      throw 'Not supported platform';
    }
    SpeechToText speech = SpeechToText();
    bool available =
        await speech.initialize(onStatus: onStatus, onError: onError);
    if (available) {
      return speech;
    } else {
      logger.e("The user has denied the use of speech recognition.");
    }

    return null;
  }

  static listen(
    SpeechToText speech, {
    void Function(SpeechRecognitionResult)? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    dynamic Function(double)? onSoundLevelChange,
    dynamic cancelOnError = false,
    dynamic partialResults = true,
    dynamic onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    dynamic sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    speech.listen(onResult: onResult);
  }

  static stop(SpeechToText speech) {
    speech.stop();
  }
}
