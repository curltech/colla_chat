import 'package:colla_chat/transport/webclient.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

class HttpClient implements IWebClient {
  final Client _client = RetryClient(Client());
  final String address;

  HttpClient(this.address);

  @override
  Future<Response> send(String url, dynamic data) async {
    Uri uri;
    if (url.startsWith('https')) {
      uri = Uri.https(address, url, data);
    } else {
      uri = Uri.http(address, url, data);
    }
    try {
      var token = '';
      var headers = {'Authorization': 'Bearer $token'};
      Response response = await _client.post(uri, body: data, headers: headers);

      return response;
    } finally {
      _client.close();
    }
  }

  @override
  Future<Response> get(String url) async {
    Uri uri;
    if (url.startsWith('https')) {
      uri = Uri.https(address, url);
    } else {
      uri = Uri.http(address, url);
    }
    try {
      var token = '';
      var headers = {'Authorization': 'Bearer $token'};
      var response = await _client.get(uri, headers: headers);

      return response;
    } finally {
      _client.close();
    }
  }

  @override
  Function()? postConnected;
}
