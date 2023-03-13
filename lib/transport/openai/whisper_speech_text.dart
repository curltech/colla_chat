import 'dart:io';

import 'package:ffmpeg_dart/ffmpeg_dart.dart';
import 'package:whisper_dart/scheme/transcribe.dart';
import 'package:whisper_dart/scheme/version.dart';
import 'package:whisper_dart/scheme/whisper_response.dart';
import 'package:whisper_dart/whisper_dart.dart';

///提供Whispers语音识别的功能
class WhisperSpeechText {
  late final Whisper whisper;

  WhisperSpeechText() {
    whisper = Whisper(whisperLib: "./path_library_shared_whisper");
  }

  Future<Version> version({String? whisperLib}) async {
    Version whisperVersion = await whisper.getVersion(whisperLib: whisperLib);

    return whisperVersion;
  }

  Future<Transcribe> transcribe({
    required String audio,
    required String model,
    bool is_translate = false,
    int threads = 6,
    bool is_verbose = false,
    String language = "id",
    bool is_special_tokens = false,
    bool is_no_timestamps = false,
    String? whisperLib,
    int n_processors = 1,
    bool split_on_word = false,
    bool no_fallback = false,
    bool diarize = false,
    bool speed_up = false,
  }) async {
    Transcribe transcribe = await whisper.transcribe(
      audio: audio, //"./path_file_audio_wav_16_bit",
      model: model, //"./path_model_whisper_bin",
      language: "id", // language
    );
    return transcribe;
  }

  File convert({
    required File audioInput,
    required File audioOutput,
    String? pathFFmpeg,
    FFmpegArgs? fFmpegArgs,
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Duration? timeout,
  }) {
    File file = WhisperAudioconvert.convert(
      audioInput: audioInput,
      audioOutput: audioOutput,
    );

    return file;
  }

  Future<WhisperResponse> request({
    required File audio,
    required File model,
    bool is_translate = false,
    int threads = 4,
    bool is_verbose = false,
    String language = "id",
    bool is_special_tokens = false,
    bool is_no_timestamps = false,
    int n_processors = 1,
    bool split_on_word = false,
    bool no_fallback = false,
    bool diarize = false,
    bool speed_up = false,
  }) async {
    WhisperResponse res = await whisper.request(
      whisperRequest: WhisperRequest.fromWavFile(
        audio: audio, //File("samples/output.wav"),
        model: model, //File("models/ggml-model-whisper-small.bin"),
      ),
    );

    return res;
  }
}
