import 'package:flutter_alice/model/alice_http_error.dart';
import 'package:flutter_alice/model/alice_http_request.dart';
import 'package:flutter_alice/model/alice_http_response.dart';

class AliceHttpCall {
  AliceHttpCall(this.id) {
    loading = true;
  }

  final int id;
  String client = '';
  bool loading = true;
  bool secure = false;
  String method = '';
  String endpoint = '';
  String server = '';
  int? port;
  String uri = '';
  int duration = 0;

  AliceHttpRequest? request;
  AliceHttpResponse? response;
  AliceHttpError? error;

  void setResponse(AliceHttpResponse response) {
    this.response = response;
    loading = false;
  }

  String getCurlCommand() {
    bool compressed = false;
    String curlCmd = 'curl';
    curlCmd += ' -X $method';
    final Map<String, dynamic> headers = request!.headers;
    headers.forEach((String key, dynamic value) {
      if ('Accept-Encoding' == key && 'gzip' == value) {
        compressed = true;
      }
      curlCmd += " -H '$key: $value'";
    });

    final String? requestBody = request?.body.toString();
    if (requestBody != null && requestBody != '') {
      // try to keep to a single line and use a subshell to preserve any line breaks
      curlCmd += " --data \$'${requestBody.replaceAll('\n', r'\n')}'";
    }

    final String serverStr = server + (port == null ? '' : ':$port');

    curlCmd += "${compressed ? ' --compressed ' : ' '}'${secure ? 'https://' : 'http://'}$serverStr$endpoint'";
    return curlCmd;
  }
}
