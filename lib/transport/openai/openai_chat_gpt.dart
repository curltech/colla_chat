import 'dart:io';

import 'package:colla_chat/plugin/logger.dart';
import 'package:dart_openai/openai.dart';

///提供ChatGpt完整的功能，包括聊天，翻译，训练，优化，设置规则，图像生成，语音识别
///
///  'text-davinci-003';
///  'text-davinci-002';
///  'code-davinci-002';
///  'gpt-3.5-turbo'; // gpt 3.5
///  'gpt-3.5-turbo-0301';
class ChatGPT {
  late OpenAI openAI;

  ChatGPT(String apiKey, {String? organization}) {
    OpenAI.apiKey = apiKey;
    OpenAI.organization = organization;
    openAI = OpenAI.instance;
  }

  ///列出模型
  Future<List<OpenAIModelModel>> listModel() async {
    List<OpenAIModelModel> models = await openAI.model.list();

    return models;
  }

  ///获取模型
  Future<OpenAIModelModel> retrieveModel(String modelId) async {
    OpenAIModelModel model = await openAI.model.retrieve(modelId);

    return model;
  }

  ///发起completion
  Future<OpenAICompletionModel> completion({
    required String model,
    dynamic prompt,
    String? suffix,
    int? maxTokens,
    double? temperature,
    double? topP,
    int? n,
    int? logprobs,
    bool? echo,
    String? stop,
    double? presencePenalty,
    double? frequencyPenalty,
    int? bestOf,
    Map<String, dynamic>? logitBias,
    String? user,
  }) async {
    OpenAICompletionModel completion = await openAI.completion.create(
      //"text-davinci-003",
      model: model,
      //"Dart is a progr",
      prompt: prompt,
      suffix: suffix,
      //20,
      maxTokens: maxTokens,
      //0.5,
      temperature: temperature,
      topP: topP,
      //1,
      n: n,
      logprobs: logprobs,
      //["\n"],
      stop: stop,
      //true,
      echo: echo,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      bestOf: bestOf,
      logitBias: logitBias,
      user: user,
    );

    return completion;
  }

  ///流的方式发起completion，回答在onChoices回调函数中处理
  completionStream({
    required String model,
    dynamic prompt,
    String? suffix,
    int? maxTokens,
    double? temperature,
    double? topP,
    int? n,
    int? logprobs,
    bool? echo,
    String? stop,
    double? presencePenalty,
    double? frequencyPenalty,
    int? bestOf,
    Map<String, dynamic>? logitBias,
    String? user,
    required Function(List<OpenAIStreamCompletionModelChoice> choices)
        onChoices,
  }) {
    Stream<OpenAIStreamCompletionModel> completionStream =
        openAI.completion.createStream(
      model: model,
      //"text-davinci-003",
      prompt: prompt,
      //"Dart is a progr",
      suffix: suffix,
      maxTokens: maxTokens,
      //20,
      temperature: temperature,
      //0.5,
      topP: topP,
      n: n,
      //1,
      logprobs: logprobs,
      stop: stop,
      //["\n"],
      echo: echo,
      //true,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      bestOf: bestOf,
      logitBias: logitBias,
      user: user,
    );

    completionStream.listen((event) {
      onChoices(event.choices);
    });
  }

  ///发起chat completion
  Future<OpenAIChatCompletionModel> chatCompletion({
    String model = 'gpt-3.5-turbo-0301',
    required String message,
    double? temperature,
    double? topP,
    int? n,
    dynamic stop,
    int? maxTokens,
    double? presencePenalty,
    double? frequencyPenalty,
    Map<String, dynamic>? logitBias,
    String? user,
  }) async {
    OpenAIChatCompletionModel chatCompletion =
        await OpenAI.instance.chat.create(
      model: model,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(content: message, role: user!),
      ],
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      n: n,
      stop: stop,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      logitBias: logitBias,
      user: user,
    );

    return chatCompletion;
  }

  ///流模式发起chat completion
  chatCompletionStream({
    String model = 'gpt-3.5-turbo-0301',
    required String message,
    double? temperature,
    double? topP,
    int? n,
    dynamic stop,
    int? maxTokens,
    double? presencePenalty,
    double? frequencyPenalty,
    Map<String, dynamic>? logitBias,
    String? user,
    String role='user',
    required Function(OpenAIStreamChatCompletionModel) onCompletion,
  }) {
    Stream<OpenAIStreamChatCompletionModel> chatStream =
        openAI.chat.createStream(
      model: "gpt-3.5-turbo",
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: message,
          role: role,
        )
      ],
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      n: n,
      stop: stop,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      logitBias: logitBias,
      user: user,
    );

    chatStream.listen(onCompletion).onError((err) {
      logger.i('$err');
    });
  }

  ///生成prompt的编辑版本
  Future<OpenAIEditModel> edit({
    required String model,
    String? input,
    required String? instruction,
    int? n,
    double? temperature,
    double? topP,
  }) async {
    OpenAIEditModel edit = await openAI.edit.create(
      model: model,
      instruction: instruction,
      input: input,
      n: n,
      temperature: temperature,
      topP: topP,
    );
    return edit;
  }

  ///根据文本创建图像
  Future<OpenAIImageModel> createImage({
    required String prompt,
    int? n = 1,
    OpenAIImageSize? size = OpenAIImageSize.size1024,
    OpenAIResponseFormat? responseFormat = OpenAIResponseFormat.url,
    String? user,
  }) async {
    OpenAIImageModel image = await openAI.image.create(
      prompt: prompt,
      n: n,
      size: size,
      responseFormat: responseFormat,
      user: user,
    );

    return image;
  }

  ///生成图像的变种
  Future<OpenAIImageVariationModel> imageVariation({
    required File image,
    int? n = 1,
    OpenAIImageSize? size = OpenAIImageSize.size1024,
    OpenAIResponseFormat? responseFormat = OpenAIResponseFormat.url,
    String? user,
  }) async {
    OpenAIImageVariationModel imageVariation = await openAI.image.variation(
      image: image,
      n: n,
      size: size,
      responseFormat: responseFormat,
      user: user,
    );

    return imageVariation;
  }

  ///根据文本修改图像
  Future<OpenAiImageEditModel> imageEdit({
    required File image,
    File? mask,
    required String prompt,
    int? n = 1,
    OpenAIImageSize? size = OpenAIImageSize.size1024,
    OpenAIResponseFormat? responseFormat = OpenAIResponseFormat.url,
    String? user,
  }) async {
    OpenAiImageEditModel imageEdit = await openAI.image.edit(
      image: image,
      mask: mask,
      prompt: prompt,
      n: n,
      size: size,
      responseFormat: responseFormat,
      user: user,
    );

    return imageEdit;
  }

  ///创建输入文本的向量
  Future<OpenAIEmbeddingsModel> createEmbeddings({
    required String model,
    required dynamic input,
    String? user,
  }) async {
    OpenAIEmbeddingsModel embeddings = await openAI.embedding.create(
      model: model,
      input: input,
    );

    return embeddings;
  }

  ///语音转录
  Future<OpenAIAudioModel> createTranscription({
    required File file,
    String model = "whisper-1",
    String? prompt,
    String? responseFormat,
    double? temperature,
    String? language,
  }) async {
    OpenAIAudioModel transcription = await openAI.audio.createTranscription(
      file: file,
      model: model,
      prompt: prompt,
      responseFormat: responseFormat,
      temperature: temperature,
      laungage: language,
    );

    return transcription;
  }

  ///语音转文本
  ///"whisper-1",
  Future<OpenAIAudioModel> createTranslation({
    required File file,
    String model = "whisper-1",
    String? prompt,
    String? responseFormat,
    double? temperature,
  }) async {
    OpenAIAudioModel translation = await openAI.audio.createTranslation(
      file: file,
      model: model,
      prompt: prompt,
      responseFormat: responseFormat,
      temperature: temperature,
    );

    return translation;
  }

  ///列出账户中的数据文件
  Future<List<OpenAIFileModel>> listFiles() async {
    List<OpenAIFileModel> files = await openAI.file.list();

    return files;
  }

  ///上传数据文件
  Future<OpenAIFileModel> upload({
    required File file,
    String purpose = "fine-tuning",
  }) async {
    OpenAIFileModel uploadedFile = await openAI.file.upload(
      file: file,
      purpose: purpose,
    );

    return uploadedFile;
  }

  ///删除账户中的数据文件
  Future<bool> deleteFile(String fileId) async {
    bool isFileDeleted = await openAI.file.delete(fileId);

    return isFileDeleted;
  }

  ///获取账户中的数据文件
  Future<OpenAIFileModel> retrieveFile(String fileId) async {
    OpenAIFileModel file = await openAI.file.retrieve(fileId);

    return file;
  }

  ///获取账户中的数据文件内容
  Future<dynamic> retrieveContent(String fileId) async {
    dynamic fileContent = await openAI.file.retrieveContent(fileId);

    return fileContent;
  }

  ///创建fine tune任务
  Future<OpenAIFineTuneModel> createFineTune({
    required String trainingFile,
    String? validationFile,
    String? model,
    int? nEpoches,
    int? batchSize,
    double? learningRateMultiplier,
    double? promptLossWeight,
    bool? computeClassificationMetrics,
    int? classificationNClass,
    int? classificationPositiveClass,
    int? classificationBetas,
    String? suffix,
  }) async {
    OpenAIFineTuneModel fineTune = await openAI.fineTune.create(
      trainingFile: trainingFile,
      validationFile: validationFile,
      model: model,
      nEpoches: nEpoches,
      batchSize: batchSize,
      learningRateMultiplier: learningRateMultiplier,
      computeClassificationMetrics: computeClassificationMetrics,
      classificationNClass: classificationNClass,
      classificationPositiveClass: classificationPositiveClass,
      classificationBetas: classificationBetas,
      suffix: suffix,
    );

    return fineTune;
  }

  ///列出fine tune任务
  Future<List<OpenAIFineTuneModel>> listFineTunes() async {
    List<OpenAIFineTuneModel> fineTunes = await openAI.fineTune.list();

    return fineTunes;
  }

  ///获取fine tune任务
  Future<OpenAIFineTuneModel> retrieveFineTune(String fineTuneId) async {
    OpenAIFineTuneModel fineTune = await openAI.fineTune.retrieve(fineTuneId);

    return fineTune;
  }

  ///撤销fine tune任务
  Future<OpenAIFineTuneModel> cancelFineTune(String fineTuneId) async {
    OpenAIFineTuneModel cancelledFineTune =
        await openAI.fineTune.cancel(fineTuneId);

    return cancelledFineTune;
  }

  ///列出fine tune任务的事件
  Future<List<OpenAIFineTuneEventModel>> listEvent(String fineTuneId) async {
    List<OpenAIFineTuneEventModel> events =
        await openAI.fineTune.listEvents(fineTuneId);

    return events;
  }

  ///流模式列出fine tune任务的事件
  listEventStream(
      String fineTuneId, Function(OpenAIFineTuneEventStreamModel) onEvent) {
    Stream<OpenAIFineTuneEventStreamModel> eventsStream =
        openAI.fineTune.listEventsStream(fineTuneId);

    eventsStream.listen(onEvent).onError((err) {
      logger.e('$err');
    });
  }

  ///删除fine tune任务
  Future<bool> deleteFineTune(String fineTuneId) async {
    bool deleted = await openAI.fineTune.delete(fineTuneId);

    return deleted;
  }

  ///创建适合的规则
  Future<OpenAIModerationModel> createModeration(
      {required String input, String? model}) async {
    try {
      OpenAIModerationModel moderation =
          await openAI.moderation.create(input: input, model: model);

      return moderation;
    } on Exception catch (e) {
      logger.e('$e');
      rethrow;
    }
  }
}
