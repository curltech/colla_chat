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
    required this.baseUrl,
    Map<String, String> headers = const {},
    Map<String, String> queryParams = const {},
    http.Client? client,
  }) {
    _client = OllamaClient(
        config: OllamaConfig(
            baseUrl: baseUrl,
            defaultHeaders: headers,
            defaultQueryParams: queryParams),
        httpClient: client);
  }

  void close() {
    _client.close();
  }

  Future<String?> prompt(
    String prompt, {
    List<String>? images,
    String? system,
    String? template,
    List<int>? context,
    ModelOptions? options,
    ResponseFormat? format,
    bool? raw,
    bool stream = false,
    KeepAlive? keepAlive,
  }) async {
    context = context ?? _context;
    final GenerateResponse generated = await _client.completions.generate(
      request: GenerateRequest(
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
    ModelOptions? options,
    ResponseFormat? format,
    bool? raw,
    bool stream = false,
    KeepAlive? keepAlive,
  }) async {
    context = context ?? _context;
    final Stream<GenerateStreamEvent> completionStream =
        _client.completions.generateStream(
      request: GenerateRequest(
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
      // _context = res.context;
      text += res.response?.trim() ?? '';
    }

    return text;
  }

  Future<String?> chat(
    List<String> contents, {
    ResponseFormat? format,
    ModelOptions? options,
    bool stream = false,
    KeepAlive? keepAlive,
  }) async {
    List<ChatMessage> messages = [];
    for (String content in contents) {
      messages.add(ChatMessage(
        role: MessageRole.user,
        content: content,
      ));
    }
    final generated = await _client.chat.create(
      request: ChatRequest(
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
    ModelOptions? options,
    bool stream = false,
    KeepAlive? keepAlive,
  }) async {
    List<ChatMessage> messages = [];
    for (String content in contents) {
      messages.add(ChatMessage(
        role: MessageRole.user,
        content: content,
      ));
    }
    final Stream<ChatStreamEvent> completionStream = _client.chat.createStream(
      request: ChatRequest(
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
    EmbedInput input, {
    ModelOptions? options,
    KeepAlive? keepAlive,
  }) async {
    final generated = await _client.embeddings.create(
      request: EmbedRequest(
          model: _model, input: input, keepAlive: keepAlive, options: options),
    );
    return generated.embedding;
  }

  Future<String?> createModel(
    String model, {
    Map<String, dynamic>? parameters,
    List<ChatMessage>? messages,
    bool stream = false,
  }) async {
    final StatusResponse res = await _client.models.create(
      request: CreateRequest(
          model: model,
          messages: messages,
          parameters: parameters,
          stream: stream),
    );
    return res.status;
  }

  Future<List<String?>> createModelStream(String model,
      {Map<String, dynamic>? parameters,
      List<ChatMessage>? messages,
      bool stream = false}) async {
    final modelStream = _client.models.createStream(
      request: CreateRequest(
          model: model,
          messages: messages,
          parameters: parameters,
          stream: stream),
    );
    List<String?> status = [];
    await for (final res in modelStream) {
      status.add(res.status);
    }

    return status;
  }

  Future<List<ModelSummary>?> listModels() async {
    final ListResponse res = await _client.models.list();

    return res.models;
  }

  Future<ShowResponse> showModelInfo(String model) async {
    final res = await _client.models.show(
      request: ShowRequest(model: model),
    );

    return res;
  }

  Future<String?> pullModel(
    String model, {
    bool insecure = false,
    bool stream = false,
  }) async {
    final StatusResponse res = await _client.models.pull(
      request: PullRequest(model: model, insecure: insecure, stream: stream),
    );

    return res.status;
  }

  Future<List<String?>> pullModelStream(
    String model, {
    bool insecure = false,
    bool stream = false,
  }) async {
    final modelStream = _client.models.pullStream(
      request: PullRequest(model: model, insecure: insecure, stream: stream),
    );
    List<String?> status = [];
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
    final StatusResponse res = await _client.models.push(
      request: PushRequest(model: model, insecure: insecure, stream: stream),
    );

    return res.status;
  }

  Future<List<String?>> pushModelStream(
    String model, {
    bool insecure = false,
    bool stream = false,
  }) async {
    final modelStream = _client.models.pushStream(
      request: PushRequest(model: model, insecure: insecure, stream: stream),
    );
    List<String?> status = [];
    await for (final res in modelStream) {
      status.add(res.status);
    }

    return status;
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

  void close(String url) {
    if (_clients.containsKey(url)) {
      var ollamaDartClient = _clients[url];
      ollamaDartClient!.close();
      _clients.remove(url);
    }
  }
}

final DartOllamaClientPool dartOllamaClientPool = DartOllamaClientPool();
