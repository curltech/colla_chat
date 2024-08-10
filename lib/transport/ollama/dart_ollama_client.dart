import 'package:http/http.dart' as http;
import 'package:ollama_dart/ollama_dart.dart';
import 'package:synchronized/synchronized.dart';

/// Ollama, 提供ollama完整的功能，包括聊天，翻译，训练，优化，设置规则，图像生成，语音识别
/// "请将英语文字 'Hello, how are you?' 翻译为中文"
/// "请将 'Hello, how are you?' 转换为语音，使用标准男性音"
/// "请将 'audio file.mp3' 转换为文本，使用英语"
class DartOllamaClient {
  late final String baseUrl;
  late final OllamaClient _client;
  final String _model = 'llama3';

  ///会话的上下文，作为参数时可以指定保持上下文
  List<int>? _context;

  DartOllamaClient({
    String? baseUrl,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    http.Client? client,
  }) {
    _client = OllamaClient(
        baseUrl: baseUrl,
        headers: headers,
        queryParams: queryParams,
        client: client);
    this.baseUrl = _client.baseUrl!;
  }

  close() {
    _client.endSession();
  }

  Future<String?> prompt(
    String prompt, {
    List<String>? images,
    String? system,
    String? template,
    List<int>? context,
    RequestOptions? options,
    ResponseFormat? format,
    bool? raw,
    bool stream = false,
    int? keepAlive,
  }) async {
    context = context ?? _context;
    final GenerateCompletionResponse generated =
        await _client.generateCompletion(
      request: GenerateCompletionRequest(
          model: _model,
          prompt: prompt,
          images: images,
          system: system,
          template: template,
          context: context,
          options: options,
          format: format,
          raw: raw,
          stream: stream,
          keepAlive: keepAlive),
    );
    _context = generated.context;

    return generated.response;
  }

  Future<String> promptStream(
    String prompt, {
    List<String>? images,
    String? system,
    String? template,
    List<int>? context,
    RequestOptions? options,
    ResponseFormat? format,
    bool? raw,
    bool stream = false,
    int? keepAlive,
  }) async {
    context = context ?? _context;
    final Stream<GenerateCompletionResponse> completionStream =
        _client.generateCompletionStream(
      request: GenerateCompletionRequest(
          model: _model,
          prompt: prompt,
          images: images,
          system: system,
          template: template,
          context: context,
          options: options,
          format: format,
          raw: raw,
          stream: stream,
          keepAlive: keepAlive),
    );
    String text = '';
    await for (final res in completionStream) {
      _context = res.context;
      text += res.response?.trim() ?? '';
    }

    return text;
  }

  Future<String?> chat(
    List<String> contents, {
    ResponseFormat? format,
    RequestOptions? options,
    bool stream = false,
    int? keepAlive,
  }) async {
    List<Message> messages = [];
    for (String content in contents) {
      messages.add(Message(
        role: MessageRole.user,
        content: content,
      ));
    }
    final generated = await _client.generateChatCompletion(
      request: GenerateChatCompletionRequest(
          model: _model,
          messages: messages,
          format: format,
          options: options,
          stream: stream,
          keepAlive: keepAlive),
    );
    return generated.message?.content;
  }

  Future<String> chatStream(
    List<String> contents, {
    ResponseFormat? format,
    RequestOptions? options,
    bool stream = false,
    int? keepAlive,
  }) async {
    List<Message> messages = [];
    for (String content in contents) {
      messages.add(Message(
        role: MessageRole.user,
        content: content,
      ));
    }
    final Stream<GenerateChatCompletionResponse> completionStream =
        _client.generateChatCompletionStream(
      request: GenerateChatCompletionRequest(
          model: _model,
          messages: messages,
          format: format,
          options: options,
          stream: stream,
          keepAlive: keepAlive),
    );
    String text = '';
    await for (final res in completionStream) {
      text += (res.message?.content ?? '').trim();
    }
    return text;
  }

  Future<List<double>?> embedding(
    String prompt, {
    RequestOptions? options,
  }) async {
    final generated = await _client.generateEmbedding(
      request: GenerateEmbeddingRequest(
        model: _model,
        prompt: prompt,
      ),
    );
    return generated.embedding;
  }

  Future<CreateModelStatus?> createModel(
    String model,
    String modelfile, {
    bool stream = false,
  }) async {
    final CreateModelResponse res = await _client.createModel(
      request: CreateModelRequest(
          model: model, modelfile: modelfile, stream: stream),
    );
    return res.status;
  }

  Future<List<CreateModelStatus?>> createModelStream(
      String model, String modelfile,
      {bool stream = false}) async {
    final modelStream = _client.createModelStream(
      request: CreateModelRequest(
          model: model, modelfile: modelfile, stream: stream),
    );
    List<CreateModelStatus?> status = [];
    await for (final res in modelStream) {
      status.add(res.status);
    }

    return status;
  }

  Future<List<Model>?> listModels() async {
    final ModelsResponse res = await _client.listModels();

    return res.models;
  }

  Future<ModelInfo> showModelInfo(String model) async {
    final res = await _client.showModelInfo(
      request: ModelInfoRequest(model: model),
    );

    return res;
  }

  Future<PullModelStatus?> pullModel(
    String model, {
    bool insecure = false,
    bool stream = false,
  }) async {
    final PullModelResponse res = await _client.pullModel(
      request:
          PullModelRequest(model: model, insecure: insecure, stream: stream),
    );

    return res.status;
  }

  Future<List<PullModelStatus?>> pullModelStream(
    String model, {
    bool insecure = false,
    bool stream = false,
  }) async {
    final modelStream = _client.pullModelStream(
      request:
          PullModelRequest(model: model, insecure: insecure, stream: stream),
    );
    List<PullModelStatus?> status = [];
    await for (final res in modelStream) {
      status.add(res.status);
    }

    return status;
  }

  Future<String?> pushModel(
    String model, {
    bool insecure = false,
    bool stream = false,
  }) async {
    final PushModelResponse res = await _client.pushModel(
      request:
          PushModelRequest(model: model, insecure: insecure, stream: stream),
    );

    return res.status;
  }

  Future<List<String?>> pushModelStream(
    String model, {
    bool insecure = false,
    bool stream = false,
  }) async {
    final modelStream = _client.pushModelStream(
      request:
          PushModelRequest(model: model, insecure: insecure, stream: stream),
    );
    List<String?> status = [];
    await for (final res in modelStream) {
      status.add(res.status);
    }

    return status;
  }

  Future<void> checkBlob(String digest) async {
    await _client.checkBlob(
      digest: digest,
    );
  }
}

class DartOllamaClientPool {
  Lock lock = Lock();
  final _clients = <String, DartOllamaClient>{};

  DartOllamaClientPool();

  ///获取或者连接指定地址的websocket的连接，并可以根据参数是否设置为缺省
  DartOllamaClient? get(String url) {
    DartOllamaClient? ollamaDartClient;
    if (_clients.containsKey(url)) {
      ollamaDartClient = _clients[url];
    } else {
      ollamaDartClient = DartOllamaClient(baseUrl: url);
      _clients[url] = ollamaDartClient;
    }

    return ollamaDartClient;
  }

  close(String url) {
    if (_clients.containsKey(url)) {
      var ollamaDartClient = _clients[url];
      ollamaDartClient!.close();
      _clients.remove(url);
    }
  }
}

final DartOllamaClientPool dartOllamaClientPool = DartOllamaClientPool();
