import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextUtil {
  static Future<stt.SpeechToText?> initialize({
    void Function(SpeechRecognitionError)? onError,
    void Function(String)? onStatus,
  }) async {
    stt.SpeechToText speech = stt.SpeechToText();
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
    stt.SpeechToText speech, {
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

  static stop(stt.SpeechToText speech) {
    speech.stop();
  }
}
