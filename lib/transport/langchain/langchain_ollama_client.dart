import 'package:http/http.dart' as http;
import 'package:langchain/langchain.dart';
import 'package:langchain_ollama/langchain_ollama.dart';
import 'package:synchronized/synchronized.dart';

/// langchain, 提供ollama完整的功能，包括聊天，翻译，训练，优化，设置规则，图像生成，语音识别
class LangChainOllamaClient {
  late final String baseUrl;
  late final ChatOllama _client;
  final String _model = 'llama3';

  LangChainOllamaClient({
    this.baseUrl = 'http:// localhost:11434/ api',
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    http.Client? client,
    ChatOllamaOptions defaultOptions = const ChatOllamaOptions(model: 'llama3'),
    String encoding = 'cl100k_base',
  }) {
    _client = ChatOllama(
        baseUrl: baseUrl,
        headers: headers,
        queryParams: queryParams,
        client: client,
        defaultOptions: defaultOptions,
        encoding: encoding);
  }

  Future<ChatResult> prompt(String prompt, {ChatOllamaOptions? options}) async {
    PromptValue promptValue = PromptValue.string(prompt);
    ChatResult result = await _client.invoke(promptValue, options: options);

    return result;
  }

  Future<ChatResult> chat(List<String> contents,
      {ChatOllamaOptions? options}) async {
    List<ChatMessage> messages = [];
    for (String content in contents) {
      messages.add(ChatMessage.humanText(content));
    }
    PromptValue promptValue = PromptValue.chat(messages);
    ChatResult result = await _client.invoke(promptValue, options: options);

    return result;
  }

  close() {
    _client.close();
  }
}

class LangChainOllamaClientPool {
  Lock lock = Lock();
  final _clients = <String, LangChainOllamaClient>{};

  LangChainOllamaClientPool();

  ///获取或者连接指定地址的websocket的连接，并可以根据参数是否设置为缺省
  LangChainOllamaClient? get(String url) {
    LangChainOllamaClient? langChainClient;
    if (_clients.containsKey(url)) {
      langChainClient = _clients[url];
    } else {
      langChainClient = LangChainOllamaClient(baseUrl: url);
      _clients[url] = langChainClient;
    }

    return langChainClient;
  }

  close(String url) {
    if (_clients.containsKey(url)) {
      var langChainClient = _clients[url];
      langChainClient!.close();
      _clients.remove(url);
    }
  }
}

final LangChainOllamaClientPool langChainOllamaClientPool =
    LangChainOllamaClientPool();
