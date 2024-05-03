
import 'package:http/http.dart' as http;
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_google/langchain_google.dart';
import 'package:langchain_ollama/langchain_ollama.dart';
import 'package:synchronized/synchronized.dart';

/// langchain, 提供ollama完整的功能，包括聊天，翻译，训练，优化，设置规则，图像生成，语音识别
class LangChainClient {
  final String peerId;
  BaseLLM? llm;
  BaseChatModel? chatModel;
  Tool? tool;

  LangChainClient(this.peerId);

  static LangChainClient chatOpenAI(
    String peerId, {
    String? apiKey,
    String? organization,
    String baseUrl = 'https://api.openai.com/v1',
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    http.Client? client,
    OpenAIOptions defaultAIOptions =
        const OpenAIOptions(model: 'gpt-3.5-turbo-instruct', maxTokens: 256),
    ChatOpenAIOptions defaultChatOptions =
        const ChatOpenAIOptions(model: 'gpt-3.5-turbo'),
    OpenAIDallEToolOptions? defaultToolOptions = const OpenAIDallEToolOptions(),
    String? encoding,
  }) {
    LangChainClient langChainClient = LangChainClient(peerId);
    langChainClient.llm = OpenAI(
        apiKey: apiKey,
        organization: organization,
        baseUrl: baseUrl,
        headers: headers,
        queryParams: queryParams,
        client: client,
        defaultOptions: defaultAIOptions,
        encoding: encoding);
    langChainClient.chatModel = ChatOpenAI(
        apiKey: apiKey,
        organization: organization,
        baseUrl: baseUrl,
        headers: headers,
        queryParams: queryParams,
        client: client,
        defaultOptions: defaultChatOptions,
        encoding: encoding);
    // langChainClient.embedding = OpenAIEmbeddings(
    //     apiKey: apiKey,
    //     organization: organization,
    //     baseUrl: baseUrl,
    //     headers: headers,
    //     queryParams: queryParams,
    //     client: client,
    //     defaultOptions: defaultToolOptions);
    // langChainClient.chain = OpenAIQAWithStructureChain(
    //     apiKey: apiKey,
    //     organization: organization,
    //     baseUrl: baseUrl,
    //     headers: headers,
    //     queryParams: queryParams,
    //     client: client,
    //     defaultOptions: defaultToolOptions);
    // langChainClient.agent = OpenAIFunctionsAgent(
    //     apiKey: apiKey,
    //     organization: organization,
    //     baseUrl: baseUrl,
    //     headers: headers,
    //     queryParams: queryParams,
    //     client: client,
    //     defaultOptions: defaultToolOptions);
    langChainClient.tool = OpenAIDallETool(
        apiKey: apiKey,
        organization: organization,
        baseUrl: baseUrl,
        headers: headers,
        queryParams: queryParams,
        client: client,
        defaultOptions: defaultToolOptions);

    return langChainClient;
  }

  static LangChainClient chatGoogleGenerativeAI(
    String peerId, {
    String? apiKey,
    String? baseUrl,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    http.Client? client,
    ChatGoogleGenerativeAIOptions defaultOptions =
        const ChatGoogleGenerativeAIOptions(model: 'gemini-pro'),
  }) {
    LangChainClient langChainClient = LangChainClient(peerId);
    langChainClient.chatModel = ChatGoogleGenerativeAI(
        apiKey: apiKey,
        baseUrl: baseUrl,
        headers: headers,
        queryParams: queryParams,
        client: client,
        defaultOptions: defaultOptions);
    return langChainClient;
  }

  static LangChainClient chatOllama(
    String peerId, {
    //String baseUrl = 'http://localhost:11434/api',
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    http.Client? client,
    ChatOllamaOptions defaultOptions = const ChatOllamaOptions(model: 'llama3'),
    String encoding = 'cl100k_base',
  }) {
    LangChainClient langChainClient = LangChainClient(peerId);
    langChainClient.chatModel = ChatOllama(
        baseUrl: peerId,
        headers: headers,
        queryParams: queryParams,
        client: client,
        defaultOptions: defaultOptions,
        encoding: encoding);
    return langChainClient;
  }

  Future<ChatResult> prompt(String content, {ChatModelOptions? options}) async {
    PromptValue prompt = PromptValue.string(content);
    ChatResult result = await chatModel!.invoke(prompt);

    return result;
  }

  Future<ChatResult> chat(List<String> contents,
      {ChatModelOptions? options}) async {
    List<ChatMessage> messages = [];
    for (String content in contents) {
      messages.add(ChatMessage.humanText(content));
    }
    PromptValue prompt = PromptValue.chat(messages);
    ChatResult result = await chatModel!.invoke(prompt);

    return result;
  }

  Future<String> createImage(String toolInput,
      {OpenAIDallEToolOptions? options}) async {
    String result = await tool!.runInternalString(toolInput, options: options);

    return result;
  }

  close() {
    if (chatModel != null) {
      if (chatModel is ChatOllama) {
        (chatModel! as ChatOllama).close();
      }
    }
  }
}

class LangChainClientPool {
  Lock lock = Lock();
  var langChainClients = <String, LangChainClient>{};

  LangChainClientPool();

  ///获取或者连接指定地址的websocket的连接，并可以根据参数是否设置为缺省
  LangChainClient? get(String url) {
    LangChainClient? langChainClient;
    if (langChainClients.containsKey(url)) {
      langChainClient = langChainClients[url];
    } else {
      langChainClient = LangChainClient.chatOllama(url);
      langChainClients[url] = langChainClient;
    }

    return langChainClient;
  }

  close(String url) {
    if (langChainClients.containsKey(url)) {
      var langChainClient = langChainClients[url];
      langChainClient!.close();
      langChainClients.remove(url);
    }
  }
}

final LangChainClientPool langChainClientPool = LangChainClientPool();
