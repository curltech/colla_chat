import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:colla_chat/plugin/logger.dart';

///提供ChatGpt简单的文本聊天和翻译功能
class ChatGPTChat {
  late final OpenAI openAI;

  ChatGPTChat(String apiKey) {
    openAI = OpenAI.instance.build(
        token: apiKey,
        baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
        isLog: true);
  }

  ///如果需要翻译，prompt经过本函数处理
  translateWord(String language, String text) {
    return "Translate this into $language : $text";
  }

  ///model name
  /// const kTextDavinci3 = 'text-davinci-003';
  /// const kTextDavinci2 = 'text-davinci-002';
  /// const kCodeDavinci2 = 'code-davinci-002';
  /// const kChatGptTurboModel = 'gpt-3.5-turbo'; // gpt 3.5
  /// const kChatGptTurbo0301Model = 'gpt-3.5-turbo-0301';
  completion(
      {required String prompt,
      required String model,
      double temperature = .3,
      int maxTokens = 100,
      double topP = 1.0,
      double frequencyPenalty = .0,
      double presencePenalty = .0,
      List<String>? stop,
      Function(CTResponse?)? onComplete}) {
    final request = CompleteText(
      prompt: prompt,
      model: Model.TextDavinci3,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
      stop: stop,
    );
    Stream<CTResponse?> response =
        openAI.onCompletion(request: request).asStream();
    response.listen(onComplete).onError((err) {});
  }

  Future<List<dynamic>> chatCompletion({
    required ChatModel model,
    required List<Map<String, String>> messages,
    double? temperature = .3,
    double? topP = 1.0,
    int? n = 1,
    bool? stream = false,
    List<String>? stop,
    int? maxToken = 100,
    double? presencePenalty = .0,
    double? frequencyPenalty = .0,
    String? user = "",
  }) async {
    final request = ChatCompleteText(
      model: model,
      messages: messages,
      //[Map.of({"role": "user", "content": 'Hello!'})],
      maxToken: maxToken,
      temperature: temperature,
      topP: topP,
      n: n,
      stream: stream,
      stop: stop,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      user: user,
    );
    final response = await openAI.onChatCompletion(request: request);

    return response!.choices;
  }

  void chatCompletionStream(
      {required ChatModel model,
      required List<Map<String, String>> messages,
      double? temperature = .3,
      double? topP = 1.0,
      int? n = 1,
      bool? stream = false,
      List<String>? stop,
      int? maxToken = 100,
      double? presencePenalty = .0,
      double? frequencyPenalty = .0,
      String? user = "",
      required Function(ChatCTResponse?) onChatCompletion}) async {
    final request = ChatCompleteText(
      model: model,
      messages: messages,
      //[Map.of({"role": "user", "content": 'Hello!'})],
      maxToken: maxToken,
      temperature: temperature,
      topP: topP,
      n: n,
      stream: stream,
      //kChatGptTurbo0301Model
      stop: stop,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      user: user,
    );

    openAI
        .onChatCompletionStream(request: request)
        .listen(onChatCompletion)
        .onError((err) {
      logger.i('$err');
    });
  }
}
